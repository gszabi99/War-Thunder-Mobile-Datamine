from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "dagor.time" import get_time_msec
from "dagor.workcycle" import deferOnce
from "eventbus" import eventbus_send
from "sound_wt" import playSound
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/clientState/clientState.nut" import isInDebriefing
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/gameModes/newbieGameModesConfig.nut" import isNewbieMode
from "%appGlobals/pServer/bqClient.nut" import sendNewbieBqEvent
from "%appGlobals/pServer/pServerApi.nut" import registerHandler
from "%appGlobals/pServer/profile.nut" import curUnits, campUnitsCfg
from "%appGlobals/pServer/slots.nut" import curSlots
from "%appGlobals/permissions.nut" import can_write_replays
from "%appGlobals/squadState.nut" import isInSquad, isSquadLeader
from "%appGlobals/unitsState.nut" import setCurrentUnit
from "%rGui/attributes/unitAttr/unitAttrState.nut" import openUnitAttrWnd
from "%rGui/boosters/boostersListActive.nut" import boostersListActive
import "%rGui/components/panelBg.nut" as panelBg
from "%rGui/components/textButton.nut" import textButtonPrimary, textButtonCommon, textButtonBattle, buttonsHGap,
  iconButtonCommon
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/debriefing/debrUtils.nut" import getResearchedUnit, getBestUnitName, isUnitReceiveLevel,
  getSlotOrUnitLevelUnlockRewards, getBgUnits
from "%rGui/debriefing/debriefingState.nut" import debriefingData, curDebrTabId, nextDebrTabId,
  isDebriefingAnimFinished, isNoExtraScenesAfterDebriefing, DEBR_TAB_SCORES, debrTabsShowTime, showReleaseToContinueBtn,
  needShowBtns_Campaign, needShowBtns_Unit, needShowBtns_Final, needReinitScene, activatingTimeBtns_Campaign,
  activatingTimeBtns_Final
from "%rGui/debriefing/debriefingTabBar.nut" import debriefingTabBar
from "%rGui/debriefing/debriefingWndConsts.nut" import footerGap, footerHeight
import "%rGui/debriefing/mkDebrTabsInfo.nut" as mkDebrTabsInfo
import "%rGui/debriefing/mkDebriefingEmpty.nut" as mkDebriefingEmpty
import "%rGui/debriefing/tapListener.nut" as tapListener
from "%rGui/event/eventState.nut" import allSpecialEvents, specialEventsWithTree
from "%rGui/event/gmEventState.nut" import gmEventsList
from "%rGui/feedback/rateGame.nut" import requestShowRateGame
from "%rGui/feedback/rateGameState.nut" import needRateGame
from "%rGui/gameModes/gameModeState.nut" import randomBattleMode, allGameModes, shouldStartNewbieSingleOnline
from "%rGui/gameModes/newbieOfflineMissions.nut" import isNextBattleNewbieOffline, startCurNewbieMission
from "%rGui/gameModes/offlineBattlesState.nut" import runOfflineBattle, openOfflineBattleMenu
from "%rGui/mainMenu/toBattleButton.nut" import mkToBattleButtonWithSquadManagement
from "%rGui/navState.nut" import registerScene
import "%rGui/queue/queuePenaltyWnd.nut" as tryOpenQueuePenaltyWnd
from "%rGui/replay/lastReplayState.nut" import hasUnsavedReplay
import "%rGui/replay/saveReplayWindow.nut" as saveReplayWindow
from "%rGui/seasonScene/seasonSceneState.nut" import openSeasonScene, LOOTBOX_TAB, MAP_TAB, openGmEventWnd
import "%rGui/shop/missingPremiumAccWnd.nut" as showNoPremMessageIfNeed
import "%rGui/shop/offerMissingUnitItemsMessage.nut" as offerMissingUnitItemsMessage
from "%rGui/slotBar/slotBarState.nut" import selectedSlotIdx
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/tutorial/tutorialConst.nut" import TUTORIAL_UNITS_RESEARCH_ID, TUTORIAL_ARSENAL_ID
from "%rGui/unit/hangarUnit.nut" import setHangarUnit, setHangarUnitGroup
from "%rGui/unit/unitsWndState.nut" import curSelectedUnit
from "%rGui/unitsTree/unitsTreeState.nut" import openUnitsTreeAtUnit
from "%rGui/unlocks/userstat.nut" import registerUnlocksSceneToUpdate


let rightButtonOvr = { minWidth = hdpx(400) }

local isAttached = false

