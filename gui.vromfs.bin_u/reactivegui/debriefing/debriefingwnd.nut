from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { playSound } = require("sound_wt")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { curUnit, playerLevelInfo, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { registerScene } = require("%rGui/navState.nut")
let { textButtonPrimary, textButtonBattle, buttonsHGap } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { commonGlare } = require("%rGui/components/glare.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { openUnitAttrWnd } = require("%rGui/unitAttr/unitAttrState.nut")
let { debriefingData, curDebrTabId, nextDebrTabId, isDebriefingAnimFinished, isNoExtraScenesAfterDebriefing,
  DEBR_TAB_SCORES, DEBR_TAB_CAMPAIGN, debrTabsShowTime, stopDebriefingAnimation,
  needShowBtns_Campaign, needShowBtns_Unit, needShowBtns_Final,
} = require("debriefingState.nut")
let { randomBattleMode } = require("%rGui/gameModes/gameModeState.nut")
let { newbieOfflineMissions, startCurNewbieMission } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let offerMissingUnitItemsMessage = require("%rGui/shop/offerMissingUnitItemsMessage.nut")
let { requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { textButtonPlayerLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { needRateGame } = require("%rGui/feedback/rateGameState.nut")
let { requestShowRateGame } = require("%rGui/feedback/rateGame.nut")
let { isInSquad, isSquadLeader } = require("%appGlobals/squadState.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { lvlUpCost } = require("%rGui/levelUp/levelUpState.nut")
let { openExpWnd } = require("%rGui/mainMenu/expWndState.nut")
let showNoPremMessageIfNeed = require("%rGui/shop/missingPremiumAccWnd.nut")
let { isPlayerReceiveLevel, isUnitReceiveLevel, getNewPlatoonUnit } = require("debrUtils.nut")
let mkDebrTabsInfo = require("mkDebrTabsInfo.nut")
let debriefingTabBar = require("debriefingTabBar.nut")
let mkDebriefingEmpty = require("mkDebriefingEmpty.nut")
let boostersListActive = require("%rGui/boosters/boostersListActive.nut")

local isAttached = false

let closeDebriefing = @() eventbus_send("Debriefing_CloseInDagui", {})
let startBattle = @() eventbus_send("queueToGameMode", { modeId = randomBattleMode.get()?.gameModeId }) //FIXME: Should to use game mode from debriefing

const SAVE_ID_UPGRADE_BUTTON_PUSHED = "debriefingUpgradeButtonPushed"
let countUpgradeButtonPushed = Watched(get_local_custom_settings_blk()?[SAVE_ID_UPGRADE_BUTTON_PUSHED] ?? 0)
let minCountUpgradeButtonPushed = 3

let updateHangarUnit = @(unitId) unitId == null ? null : setHangarUnit(unitId)

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

let mkBtnToHangar = @(needShow, campaign) mkBtnAppearAnim(false, needShow, textButtonPrimary(
  utf8ToUpper(loc(campaign == "ships" ? "return_to_port/short" : "return_to_hangar/short")),
  function() {
    isNoExtraScenesAfterDebriefing.set(true)
    if (needRateGame.get())
      return requestShowRateGame()
    closeDebriefing()
  },
  { hotkeys = [btnBEscUp] }))

let mkBtnLevelUp = @(needShow) mkBtnAppearAnim(true, needShow, textButtonBattle(
  utf8ToUpper(loc("msgbox/btn_get")),
  function() {
    isNoExtraScenesAfterDebriefing.set(false)
    if (needRateGame.get())
      return requestShowRateGame()
    closeDebriefing()
  },
  { hotkeys = ["^J:X | Enter"] }))

let mkBtnBuyNextPlayerLevel = @(needShow, curPlayerLevel) function() {
  let res = {
    watch = [playerLevelInfo, lvlUpCost]
  }
  let { level, starLevel, isMaxLevel, isReadyForLevelUp } = playerLevelInfo.get()
  if (level > curPlayerLevel || isMaxLevel || isReadyForLevelUp)
    return res

  let cost = { price = lvlUpCost.get(), currencyId = GOLD }
  let btnComp = mkBtnAppearAnim(false, needShow,
    textButtonPlayerLevelUp(utf8ToUpper(loc("getCampaignLevel")), level, starLevel, openExpWnd, null, cost))
  return res.__update({ children = btnComp })
}

let toBattleButton = textButtonBattle(utf8ToUpper(loc("mainmenu/toBattle/short")),
  function() {
    sendNewbieBqEvent("pressToBattleButtonDebriefing", { status = "online_battle" })
    isNoExtraScenesAfterDebriefing.set(true)
    if (needRateGame.get())
      return requestShowRateGame()
    showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnit.get(), startBattle))
    closeDebriefing()
  },
  { hotkeys = ["^J:X | Enter"] })

let startOfflineMissionButton = textButtonBattle(utf8ToUpper(loc("mainmenu/toBattle/short")),
  function() {
    sendNewbieBqEvent("pressToBattleButtonDebriefing", { status = "offline_battle" })
    isNoExtraScenesAfterDebriefing.set(true)
    if (needRateGame.get())
      return requestShowRateGame()
    startCurNewbieMission()
    closeDebriefing()
  },
  { hotkeys = ["^J:X | Enter"] })

let mkBtnUpgradeUnit = @(needShow, campaign) mkBtnAppearAnim(true, needShow, textButtonPrimary(
  utf8ToUpper(loc(campaign == "tanks" ? "mainmenu/btnUpgradePlatoon" : "mainmenu/btnUpgradeShip")),
  function() {
    isNoExtraScenesAfterDebriefing.set(false)
    if (needRateGame.get())
      return requestShowRateGame()
    countUpgradeButtonPushed.set(countUpgradeButtonPushed.get() + 1)
    get_local_custom_settings_blk()[SAVE_ID_UPGRADE_BUTTON_PUSHED] = countUpgradeButtonPushed.get()
    eventbus_send("saveProfile", {})
    let unit = allUnitsCfg.get()?[debriefingData.get()?.unit.name]
    if (unit != null) {
      updateHangarUnit(unit.name)
      openUnitAttrWnd()
    }
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

let mkBtnToBattlePlace = @(needShow) mkBtnAppearAnim(false, needShow, @() {
  watch = [newbieOfflineMissions, isInSquad, isSquadLeader]
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = !isInSquad.get() && newbieOfflineMissions.get() != null ? [ boostersListActive, startOfflineMissionButton ]
    : !isInSquad.get() || isSquadLeader.get() ? [ boostersListActive, toBattleButton ]
    : null
})

let mkBtnNewPlatoonUnit = @(needShow, newPlatoonUnit) mkBtnAppearAnim(true, needShow, textButtonBattle(
  utf8ToUpper(loc("msgbox/btn_get")),
  function() {
    isNoExtraScenesAfterDebriefing.set(false)
    if (needRateGame.get())
      return requestShowRateGame()
    closeDebriefing()
    let unit = allUnitsCfg.get()?[debriefingData.get()?.unit.name]
    if (unit != null) {
      unitDetailsWnd({ name = unit.name, selUnitName = newPlatoonUnit.name })
      requestOpenUnitPurchEffect(newPlatoonUnit)
    }
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
  let { campaign = "", isWon = false, reward = {} } = debrData

  let hasPlayerLevelUp = isPlayerReceiveLevel(debrData)
  let hasUnitLevelUp = isUnitReceiveLevel(debrData)
  let newPlatoonUnit = getNewPlatoonUnit(debrData)

  let tabsParams = {
    needBtnCampaign = hasPlayerLevelUp
    needBtnUnit = newPlatoonUnit != null || (!hasPlayerLevelUp && hasUnitLevelUp)
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
    updateHangarUnit(reward?.unitName)
    playSound(isWon ? "stats_winner_start" : "stats_looser_start")
    sendNewbieBqEvent("openDebriefing", { status = isWon ? "win" : "loose" })
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
                children = newPlatoonUnit != null || hasPlayerLevelUp ? null
                  : hasUnitLevelUp ? mkBtnUpgradeUnit(needShowBtns_Unit, campaign)
                  : mkBtnToHangar(needShowBtns_Final, campaign)
              }
              {
                size = [flex(), SIZE_TO_CONTENT]
                halign = ALIGN_RIGHT
                children = {
                  flow = FLOW_HORIZONTAL
                  gap = buttonsHGap
                  children = (hasPlayerLevelUp ? [   //warning disable: -unwanted-modification
                        buttonDescText(needShowBtns_Campaign, loc("levelUp/playerLevelUp"))
                        mkBtnLevelUp(needShowBtns_Campaign)
                      ]
                    : newPlatoonUnit != null ? [
                        buttonDescText(needShowBtns_Unit, loc("levelUp/receiveNewPlatoonUnit"))
                        mkBtnNewPlatoonUnit(needShowBtns_Unit, newPlatoonUnit)
                      ]
                    : hasUnitLevelUp && countUpgradeButtonPushed.get() < minCountUpgradeButtonPushed ? [
                      ]
                    : [
                        mkBtnBuyNextPlayerLevel(Computed(@() curDebrTabId.get() == DEBR_TAB_CAMPAIGN),
                          debrData?.player.level ?? -1)
                        mkBtnToBattlePlace(needShowBtns_Final)
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
