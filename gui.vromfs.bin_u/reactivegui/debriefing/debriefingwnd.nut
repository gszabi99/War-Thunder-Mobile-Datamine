from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { playSound } = require("sound_wt")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { registerScene } = require("%rGui/navState.nut")
let { textButtonPrimary, textButtonBattle, buttonsHGap } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { commonGlare } = require("%rGui/components/glare.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { openUnitAttrWnd } = require("%rGui/unitAttr/unitAttrState.nut")
let { debriefingData, curDebrTabId, isDebriefingAnimFinished, isNoExtraScenesAfterDebriefing,
  DEBR_TAB_CAMPAIGN, DEBR_TAB_UNIT
} = require("debriefingState.nut")
let { randomBattleMode } = require("%rGui/gameModes/gameModeState.nut")
let { newbieOfflineMissions, startCurNewbieMission } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let offerMissingUnitItemsMessage = require("%rGui/shop/offerMissingUnitItemsMessage.nut")
let { requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { needRateGame } = require("%rGui/feedback/rateGameState.nut")
let { requestShowRateGame } = require("%rGui/feedback/rateGame.nut")
let { isInSquad, isSquadLeader } = require("%appGlobals/squadState.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let showNoPremMessageIfNeed = require("%rGui/shop/missingPremiumAccWnd.nut")
let { buttonsShowTime } = require("debriefingWndConsts.nut")
let { getRewardsInfo } = require("totalRewardCounts.nut")
let mkDebrTabsInfo = require("mkDebrTabsInfo.nut")
let debriefingTabBar = require("debriefingTabBar.nut")
let mkDebriefingEmpty = require("mkDebriefingEmpty.nut")

local isAttached = false

let closeDebriefing = @() send("Debriefing_CloseInDagui", {})
let startBattle = @() send("queueToGameMode", { modeId = randomBattleMode.get()?.gameModeId }) //FIXME: Should to use game mode from debriefing

const SAVE_ID_UPGRADE_BUTTON_PUSHED = "debriefingUpgradeButtonPushed"
let countUpgradeButtonPushed = Watched(get_local_custom_settings_blk()?[SAVE_ID_UPGRADE_BUTTON_PUSHED] ?? 0)
let minCountUpgradeButtonPushed = 3

let updateHangarUnit = @(unitId) unitId == null ? null : setHangarUnit(unitId)

let buttonDescText = @(delay, text) {
  maxWidth = hdpx(400)
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color = 0xFFFFFFFF

  key = {}
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, delay, duration = 0.3, easing = OutQuad, play = true }
  ]
}.__update(fontSmall)

let mkBtnAppearAnim = @(needBlink, delay, children) {
  key = {}
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, delay, duration = 0.3, easing = OutQuad, play = true }
  ].extend(!needBlink ? [] : [
    { prop = AnimProp.scale, from = [1, 1], to = [1.3, 1.3], delay, duration = 0.5, easing = Blink, play = true }
  ])
  children
}

let mkBtnToHangar = @(delay, campaign) mkBtnAppearAnim(false, delay, textButtonPrimary(
  utf8ToUpper(loc(campaign == "ships" ? "return_to_port/short" : "return_to_hangar/short")),
  function() {
    isNoExtraScenesAfterDebriefing.set(true)
    if (needRateGame.get())
      return requestShowRateGame()
    closeDebriefing()
  },
  { hotkeys = [btnBEscUp] }))

let mkBtnLevelUp = @(delay) mkBtnAppearAnim(true, delay, textButtonBattle(
  utf8ToUpper(loc("msgbox/btn_get")),
  function() {
    isNoExtraScenesAfterDebriefing.set(false)
    if (needRateGame.get())
      return requestShowRateGame()
    closeDebriefing()
  },
  { hotkeys = ["^J:X | Enter"] }))

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