function closeDebriefing() {
  eventbus_send("Debriefing_CloseInDagui", {})
  needReinitScene.set(true)
}
let startBattle = @(modeId) eventbus_send("queueToGameMode", { modeId })
function openSpecialEvent() {
  let eventName = allGameModes.get().findvalue(@(m) m.name == debriefingData.get()?.roomInfo.game_mode_name)?.eventId
  let eventId = allSpecialEvents.get().findindex(@(e) e.eventName == eventName)
  if (eventId) {
    if (eventName in gmEventsList.get())
      openGmEventWnd(eventName)
    else if (specialEventsWithTree.get().findindex(@(event) event.eventName == eventId) != null)
      openSeasonScene(eventId, MAP_TAB)
    else
      openSeasonScene(eventId, LOOTBOX_TAB)
  }
}

const SAVE_ID_UPGRADE_BUTTON_PUSHED = "debriefingUpgradeButtonPushed"
let countUpgradeButtonPushed = Watched(get_local_custom_settings_blk()?[SAVE_ID_UPGRADE_BUTTON_PUSHED] ?? 0)
const minCountUpgradeButtonPushed = 3

let updateHangarUnit = @(unitId) unitId == null ? null : setHangarUnit(unitId)

let upgradeUnitLocIdByCampaign = {
  air   = "mainmenu/btnUpgradeAircraft"
  tanks = "mainmenu/btnUpgradeTank"
  ships = "mainmenu/btnUpgradeShip"
}

let btnSaveReplay = @() {
  watch = [can_write_replays, hasUnsavedReplay]
  children = !can_write_replays.get() || !hasUnsavedReplay.get() ? null
    : iconButtonCommon(
      "ui/gameuiskin#icon_menu_replay_save.svg",
      saveReplayWindow
      {ovr = {
        size = const [hdpxi(109), hdpxi(109)],
        minWidth = hdpxi(109)
      }}
    )
}

let buttonDescText = @(needShowW, text) @() !needShowW.get() ? { watch = needShowW } : {
  watch = needShowW
  vplace = ALIGN_CENTER
  children = {
    maxWidth = hdpx(400)
    halign = ALIGN_CENTER
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text
    color = 0xFFFFFFFF

    key = {}
    transform = {}
    animations = [{ prop = AnimProp.opacity, from = 0, to = 1, duration = 1.0, easing = OutQuad, play = true }]
  }.__update(fontSmall)
}

let mkBtnAppearAnim = @(needBlink, needShowW, children) @() !needShowW.get() ? { watch = needShowW } : {
  watch = needShowW
  children = {
    key = {}
    transform = {}
    animations = [{ prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, easing = OutQuad, play = true }]
      .extend(needBlink
        ? [{ prop = AnimProp.scale, from = [1, 1], to = [1.3, 1.3], duration = 0.5, easing = Blink, play = true }]
        : [])
    children
  }
}

let mkBtnToHangar = @(needShow, debrData, isMainBtn, unlockedReward) mkBtnAppearAnim(false, needShow,
  (isMainBtn ? textButtonBattle : textButtonCommon)(
    utf8ToUpper(loc(unlockedReward.has ? $"return_to_hangar/lvlUnlocks/{unlockedReward.type}"
      : (debrData?.campaign ?? "") != "" ? getCampaignPresentation(debrData.campaign).returnToHangarShortLocId
      : "return_to_hangar/short"
    )),
    function() {
      if (activatingTimeBtns_Final.get() > get_time_msec())
        return
      isNoExtraScenesAfterDebriefing.set(true)
      if (needRateGame.get())
        requestShowRateGame()
      if (unlockedReward.has) {
        selectedSlotIdx.set(unlockedReward.idx)
        setCurrentUnit(unlockedReward.name)
        curSelectedUnit.set(unlockedReward.name)
      }
      closeDebriefing()
      openSpecialEvent()
    },
    { hotkeys = isMainBtn ? ["^J:X | Enter"] : [btnBEscUp], ovr = rightButtonOvr }))

let mkBtnToOfflineBattles = @(needShow, debrData) mkBtnAppearAnim(false, needShow,
  textButtonCommon(
    utf8ToUpper(loc("return_to_offline_battles")),
    function() {
      if (activatingTimeBtns_Final.get() > get_time_msec())
        return
      isNoExtraScenesAfterDebriefing.set(true)
      if (needRateGame.get())
        requestShowRateGame()
      closeDebriefing()
      openOfflineBattleMenu(debrData)
    },
    { hotkeys = ["^J:Y"], ovr = rightButtonOvr }))

