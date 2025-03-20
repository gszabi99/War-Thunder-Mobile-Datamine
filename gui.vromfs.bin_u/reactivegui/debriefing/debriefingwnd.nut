from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { playSound } = require("sound_wt")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { curUnit, playerLevelInfo, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { releasedUnits } = require("%rGui/unit/unitState.nut")
let { registerScene } = require("%rGui/navState.nut")
let { textButtonPrimary, textButtonBattle, buttonsHGap } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { commonGlare } = require("%rGui/components/glare.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { openUnitAttrWnd } = require("%rGui/attributes/unitAttr/unitAttrState.nut")
let { debriefingData, curDebrTabId, nextDebrTabId, isDebriefingAnimFinished, isNoExtraScenesAfterDebriefing,
  DEBR_TAB_SCORES, DEBR_TAB_CAMPAIGN, debrTabsShowTime, stopDebriefingAnimation,
  needShowBtns_Campaign, needShowBtns_Unit, needShowBtns_Final,
} = require("debriefingState.nut")
let { randomBattleMode, allGameModes } = require("%rGui/gameModes/gameModeState.nut")
let { newbieOfflineMissions, startCurNewbieMission } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let { isNewbieMode } = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let offerMissingUnitItemsMessage = require("%rGui/shop/offerMissingUnitItemsMessage.nut")
let { requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { textButtonPlayerLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { needRateGame } = require("%rGui/feedback/rateGameState.nut")
let { requestShowRateGame } = require("%rGui/feedback/rateGame.nut")
let { isInSquad, isSquadLeader } = require("%appGlobals/squadState.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { lvlUpCost } = require("%rGui/levelUp/levelUpState.nut")
let { openExpWnd, canPurchaseLevelUp } = require("%rGui/mainMenu/expWndState.nut")
let showNoPremMessageIfNeed = require("%rGui/shop/missingPremiumAccWnd.nut")
let { isPlayerReceiveLevel, getResearchedUnit, getBestUnitName, isUnitReceiveLevel, getNewPlatoonUnit, getSlotOrUnitLevelUnlockRewards
} = require("debrUtils.nut")
let mkDebrTabsInfo = require("mkDebrTabsInfo.nut")
let debriefingTabBar = require("debriefingTabBar.nut")
let mkDebriefingEmpty = require("mkDebriefingEmpty.nut")
let { boostersListActive } = require("%rGui/boosters/boostersListActive.nut")
let { openEventWnd, specialEvents } = require("%rGui/event/eventState.nut")
let { getUnitTags } = require("%appGlobals/unitTags.nut")
let { openUnitsTreeAtUnit } = require("%rGui/unitsTree/unitsTreeState.nut")
let { slots, selectedSlotIdx } = require("%rGui/slotBar/slotBarState.nut")
let { setCurrentUnit, buyUnitsData } = require("%appGlobals/unitsState.nut")
let { curSelectedUnit } = require("%rGui/unit/unitsWndState.nut")
let { runOfflineBattle } = require("%rGui/debugTools/debugOfflineBattleState.nut")
let { TUTORIAL_UNITS_RESEARCH_ID, TUTORIAL_ARSENAL_ID } = require("%rGui/tutorial/tutorialConst.nut")

local isAttached = false

let closeDebriefing = @() eventbus_send("Debriefing_CloseInDagui", {})
let startBattle = @(modeId) eventbus_send("queueToGameMode", { modeId })
let function openSpecialEvent() {
  let eventName = allGameModes.get().findvalue(@(m) m.name == debriefingData.get()?.roomInfo.game_mode_name)?.eventId
  let eventId = specialEvents.get().findindex(@(e) e.eventName == eventName)
  if (eventId)
    openEventWnd(eventId)
}

const SAVE_ID_UPGRADE_BUTTON_PUSHED = "debriefingUpgradeButtonPushed"
let countUpgradeButtonPushed = Watched(get_local_custom_settings_blk()?[SAVE_ID_UPGRADE_BUTTON_PUSHED] ?? 0)
let minCountUpgradeButtonPushed = 3

let updateHangarUnit = @(unitId) unitId == null ? null : setHangarUnit(unitId)

let upgradeUnitLocIdByCampaign = {
  air   = "mainmenu/btnUpgradeAircraft"
  tanks = "mainmenu/btnUpgradePlatoon"
  ships = "mainmenu/btnUpgradeShip"
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
  (isMainBtn ? textButtonBattle : textButtonPrimary)(
    utf8ToUpper(loc(unlockedReward.has && debrData?.isSeparateSlots ? $"return_to_hangar/lvlUnlocks/{unlockedReward.type}"
      : debrData?.campaign == "ships" ? "return_to_port/short"
      : "return_to_hangar/short"
    )),
    function() {
      isNoExtraScenesAfterDebriefing.set(true)
      if (needRateGame.get())
        requestShowRateGame()
      if (unlockedReward.has && debrData?.isSeparateSlots){
        selectedSlotIdx.set(unlockedReward.idx)
        setCurrentUnit(unlockedReward.name)
        curSelectedUnit.set(unlockedReward.name)
      }
      closeDebriefing()
      openSpecialEvent()
    },
    { hotkeys = isMainBtn ? ["^J:X | Enter"] : [btnBEscUp] }))

let mkBtnLevelUp = @(needShow) mkBtnAppearAnim(true, needShow, textButtonBattle(
  utf8ToUpper(loc("msgbox/btn_get")),
  function() {
    isNoExtraScenesAfterDebriefing.set(false)
    if (needRateGame.get())
      requestShowRateGame()
    closeDebriefing()
  },
  { hotkeys = ["^J:X | Enter"] }))

let mkBtnNewUnitResearched = @(needShow, researchedUnit) mkBtnAppearAnim(true, needShow, textButtonBattle(
  utf8ToUpper(loc("msgbox/btn_get")),
  function() {
    isNoExtraScenesAfterDebriefing.set(false)
    let nextAction = @() openUnitsTreeAtUnit(researchedUnit?.name)
    if (needRateGame.get())
      requestShowRateGame(nextAction)
    else
      nextAction()
    closeDebriefing()
  },
  { hotkeys = ["^J:X | Enter"] }))

let mkBtnBuyNextPlayerLevel = @(needShow, curPlayerLevel, campaign) function() {
  let res = {
    watch = [playerLevelInfo, lvlUpCost, serverConfigs, buyUnitsData, releasedUnits]
  }
  let { level, starLevel, isMaxLevel, isReadyForLevelUp } = playerLevelInfo.get()
  if (level > curPlayerLevel || isMaxLevel || isReadyForLevelUp
      || campaign in serverConfigs.get()?.unitTreeNodes
      || !canPurchaseLevelUp(playerLevelInfo.get(), buyUnitsData.get(), releasedUnits.get()))
    return res

  let cost = { price = lvlUpCost.get(), currencyId = GOLD }
  let btnComp = mkBtnAppearAnim(false, needShow,
    textButtonPlayerLevelUp(utf8ToUpper(loc("getCampaignLevel")), level, starLevel, openExpWnd, null, cost))
  return res.__update({ children = btnComp })
}

let toBattleButton = @(gmId) textButtonBattle(utf8ToUpper(loc("mainmenu/toBattle/short")),
  function() {
    sendNewbieBqEvent("pressToBattleButtonDebriefing", { status = "online_battle" })
    isNoExtraScenesAfterDebriefing.set(true)
    let nextAction = @() showNoPremMessageIfNeed(
      @() offerMissingUnitItemsMessage(curUnit.get(), @() startBattle(gmId)))
    if (needRateGame.get())
      requestShowRateGame(nextAction)
    else
      nextAction()
    closeDebriefing()
  },
  { hotkeys = ["^J:X | Enter"] })

let startOfflineMissionButton = textButtonBattle(utf8ToUpper(loc("mainmenu/toBattle/short")),
  function() {
    sendNewbieBqEvent("pressToBattleButtonDebriefing", { status = "offline_battle" })
    isNoExtraScenesAfterDebriefing.set(true)
    let nextAction = startCurNewbieMission
    if (needRateGame.get())
      requestShowRateGame(nextAction)
    else
      nextAction()
    closeDebriefing()
  },
  { hotkeys = ["^J:X | Enter"] })

let mkStartCustomOfflineBattleButton = @(unitName, missionName) textButtonBattle(utf8ToUpper(loc("mainmenu/toBattle/short")),
  function() {
    isNoExtraScenesAfterDebriefing.set(true)
    let nextAction = @() runOfflineBattle(unitName, missionName)
    if (needRateGame.get())
      requestShowRateGame(nextAction)
    else
      nextAction()
    closeDebriefing()
  },
  { hotkeys = ["^J:X | Enter"] })

let mkBtnUpgradeUnit = @(needShow, campaign) mkBtnAppearAnim(true, needShow, textButtonPrimary(
  utf8ToUpper(loc(upgradeUnitLocIdByCampaign?[campaign] ?? upgradeUnitLocIdByCampaign.tanks)),
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
    ovr = {
      children = commonGlare
      clipChildren = true
    }
  }
))

let mkNextGameModeInfo = @(roomInfo) Computed(function() {
  let rgmId = randomBattleMode.get()?.gameModeId
  let { game_mode_id = rgmId, game_mode_name = null } = roomInfo
  return game_mode_id not in allGameModes.get() || game_mode_id == rgmId || isNewbieMode(game_mode_name)
    ? { gmId = rgmId, isCommonBattle = true }
    : { gmId = game_mode_id, isCommonBattle = false }
})

let mkBtnToBattlePlace = @(needShow, nextGMInfo, debrData) mkBtnAppearAnim(false, needShow,
  function() {
    let { isCustomOfflineBattle = false, unit = null, mission = null } = debrData
    let { gmId, isCommonBattle } = nextGMInfo.get()
    return {
      watch = [newbieOfflineMissions, isInSquad, isSquadLeader, nextGMInfo]
      flow = FLOW_HORIZONTAL
      gap = hdpx(20)
      children = !isInSquad.get() && isCustomOfflineBattle && unit?.name != null && mission != null
          ? [ boostersListActive, mkStartCustomOfflineBattleButton(unit.name, mission) ]
        : !isInSquad.get() && isCommonBattle && newbieOfflineMissions.get() != null
          ? [ boostersListActive, startOfflineMissionButton ]
        : gmId != null && (!isInSquad.get() || isSquadLeader.get())
          ? [ boostersListActive, toBattleButton(gmId) ]
        : null
    }
  })

let mkBtnNewPlatoonUnit = @(needShow, newPlatoonUnit) mkBtnAppearAnim(true, needShow, textButtonBattle(
  utf8ToUpper(loc("msgbox/btn_get")),
  function() {
    isNoExtraScenesAfterDebriefing.set(false)
    function nextAction() {
      let unit = campUnitsCfg.get()?[getBestUnitName(debriefingData.get())]
      if (unit != null) {
        unitDetailsWnd({ name = unit.name, selUnitName = newPlatoonUnit.name })
        requestOpenUnitPurchEffect(newPlatoonUnit)
      }
    }
    if (needRateGame.get())
      requestShowRateGame(nextAction)
    else
      nextAction()
    closeDebriefing()
  },
  { hotkeys = ["^J:X | Enter"] }))

let btnSkip = function() {
  let res = { watch = [ isDebriefingAnimFinished, nextDebrTabId ] }
  return isDebriefingAnimFinished.get() || nextDebrTabId.get() == null ? res : res.__update({
    children = textButtonPrimary(utf8ToUpper(loc("msgbox/btn_skip")),
      function() {
        let nextTabId = nextDebrTabId.get()
        if (nextTabId != null)
          curDebrTabId.set(nextTabId)
      },
      { hotkeys = ["^J:X | Enter"] })
  })
}

function debriefingWnd() {
  let debrData = debriefingData.get()
  let { campaign = "", isWon = false, isTutorial = false, roomInfo = null, isSeparateSlots = false,
    isFinished = false, isDeserter = false, isDisconnected = false, kickInactivity = false
  } = debrData
  let unitName = getBestUnitName(debrData)
  let researchedUnit = getResearchedUnit(debrData)
  let isUnitResearchedAfterTutorial = isTutorial && researchedUnit != null
  let unlockedReward = getSlotOrUnitLevelUnlockRewards(debrData)
  let hasAnyLevelUnlockRewards = unlockedReward.has
  let isFirstLvlUpForSlot = hasAnyLevelUnlockRewards
    && unlockedReward.type == "crew"
    && unlockedReward.levelBeforeBattle == 0
    && slots.get().filter(@(slot) slot.level != 0).len() == 1
  let canStartArsenalTutorial = hasAnyLevelUnlockRewards
    && unlockedReward.type == "arsenal"
    && debrData.completedTutorials?[TUTORIAL_UNITS_RESEARCH_ID]
    && !debrData.completedTutorials?[TUTORIAL_ARSENAL_ID]
    && researchedUnit == null
  let needForceQuitToHangar = isUnitResearchedAfterTutorial
    || isFirstLvlUpForSlot
    || canStartArsenalTutorial
  let hasPlayerLevelUp = !needForceQuitToHangar && isPlayerReceiveLevel(debrData)
  let hasUnitLevelUp = !needForceQuitToHangar && !isSeparateSlots && isUnitReceiveLevel(unitName, debrData)
  let newPlatoonUnit = needForceQuitToHangar ? null : getNewPlatoonUnit(unitName, debrData)

  let tabsParams = {
    needBtnCampaign = hasPlayerLevelUp || researchedUnit != null
    needBtnUnit = newPlatoonUnit != null || (!hasPlayerLevelUp && !researchedUnit && hasUnitLevelUp)
  }
  let debrTabsInfo = mkDebrTabsInfo(debrData, tabsParams)
  let debrTabComps = debrTabsInfo.map(@(v) [ v.id, v.comp ]).totable()
  let tabsShowTime = debrTabsInfo.filter(@(v) v.needAutoAnim).map(@(v)  { id = v.id, timeShow = v.timeShow })
  let debrAnimTime = tabsShowTime.reduce(@(res, v) res + v.timeShow, 0)

  function reinitScene() {
    debrTabsShowTime.set(tabsShowTime)
    curDebrTabId.set(debrTabsInfo?[0].id ?? DEBR_TAB_SCORES)
    isDebriefingAnimFinished.set(debrAnimTime <= 0)
    if (debrAnimTime > 0)
      resetTimeout(debrAnimTime, stopDebriefingAnimation)
    let hangarUnitName = unitName != "" ? unitName : (debrData?.reward.unitName ?? "")
    if (hangarUnitName != "" && !getUnitTags(hangarUnitName)?.hide_in_hangar)
      updateHangarUnit(hangarUnitName)
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
    size = flex()
    padding = saBordersRv
    children = [
      debriefingTabBar(debrData, debrTabsInfo)
      {
        size = flex()
        flow = FLOW_VERTICAL
        gap = hdpx(30)
        children = [
          @() {
            watch = curDebrTabId
            size = flex()
            halign = ALIGN_CENTER
            children = debrTabComps?[curDebrTabId.get()] ?? mkDebriefingEmpty(debrData)
          }
          // Footer
          @() {
            watch = countUpgradeButtonPushed
            size = [flex(), defButtonHeight]
            vplace = ALIGN_BOTTOM
            valign = ALIGN_BOTTOM
            flow = FLOW_HORIZONTAL
            children = [
              {
                size = [flex(), SIZE_TO_CONTENT]
                halign = ALIGN_LEFT
                children = newPlatoonUnit != null || hasPlayerLevelUp || researchedUnit != null || needForceQuitToHangar ? null
                  : hasUnitLevelUp ? mkBtnUpgradeUnit(needShowBtns_Unit, campaign)
                  : mkBtnToHangar(needShowBtns_Final, debrData, false, unlockedReward)
              }
              {
                size = [flex(), SIZE_TO_CONTENT]
                halign = ALIGN_RIGHT
                children = {
                  flow = FLOW_HORIZONTAL
                  gap = buttonsHGap
                  children = (needForceQuitToHangar ? [ //warning disable: -unwanted-modification
                        mkBtnToHangar(needShowBtns_Final, debrData, true, unlockedReward)
                      ]
                    : hasPlayerLevelUp ? [
                        buttonDescText(needShowBtns_Campaign, loc("levelUp/playerLevelUp"))
                        mkBtnLevelUp(needShowBtns_Campaign)
                      ]
                    : researchedUnit != null ? [
                        buttonDescText(needShowBtns_Campaign, loc("unitsTree/researchCompleted"))
                        mkBtnNewUnitResearched(needShowBtns_Campaign, researchedUnit)
                      ]
                    : newPlatoonUnit != null ? [
                        buttonDescText(needShowBtns_Unit, loc("levelUp/receiveNewPlatoonUnit"))
                        mkBtnNewPlatoonUnit(needShowBtns_Unit, newPlatoonUnit)
                      ]
                    : hasUnitLevelUp && countUpgradeButtonPushed.get() < minCountUpgradeButtonPushed ? [
                      ]
                    : [
                        mkBtnBuyNextPlayerLevel(Computed(@() curDebrTabId.get() == DEBR_TAB_CAMPAIGN),
                          debrData?.player.level ?? -1, campaign)
                        mkBtnToBattlePlace(needShowBtns_Final, mkNextGameModeInfo(roomInfo), debrData)
                      ]
                  ).append(btnSkip)  //warning disable: -unwanted-modification
                }
              }
            ]
          }
        ]
      }
    ]
  })
}

registerScene("debriefingWnd", debriefingWnd, closeDebriefing, isInDebriefing)