let mkBtnUpgradeUnit = @(delay, campaign) mkBtnAppearAnim(true, delay, textButtonPrimary(
  utf8ToUpper(loc(campaign == "tanks" ? "mainmenu/btnUpgradePlatoon" : "mainmenu/btnUpgradeShip")),
  function() {
    isNoExtraScenesAfterDebriefing.set(false)
    if (needRateGame.get())
      return requestShowRateGame()
    countUpgradeButtonPushed.set(countUpgradeButtonPushed.get() + 1)
    get_local_custom_settings_blk()[SAVE_ID_UPGRADE_BUTTON_PUSHED] = countUpgradeButtonPushed.get()
    send("saveProfile", {})
    updateHangarUnit(debriefingData.get()?.unit.name)
    openUnitAttrWnd()
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

let mkBtnToBattlePlace = @(delay) mkBtnAppearAnim(false, delay, @() {
  watch = [newbieOfflineMissions, isInSquad, isSquadLeader]
  children = !isInSquad.get() && newbieOfflineMissions.get() != null ? startOfflineMissionButton
    : !isInSquad.get() || isSquadLeader.get() ? toBattleButton
    : null
})

let mkBtnNewPlatoonUnit = @(delay, newPlatoonUnit) mkBtnAppearAnim(true, delay, textButtonBattle(
  utf8ToUpper(loc("msgbox/btn_get")),
  function() {
    isNoExtraScenesAfterDebriefing.set(false)
    if (needRateGame.get())
      return requestShowRateGame()
    closeDebriefing()
    unitDetailsWnd({ name = debriefingData.get()?.unit.name, selUnitName = newPlatoonUnit.name })
    requestOpenUnitPurchEffect(newPlatoonUnit)
  },
  { hotkeys = ["^J:X | Enter"] }))

let function isPlayerReceiveLevel(debrData) {
  let { exp = 0, nextLevelExp = 0 } = debrData?.player
  return nextLevelExp != 0
    && nextLevelExp != exp
    && (nextLevelExp <= (exp + (debrData?.reward.playerExp.totalExp ?? 0)))
}

let function isUnitReceiveLevel(debrData) {
  let { totalExp = 0 } = debrData?.reward.unitExp
  let { exp = 0, nextLevelExp = 0 } = debrData?.unit
  if (nextLevelExp <= 0 || totalExp <= 0)
    return false
  return exp + totalExp >= nextLevelExp
}

let function getNewPlatoonUnit(debrData) {
  let { unit = null, reward = null } = debrData
  if (unit == null)
    return null
  let { level = 0, exp = 0, levelsExp = [], lockedUnits = [] } = unit
  let { totalExp = 0 } = reward?.unitExp
  if (totalExp == 0 || lockedUnits.len() == 0)
    return null
  local pReqLevel = -1
  local pUnitName = null
  foreach(pUnit in lockedUnits) {
    let { reqLevel = 0, name } = pUnit
    if (reqLevel > level && (pUnitName == null || reqLevel < pReqLevel)) {
      pReqLevel = reqLevel
      pUnitName = name
    }
  }
  if (pUnitName == null || levelsExp.len() < pReqLevel)
    return null

  local leftExp = totalExp + exp
  for (local l = level; l < pReqLevel; l++)
    leftExp -= levelsExp[l]
  return leftExp >= 0 ? unit.__merge({ name = pUnitName }) : null
}

let function debriefingWnd() {
  let debrData = debriefingData.get()
  let { campaign = "", isWon = false, reward = {} } = debrData

  let rewardsInfo = getRewardsInfo(debrData)

  let hasPlayerLevelUp = isPlayerReceiveLevel(debrData)
  let hasUnitLevelUp = isUnitReceiveLevel(debrData)
  let newPlatoonUnit = getNewPlatoonUnit(debrData)

  let tabsParams = {
    needBtnCampaign = hasPlayerLevelUp
    needBtnUnit = newPlatoonUnit != null || (!hasPlayerLevelUp && hasUnitLevelUp)
  }
  let debrTabsInfo = mkDebrTabsInfo(debrData, rewardsInfo, tabsParams)
  let debrTabsInfoMap = debrTabsInfo.map(@(v) [ v.id, v ]).totable()

  let tabButtonsShowTime_Campaign = max(0, (debrTabsInfoMap?[DEBR_TAB_CAMPAIGN].timeEnd ?? 0) - buttonsShowTime)
  let tabButtonsShowTime_Unit = max(0, (debrTabsInfoMap?[DEBR_TAB_UNIT].timeEnd ?? 0) - buttonsShowTime)
  let tabButtonsShowTime_Final = debrTabsInfo?[debrTabsInfo.len() - 1].timeEnd ?? 0

  let function reinitScene() {
    if (debrTabsInfo.len())
      curDebrTabId.set(debrTabsInfo[0].id)
    updateHangarUnit(reward?.unitName)
    playSound(isWon ? "stats_winner_start" : "stats_looser_start")
    if (tabButtonsShowTime_Final > 0) {
      isDebriefingAnimFinished.set(false)
      resetTimeout(tabButtonsShowTime_Final, @() isDebriefingAnimFinished.set(true))
    }
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
            children = debrTabsInfoMap?[curDebrTabId.get()].comp ?? mkDebriefingEmpty(debrData)
          }
          // Footer
          @() {
            watch = countUpgradeButtonPushed
            size = [flex(), defButtonHeight]
            vplace = ALIGN_BOTTOM
            valign = ALIGN_BOTTOM
            flow = FLOW_HORIZONTAL
            children = [
              @() {
                size = [flex(), SIZE_TO_CONTENT]
                halign = ALIGN_LEFT
                flow = FLOW_VERTICAL
                gap = hdpx(60)
                children = newPlatoonUnit != null || hasPlayerLevelUp ? null
                  : hasUnitLevelUp ? mkBtnUpgradeUnit(tabButtonsShowTime_Unit, campaign)
                  : mkBtnToHangar(tabButtonsShowTime_Final, campaign)
              }
              @() {
                size = [flex(), SIZE_TO_CONTENT]
                halign = ALIGN_RIGHT
                flow = FLOW_VERTICAL
                gap = hdpx(60)
                children = {
                  flow = FLOW_HORIZONTAL
                  gap = buttonsHGap
                  children = hasPlayerLevelUp ? [
                        buttonDescText(tabButtonsShowTime_Campaign - 0.3, loc("levelUp/playerLevelUp"))
                        mkBtnLevelUp(tabButtonsShowTime_Campaign)
                      ]
                    : newPlatoonUnit != null ? [
                        buttonDescText(tabButtonsShowTime_Unit - 0.3, loc("levelUp/receiveNewPlatoonUnit"))
                        mkBtnNewPlatoonUnit(tabButtonsShowTime_Unit, newPlatoonUnit)
                      ]
                    : hasUnitLevelUp ? [
                        minCountUpgradeButtonPushed <= countUpgradeButtonPushed.get()
                          ? mkBtnToBattlePlace(tabButtonsShowTime_Final)
                          : null
                      ]
                    : mkBtnToBattlePlace(tabButtonsShowTime_Final)
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