let mkBtnNewUnitResearched = @(needShow, researchedUnit) mkBtnAppearAnim(true, needShow, textButtonBattle(
  utf8ToUpper(loc("msgbox/btn_get")),
  function() {
    if (activatingTimeBtns_Campaign.get() > get_time_msec())
      return
    isNoExtraScenesAfterDebriefing.set(false)
    let nextAction = @() openUnitsTreeAtUnit(researchedUnit?.name)
    if (needRateGame.get())
      requestShowRateGame(nextAction)
    else
      nextAction()
    closeDebriefing()
  },
  { hotkeys = ["^J:X | Enter"], ovr = rightButtonOvr }))

function toBattle(gmId) {
  showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnits.get(), @() startBattle(gmId)))
  closeDebriefing()
}

const cbId = "onResetPenaltyToBattleInDebriefing"
registerHandler(cbId, @(res, context) res?.error == null ? toBattle(context.gmId) : null)

let toBattleButton = @(gmId, campaign)
  mkToBattleButtonWithSquadManagement(function() {
    if (activatingTimeBtns_Final.get() > get_time_msec())
      return
    sendNewbieBqEvent("pressToBattleButtonDebriefing", { status = "online_battle" })
    isNoExtraScenesAfterDebriefing.set(true)
    let nextAction = @() tryOpenQueuePenaltyWnd(campaign, allGameModes.get()?[gmId], { id = cbId, gmId }) ? null : toBattle(gmId)
    if (needRateGame.get())
      requestShowRateGame(nextAction)
    else
      nextAction()
  },
  Computed(@() allGameModes.get()?[gmId]),
  { hotkeys = ["^J:X | Enter"], ovr = rightButtonOvr })

let startOfflineMissionButton = textButtonBattle(utf8ToUpper(loc("mainmenu/toBattle/short")),
  function() {
    if (activatingTimeBtns_Final.get() > get_time_msec())
      return
    sendNewbieBqEvent("pressToBattleButtonDebriefing", { status = "offline_battle" })
    isNoExtraScenesAfterDebriefing.set(true)
    let nextAction = startCurNewbieMission
    if (needRateGame.get())
      requestShowRateGame(nextAction)
    else
      nextAction()
    closeDebriefing()
  },
  { hotkeys = ["^J:X | Enter"], ovr = rightButtonOvr })

let mkStartCustomOfflineBattleButton = @(unitName, missionName) textButtonBattle(utf8ToUpper(loc("mainmenu/toBattle/short")),
  function() {
    if (activatingTimeBtns_Final.get() > get_time_msec())
      return
    isNoExtraScenesAfterDebriefing.set(true)
    let nextAction = @() runOfflineBattle(missionName, unitName)
    if (needRateGame.get())
      requestShowRateGame(nextAction)
    else
      nextAction()
    closeDebriefing()
  },
  { hotkeys = ["^J:X | Enter"], ovr = rightButtonOvr })

let mkBtnUpgradeUnit = @(needShow, campaign) mkBtnAppearAnim(true, needShow, textButtonPrimary(
  utf8ToUpper(loc(upgradeUnitLocIdByCampaign?[getCampaignPresentation(campaign).campaign] ?? upgradeUnitLocIdByCampaign.tanks)),
  function() {
    isNoExtraScenesAfterDebriefing.set(false)
    function nextAction() {
      countUpgradeButtonPushed.set(countUpgradeButtonPushed.get() + 1)
      get_local_custom_settings_blk()[SAVE_ID_UPGRADE_BUTTON_PUSHED] = countUpgradeButtonPushed.get()
      eventbus_send("saveProfile", {})
      let unit = campUnitsCfg.get()?[getBestUnitName(debriefingData.get())]
      if (unit != null) {
        updateHangarUnit(unit.name)
        openUnitAttrWnd()
      }
    }
    if (needRateGame.get())
      requestShowRateGame(nextAction)
    else
      nextAction()
    closeDebriefing()
  },
  {
    hotkeys = [btnBEscUp]
    hasGlare = true
    ovr = rightButtonOvr
  }
))

let mkNextGameModeInfo = @(roomInfo, prevCamp) Computed(function() {
  let rBattleMode = randomBattleMode.get()
  let rgmId = rBattleMode?.gameModeId
  let rCampaign = rBattleMode?.campaign
  let { game_mode_id = rgmId, game_mode_name = null } = roomInfo
  return game_mode_id not in allGameModes.get() || game_mode_id == rgmId || isNewbieMode(game_mode_name)
    ? { gmId = rgmId, isCommonBattle = true, campaign = rCampaign ?? prevCamp }
    : { gmId = game_mode_id, isCommonBattle = false, campaign = prevCamp ?? rCampaign }
})

