from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { mkGamercard } = require("%rGui/mainMenu/gamercard.nut")
let offerPromo = require("%rGui/shop/offerPromo.nut")
let { textButtonBattle } = require("%rGui/components/textButton.nut")
let { translucentButton, translucentButtonsVGap } = require("%rGui/components/translucentButton.nut")
let { hangarUnit, setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { curUnit, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { mkPlatoonOrUnitTitle } = require("%rGui/unit/components/unitInfoPanel.nut")
let unitsWnd = require("%rGui/unit/unitsWnd.nut")
let { openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let btnOpenUnitAttr = require("%rGui/unitAttr/btnOpenUnitAttr.nut")
let { firstBattleTutor, needFirstBattleTutor, startTutor } = require("%rGui/tutorial/tutorialMissions.nut")
let { isMainMenuAttached } = require("mainMenuState.nut")
let { randomBattleMode } = require("%rGui/gameModes/gameModeState.nut")
let { totalPlayers } = require("%appGlobals/gameModes/gameModes.nut")
let { campaignsList, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let chooseCampaignWnd = require("chooseCampaignWnd.nut")
let offerMissingUnitItemsMessage = require("%rGui/shop/offerMissingUnitItemsMessage.nut")
let mkUnitPkgDownloadInfo = require("%rGui/unit/mkUnitPkgDownloadInfo.nut")
let { startTestFlight } = require("%rGui/gameModes/startOfflineMode.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")
let downloadInfoBlock = require("%rGui/updater/downloadInfoBlock.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { newbieOfflineMissions, startCurNewbieMission } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let { allow_players_online_info } = require("%appGlobals/permissions.nut")
let { lqTexturesWarningHangar } = require("%rGui/hudHints/lqTexturesWarning.nut")
let { mkGradRank } = require("%rGui/shop/goodsView/sharedParts.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { curUnitMRankRange } = require("%rGui/state/matchingRank.nut")
let { itemsOrder } = require("%appGlobals/itemsState.nut")
let { mkItemsBalance } = require("balanceComps.nut")
let { SC_CONSUMABLES } = require("%rGui/shop/shopCommon.nut")
let { openShopWnd } = require("%rGui/shop/shopState.nut")


let unitNameStateFlags = Watched(0)

let mainMenuUnitToShow = keepref(Computed(function() {
  if (!isMainMenuAttached.value)
    return null
  return curUnit.value?.name
    ?? allUnitsCfg.value.reduce(@(res, unit) res == null || res.rank > unit.rank ? unit : res)?.name
}))

mainMenuUnitToShow.subscribe(@(unitId) unitId == null ? null : setHangarUnit(unitId))

let unitName = @() hangarUnit.value == null ? { watch = hangarUnit }
  : {
    watch = [hangarUnit, unitNameStateFlags]
    onElemState = @(sf) unitNameStateFlags(sf)
    behavior = Behaviors.Button
    flow = FLOW_HORIZONTAL
    gap = hdpx(24)
    onClick = @() unitDetailsWnd({ name = hangarUnit.value.name })
    children = [
      mkPlatoonOrUnitTitle(
        hangarUnit.value, {}, unitNameStateFlags.value & S_HOVER ? { color = hoverColor } : {})
      mkGradRank(hangarUnit.value.mRank)
    ]
  }

let campaignsBtnComp = translucentButton("ui/gameuiskin#campaign.svg",
  loc("changeCampaign"), chooseCampaignWnd)

let campaignsBtn = @() {
  watch = campaignsList
  margin = [hdpx(20), 0]
  children = campaignsList.value.len() <= 1 ? null
    : campaignsBtnComp
}

let onlineInfo = @() {
  watch = [totalPlayers, allow_players_online_info]
  rendObj = ROBJ_TEXT
  text = !allow_players_online_info.value || totalPlayers.value < 0
    ? null
    : loc("mainmenu/online_info/player_online", {
        playersOnline = totalPlayers.value
      })
  color = 0xD0D0D0D0
}.__update(fontVeryTinyShaded)

let gamercardPlace = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    mkGamercard(null, true)
    {
      size = [flex(), SIZE_TO_CONTENT]
      children = [
        {
          pos = [0, hdpx(45)]
          children = [
            onlineInfo
            downloadInfoBlock
          ]
        }
        {
          hplace = ALIGN_RIGHT
          children = offerPromo
        }
      ]
    }
  ]
}

let unitsBtnCfg = {
  ships = { img = "ui/gameuiskin#unit_ship.svg", txt = loc("options/chooseUnitsType/ship") }
  tanks = { img = "ui/gameuiskin#unit_tank.svg", txt = loc("options/chooseUnitsType/tank") }
}

let leftBottomButtons = @() {
  watch = curCampaign
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = translucentButtonsVGap
  children = [
    campaignsBtn
    btnOpenUnitAttr
    translucentButton(unitsBtnCfg?[curCampaign.value].img ?? "", unitsBtnCfg?[curCampaign.value].txt ?? "",
      function() {
        unitsWnd()
        openLvlUpWndIfCan()
      })
  ]
}


let queueCurRandomBattleMode = @() send("queueToGameMode", { modeId = randomBattleMode.value?.gameModeId })

let hotkeyX = ["^J:X | Enter"]
let toBattleText = utf8ToUpper(loc("mainmenu/toBattle/short"))
let toBattleButton = textButtonBattle(toBattleText,
  function() {
    if (curUnit.value != null)
      offerMissingUnitItemsMessage(curUnit.value, queueCurRandomBattleMode)
    else if (!openLvlUpWndIfCan())
      logerr($"Unable to start battle because no units (unit in hangar = {hangarUnit.value?.name})")
  },
  { hotkeys = hotkeyX })
let startTutorButton = textButtonBattle(toBattleText,
  @() startTutor(firstBattleTutor.value),
  { ovr = { key = "toBattleButton" }, hotkeys = hotkeyX })
let startTestFlightButton = textButtonBattle(toBattleText,
  @() startTestFlight(curUnit.value?.name),
  { hotkeys = hotkeyX })
let startOfflineMissionButton = textButtonBattle(toBattleText, startCurNewbieMission, { hotkeys = hotkeyX })

let mkMRankRange = @() curUnitMRankRange.value == null
  ? { watch = curUnitMRankRange }
  : {
      watch = curUnitMRankRange
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = hdpx(12)
      children = [
        { rendObj = ROBJ_TEXT, text = loc("mainmenu/battleTiers") }.__update(fontTinyAccented)
        mkGradRank(curUnitMRankRange.value.minMRank)
        { rendObj = ROBJ_TEXT, text = "-" }.__update(fontTinyAccented)
        mkGradRank(curUnitMRankRange.value.maxMRank)
      ]
    }

let consumablesPanel = @(){
  watch = itemsOrder
  flow = FLOW_HORIZONTAL
  children = itemsOrder.value.map(@(id) mkItemsBalance(id, @() openShopWnd(SC_CONSUMABLES)))
}

let toBattleButtonPlace = @() {
  watch = [needFirstBattleTutor, newbieOfflineMissions]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  children = [
    {
      rendObj = ROBJ_9RECT
      image = gradTranspDoubleSideX
      padding = [ hdpx(24), 0, hdpx(12), 0 ]
      texOffs = [0 , gradDoubleTexOffset]
      screenOffs = [0, hdpx(70)]
      color = 0x50000000
      flow = FLOW_VERTICAL
      halign = ALIGN_RIGHT
      children = [
        unitName
        consumablesPanel
        mkMRankRange
      ]
    }
    isOfflineMenu ? startTestFlightButton
      : needFirstBattleTutor.value ? startTutorButton
      : newbieOfflineMissions.value != null ? startOfflineMissionButton
      : toBattleButton
  ]
}

let exitMsgBox = @() openMsgBox({
  text = loc("mainmenu/questionQuitGame")
  buttons = [
    { id = "no", isCancel = true }
    { id = "yes", styleId = "PRIMARY", cb = @() send("exitGame", {}) }
  ]
})

return {
  key = {}
  size = saSize
  behavior = Behaviors.HangarCameraControl
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  onAttach = @() isMainMenuAttached(true)
  onDetach = @() isMainMenuAttached(false)
  children = [
    lqTexturesWarningHangar
    gamercardPlace
    leftBottomButtons
    toBattleButtonPlace
    mkUnitPkgDownloadInfo(curUnit, false)
  ]
  animations = wndSwitchAnim
  hotkeys = [
    ["Esc", {action=exitMsgBox}]
  ]
}
