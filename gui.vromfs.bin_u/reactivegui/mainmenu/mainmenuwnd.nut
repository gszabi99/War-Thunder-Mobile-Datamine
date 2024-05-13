from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { HangarCameraControl } = require("wt.behaviors")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { mkGamercard } = require("%rGui/mainMenu/gamercard.nut")
let offerPromo = require("%rGui/shop/offerPromo.nut")
let { translucentButtonsVGap, translucentButtonsHeight } = require("%rGui/components/translucentButton.nut")
let { gamercardGap, CS_COMMON } = require("%rGui/components/currencyStyles.nut")
let { hangarUnit, setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { itemsOrder } = require("%appGlobals/itemsState.nut")
let { unitSpecificItems } = require("%appGlobals/unitSpecificItems.nut")
let { curUnit, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { mkPlatoonOrUnitTitle } = require("%rGui/unit/components/unitInfoPanel.nut")
let { btnOpenUnitAttr } = require("%rGui/unitAttr/btnOpenUnitAttr.nut")
let { isMainMenuAttached } = require("mainMenuState.nut")
let { totalPlayers } = require("%appGlobals/gameModes/gameModes.nut")
let { curCampaign, campaignsList } = require("%appGlobals/pServer/campaign.nut")
let chooseCampaignWnd = require("chooseCampaignWnd.nut")
let mkUnitPkgDownloadInfo = require("%rGui/unit/mkUnitPkgDownloadInfo.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")
let downloadInfoBlock = require("%rGui/updater/downloadInfoBlock.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { newbieOfflineMissions } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let { allow_players_online_info } = require("%appGlobals/permissions.nut")
let { lqTexturesWarningHangar } = require("%rGui/hudHints/lqTexturesWarning.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { mkMRankRange } = require("%rGui/state/matchingRank.nut")
let squadPanel = require("%rGui/squad/squadPanel.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { btnOpenQuests } = require("%rGui/quests/btnOpenQuests.nut")
let { specialEventGamercardItems, openEventWnd } = require("%rGui/event/eventState.nut")
let btnsOpenSpecialEvents = require("%rGui/event/btnsOpenSpecialEvents.nut")
let bpBanner = require("%rGui/battlePass/bpBanner.nut")
let { openShopWnd } = require("%rGui/shop/shopState.nut")
let { SC_CONSUMABLES } = require("%rGui/shop/shopCommon.nut")
let btnOpenUnitsTree = require("%rGui/unitsTree/btnOpenUnitsTree.nut")
let { mkDropMenuBtn } = require("%rGui/components/mkDropDownMenu.nut")
let { getTopMenuButtons, topMenuButtonsGenId } = require("%rGui/mainMenu/topMenuButtonsList.nut")
let { mkItemsBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { toBattleButtonForRandomBattles } = require("%rGui/mainMenu/toBattleButton.nut")
let { framedImageBtn } = require("%rGui/components/imageButton.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { boostersListActive, boostersHeight } = require("%rGui/boosters/boostersListActive.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { unseenSkins } = require("%rGui/unitSkins/unseenSkins.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { DBGLEVEL } = require("dagor.system")
let { unitPlateTiny } = require("%rGui/unit/components/unitPlateComp.nut")

let unitNameStateFlags = Watched(0)

let mainMenuUnitToShow = keepref(Computed(function() {
  if (!isMainMenuAttached.value)
    return null
  return curUnit.value?.name
    ?? allUnitsCfg.value.reduce(@(res, unit) res == null || res.rank > unit.rank ? unit : res)?.name
}))

mainMenuUnitToShow.subscribe(@(unitId) unitId == null ? null : setHangarUnit(unitId))

let mkUnitName = @(unit) @() {
  watch = unitNameStateFlags
  onElemState = @(sf) unitNameStateFlags(sf)
  behavior = Behaviors.Button
  flow = FLOW_HORIZONTAL
  gap = hdpx(24)
  onClick = @() unitDetailsWnd({ name = unit.name })
  children = [
    mkPlatoonOrUnitTitle(
      unit, {}, unitNameStateFlags.value & S_HOVER ? { color = hoverColor } : {})
    mkGradRank(unit.mRank)
  ]
}

let unitNameBlock = @() hangarUnit.get() == null ? { watch = hangarUnit }
  : {
      watch = [hangarUnit, unseenSkins]
      children = [
        mkUnitName(hangarUnit.get())
        hangarUnit.get().name not in unseenSkins.get() ? null
          : priorityUnseenMark.__merge({ hplace = ALIGN_RIGHT, pos = [hdpx(20), hdpx(-20)] })
      ]
    }

let campaignsBtn = @() {
  watch = [campaignsList, curCampaign]
  children = campaignsList.value.len() <= 1 || curCampaign.value == null  ? null
    : framedImageBtn(getCampaignPresentation(curCampaign.value).icon, chooseCampaignWnd,
        {
          padding = [hdpx(0), hdpx(20), hdpx(0), hdpx(20) ]
          size = SIZE_TO_CONTENT
          sound = { click = "click" }
          imageSize = [hdpx(70) , hdpx(70)]
          flow = FLOW_HORIZONTAL
          gap = hdpx(20)
        },
        {
          size = [SIZE_TO_CONTENT, flex()]
          rendObj = ROBJ_TEXT
          valign = ALIGN_CENTER
          color = 0xFFFFFFFF
          text = loc("changeCampaignShort")
          fontFx = FFT_GLOW
          fontFxFactor = 64
          fontFxColor = Color(0, 0, 0)
        }.__update(fontTinyAccented)
      )
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

let dropMenuBtn = mkDropMenuBtn(getTopMenuButtons, topMenuButtonsGenId)

let gamercardPlace = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    mkGamercard(dropMenuBtn)
    {
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_RIGHT
      children = offerPromo
    }
  ]
}

let btnHorRow = @(children) {
  flow = FLOW_HORIZONTAL
  gap = translucentButtonsVGap
  children
}

let btnVerRow = @(children) {
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = translucentButtonsVGap
  children
}

let leftBottomButtons = btnVerRow([
  campaignsBtn
  @() {
    watch = newbieOfflineMissions
    children = newbieOfflineMissions.get() != null && DBGLEVEL == 0 ? null : btnVerRow([
      bpBanner
      btnHorRow([
        btnOpenQuests
        btnsOpenSpecialEvents
      ])
    ])
  }
  btnHorRow([
    btnVerRow([
      @() {
        watch = curCampaign
        children = curCampaign.get() != "air" ? btnOpenUnitAttr  : null
      }
      btnOpenUnitsTree
    ])
    btnVerRow([
      onlineInfo
      downloadInfoBlock
    ])
  ])
  // TODO: slotbar
  @() curCampaign.get() != "air" ? { watch = curCampaign }
    : {
        watch = curCampaign
        size = [unitPlateTiny[0] * 4 + hdpx(30), unitPlateTiny[1] + translucentButtonsHeight * 0.8]
      }
])

let gamercardBattleItemsBalanceBtns = @(){
  watch = [itemsOrder, specialEventGamercardItems, unitSpecificItems]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = specialEventGamercardItems.get().map(@(v) mkItemsBalance(v.itemId, @() openEventWnd(v.eventName), CS_COMMON))
    .extend(itemsOrder.get().map(@(id) mkItemsBalance(id, @() openShopWnd(SC_CONSUMABLES), CS_COMMON)))
    .extend(unitSpecificItems.get().map(@(id) mkItemsBalance(id, @() openShopWnd(SC_CONSUMABLES), CS_COMMON)))
}

let toBattleButtonPlace = {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  children = [
    {
      halign = ALIGN_RIGHT
      flow = FLOW_VERTICAL
      children = [
        squadPanel
        @() {
          watch = serverConfigs
          size = [SIZE_TO_CONTENT, boostersHeight]
          valign = ALIGN_CENTER
          children = (serverConfigs.get()?.allBoosters.len() ?? 0) > 0 ? boostersListActive : null
        }
      ]
    }
    {
      pos = [saBorders[0] * 0.5, 0]
      rendObj = ROBJ_9RECT
      image = gradTranspDoubleSideX
      padding = [ hdpx(12), saBorders[0] * 0.5]
      texOffs = [0 , gradDoubleTexOffset]
      screenOffs = [0, hdpx(70)]
      color = 0x50000000
      flow = FLOW_VERTICAL
      halign = ALIGN_RIGHT
      children = [
        unitNameBlock
        gamercardBattleItemsBalanceBtns
        mkMRankRange
      ]
    }
    toBattleButtonForRandomBattles
  ]
}

let exitMsgBox = @() openMsgBox({
  text = loc("mainmenu/questionQuitGame")
  buttons = [
    { id = "cancel", isCancel = true }
    { text = loc("mainmenu/btnQuit"), styleId = "PRIMARY", cb = @() eventbus_send("exitGame", {}) }
  ]
})

let bottomCenterBlock = {
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  children = [
    mkUnitPkgDownloadInfo(curUnit, false,
      { pos = [0, - unitPlateTiny[1] - translucentButtonsHeight * 0.8 - translucentButtonsVGap] })
  ]
}

return {
  key = {}
  size = saSize
  behavior = HangarCameraControl
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  onAttach = @() isMainMenuAttached(true)
  onDetach = @() isMainMenuAttached(false)
  children = [
    lqTexturesWarningHangar
    gamercardPlace
    leftBottomButtons
    toBattleButtonPlace
    bottomCenterBlock
  ]
  animations = wndSwitchAnim
  hotkeys = [
    [btnBEscUp, {action=exitMsgBox}]
  ]
}