let mkBtnToBattlePlace = @(needShow, nextGMInfo, debrData) mkBtnAppearAnim(false, needShow,
  function() {
    let { isCustomOfflineBattle = false, unit = null, mission = null } = debrData
    let { gmId, isCommonBattle, campaign } = nextGMInfo.get()
    let { name = null, isFake = false } = unit
    let children = []
    if (!isFake)
      children.append(boostersListActive("debriefing"))
    return {
      watch = [isNextBattleNewbieOffline, isInSquad, isSquadLeader, nextGMInfo, shouldStartNewbieSingleOnline]
      flow = FLOW_HORIZONTAL
      gap = hdpx(20)
      children = !isInSquad.get() && isCustomOfflineBattle && name != null && mission != null
          ? children.append(mkStartCustomOfflineBattleButton(name, mission))
        : !isInSquad.get() && isCommonBattle && isNextBattleNewbieOffline.get() && !shouldStartNewbieSingleOnline.get()
          ? children.append(startOfflineMissionButton)
        : gmId != null && campaign != null && (!isInSquad.get() || isSquadLeader.get())
          ? children.append(toBattleButton(gmId, campaign))
        : null
    }
  })

let btnNextTab = function() {
  let res = { watch = [ isDebriefingAnimFinished, nextDebrTabId ] }
  return isDebriefingAnimFinished.get() || nextDebrTabId.get() == null ? res : res.__update({
    children = textButtonCommon(utf8ToUpper(loc("mainmenu/btnPageNext")),
      @() curDebrTabId.set(nextDebrTabId.get()),
      { hotkeys = ["^J:X | Enter"], ovr = rightButtonOvr })
  })
}

function debriefingWnd() {
  let debrData = debriefingData.get()
  let { campaign = "", isWon = false, isTutorial = false, roomInfo = null, isCustomOfflineBattle = false,
    isFinished = false, isDeserter = false, isDisconnected = false, kickInactivity = false, predefinedId = null,
    abTests = null
  } = debrData
  let unitName = getBestUnitName(debrData)
  let bgUnits = getBgUnits(debrData)
  let researchedUnit = getResearchedUnit(debrData)
  let isUnitResearchedAfterTutorial = isTutorial && researchedUnit != null
  let unlockedReward = getSlotOrUnitLevelUnlockRewards(debrData)
  let hasAnyLevelUnlockRewards = unlockedReward.has
  let isFirstLvlUpForSlot = hasAnyLevelUnlockRewards
    && unlockedReward.type == "crew"
    && unlockedReward.levelBeforeBattle == 0
    && curSlots.get().filter(@(slot) slot.level != 0).len() == 1
  let canStartArsenalTutorial = hasAnyLevelUnlockRewards
    && unlockedReward.type == "arsenal"
    && debrData?.completedTutorials[TUTORIAL_UNITS_RESEARCH_ID]
    && !debrData?.completedTutorials[TUTORIAL_ARSENAL_ID]
    && researchedUnit == null
  let needForceQuitToHangar = isUnitResearchedAfterTutorial
    || isFirstLvlUpForSlot
    || canStartArsenalTutorial
  let isFirstBattleRewardPart = (abTests?.hasSpendTutorials ?? "false") == "true" && predefinedId == 0
  let hasUnitLevelUp = !needForceQuitToHangar && ("slots" not in debrData) && isUnitReceiveLevel(unitName, debrData)

  let tabsParams = {
    needBtnCampaign = researchedUnit != null
    needBtnUnit = !researchedUnit && hasUnitLevelUp
  }
  let debrTabsInfo = mkDebrTabsInfo(debrData, tabsParams)
  let debrTabComps = debrTabsInfo.map(@(v) [ v.id, v.comp ]).totable()
  let tabsShowTime = debrTabsInfo.filter(@(v) v.needAutoAnim).map(@(v)  { id = v.id, timeShow = v.timeShow })
  let debrAnimTime = tabsShowTime.reduce(@(res, v) res + v.timeShow, 0)
  debrTabsShowTime.set(tabsShowTime)

  function reinitScene() {
    if (!needReinitScene.get())
      return
    curDebrTabId.set(debrTabsInfo?[0].id ?? DEBR_TAB_SCORES)
    isDebriefingAnimFinished.set(debrAnimTime <= 0)
    let hangarUnitName = unitName != "" ? unitName : (debrData?.reward.unitName ?? "")
    if (bgUnits.len() > 0)
      setHangarUnitGroup(bgUnits, false, bgUnits.findindex(@(n) n == hangarUnitName) ?? 0)
    playSound(isWon ? "stats_winner_start" : "stats_looser_start")
    sendNewbieBqEvent("openDebriefing", { status = isWon ? "win" : "loose" })
    log($"[BATTLE_RESULT] isWon = {isWon}, isFinished = {isFinished}, isDeserter = {isDeserter}, isDisconnected = {isDisconnected}, kickInactivity = {kickInactivity}")
  }

  if (isAttached)
    deferOnce(reinitScene)

  return bgShaded.__merge({
    watch = debriefingData
    key = debriefingData
    function onAttach() {
      isAttached = true
      reinitScene()
    }
    function onDetach() {
      isAttached = false
      sendNewbieBqEvent("closeDebriefing", { status = isWon ? "win" : "loose" })
    }
    size = FLEX
    padding = saBordersRv
    children = [
      @() {
        watch = isDebriefingAnimFinished
        children = !isDebriefingAnimFinished.get() ? null : tapListener(debrTabsInfo)
      }
      {
        size = FLEX
        flow = FLOW_VERTICAL
        gap = footerGap
        padding = [0, 0, footerHeight + footerGap, 0]
        children = @() {
          watch = curDebrTabId
          size = FLEX
          halign = ALIGN_CENTER
          children = debrTabComps?[curDebrTabId.get()] ?? mkDebriefingEmpty(debrData)
        }
      }
      @() {
        watch = isDebriefingAnimFinished
        children = isDebriefingAnimFinished.get() ? null : tapListener(debrTabsInfo)
      }
      debriefingTabBar(debrData, debrTabsInfo)
      
      @() {
        watch = countUpgradeButtonPushed
        size = [FLEX, footerHeight]
        vplace = ALIGN_BOTTOM
        valign = ALIGN_BOTTOM
        flow = FLOW_HORIZONTAL
        children = [
          {
            size = FLEX_H
            halign = ALIGN_LEFT
            flow = FLOW_HORIZONTAL
            gap = footerGap
            children = [
              researchedUnit != null || needForceQuitToHangar || isFirstBattleRewardPart ? null
                : hasUnitLevelUp ? mkBtnUpgradeUnit(needShowBtns_Unit, campaign)
                : {
                    flow = FLOW_HORIZONTAL
                    gap = footerGap
                    children = [
                      mkBtnToHangar(needShowBtns_Final, debrData, false, unlockedReward)
                      isCustomOfflineBattle ? mkBtnToOfflineBattles(needShowBtns_Final, debrData) : null
                    ]
                  },
              mkBtnAppearAnim(false, needShowBtns_Final, btnSaveReplay)
            ]
          }
          {
            size = FLEX_H
            halign = ALIGN_RIGHT
            children = {
              flow = FLOW_HORIZONTAL
              gap = buttonsHGap
              children = (needForceQuitToHangar ? [ 
                    mkBtnToHangar(needShowBtns_Final, debrData, true, unlockedReward)
                  ]
                : researchedUnit != null ? [
                    buttonDescText(needShowBtns_Campaign, loc("unitsTree/researchCompleted"))
                    mkBtnNewUnitResearched(needShowBtns_Campaign, researchedUnit)
                  ]
                : isFirstBattleRewardPart ? [mkBtnNewUnitResearched(needShowBtns_Campaign, researchedUnit)]
                : hasUnitLevelUp && countUpgradeButtonPushed.get() < minCountUpgradeButtonPushed ? []
                : [
                    mkBtnToBattlePlace(needShowBtns_Final, mkNextGameModeInfo(roomInfo, campaign), debrData)
                  ]
              ).append(btnNextTab)  
            }
          }
        ]
      }
      @() {
        watch = showReleaseToContinueBtn
        hplace = ALIGN_RIGHT
        children = !showReleaseToContinueBtn.get() ? null
          : panelBg.__merge({
              size = const [hdpx(400), hdpx(90)]
              valign = ALIGN_CENTER
              halign = ALIGN_CENTER
              padding = 0
              children = {
                rendObj = ROBJ_TEXTAREA
                behavior = Behaviors.TextArea
                halign = ALIGN_CENTER
                maxWidth = hdpx(360)
                text = utf8ToUpper(loc("debriefing/ReleaseToContinue"))
              }.__update(fontTinyAccentedShaded)
            })
      }
    ]
  })
}

const sceneId = "debriefingWnd"
registerScene(sceneId, debriefingWnd, closeDebriefing, isInDebriefing)
registerUnlocksSceneToUpdate(sceneId)