from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { HangarCameraControl } = require("wt.behaviors")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { mkGamercard, gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let offerPromo = require("%rGui/shop/offerPromo.nut")
let { translucentButtonsVGap, translucentButton } = require("%rGui/components/translucentButton.nut")
let { gamercardGap, CS_GAMERCARD } = require("%rGui/components/currencyStyles.nut")
let { hangarUnit, setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { itemsOrder } = require("%appGlobals/itemsState.nut")
let { curUnit, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { mkPlatoonOrUnitTitle, statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let { btnOpenUnitAttr } = require("%rGui/attributes/unitAttr/btnOpenUnitAttr.nut")
let { isMainMenuAttached } = require("mainMenuState.nut")
let { totalPlayers } = require("%appGlobals/gameModes/gameModes.nut")
let { curCampaign, campaignsList, campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { curCampaignSlots, curSlots } = require("%appGlobals/pServer/slots.nut")
let { chooseCampaignWnd } = require("chooseCampaignWnd.nut")
let mkUnitPkgForBattleDownloadInfo = require("%rGui/unit/mkUnitPkgForBattleDownloadInfo.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")
let downloadInfoBlock = require("%rGui/updater/downloadInfoBlock.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { newbieOfflineMissions } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let { allow_players_online_info, allow_subscriptions } = require("%appGlobals/permissions.nut")
let { lqTexturesWarningHangar } = require("%rGui/hudHints/lqTexturesWarning.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkMRankRange } = require("%rGui/state/matchingRank.nut")
let { canReceivePremDailyBonus } = require("%rGui/state/profilePremium.nut")
let squadPanel = require("%rGui/squad/squadPanel.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { btnOpenQuests } = require("%rGui/quests/btnOpenQuests.nut")
let { specialEventGamercardItems, openEventWnd } = require("%rGui/event/eventState.nut")
let btnsOpenSpecialEvents = require("%rGui/event/btnsOpenSpecialEvents.nut")
let bpBanner = require("%rGui/battlePass/bpBanner.nut")
let { openShopWnd } = require("%rGui/shop/shopState.nut")
let { SC_CONSUMABLES } = require("%rGui/shop/shopCommon.nut")
let premDailyBonusWnd = require("%rGui/shop/premDailyBonusWnd.nut")
let btnOpenUnitsTree = require("%rGui/unitsTree/btnOpenUnitsTree.nut")
let { mkDropMenuBtn } = require("%rGui/components/mkDropDownMenu.nut")
let { getTopMenuButtons, topMenuButtonsGenId } = require("%rGui/mainMenu/topMenuButtonsList.nut")
let { mkItemsBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { toBattleButtonForRandomBattles } = require("%rGui/mainMenu/toBattleButton.nut")
let { framedImageBtn } = require("%rGui/components/imageButton.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { boostersListActive, boostersHeight } = require("%rGui/boosters/boostersListActive.nut")
let { unseenSkins } = require("%rGui/unitCustom/unitSkins/unseenSkins.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { DBGLEVEL } = require("dagor.system")
let { slotBarMainMenu, slotBarMainMenuSize } = require("%rGui/slotBar/slotBar.nut")
let { unseenCampaigns } = require("unseenCampaigns.nut")
let { isItemAllowedForUnit } = require("%rGui/unit/unitItemAccess.nut")
let { openSlotPresetWnd } = require("%rGui/slotBar/slotPresetsState.nut")

let unitNameStateFlags = Watched(0)

let battleInfoBlockMinHeight = hdpx(120)
let centerBlockGap = hdpx(20)
let centerBlockWidth = saSize[0] - 2 * statsWidth
let centerBlockTopMargin = gamercardHeight + translucentButtonsVGap
let centerBlockBottomMargin = defButtonHeight + battleInfoBlockMinHeight
let unitNameBlockHeight = hdpx(60)
let unitNameBgColor = 0x90000000

let mainMenuUnitToShow = keepref(Computed(function() {
  if (!isMainMenuAttached.value)
    return null
  return curUnit.value?.name
    ?? campUnitsCfg.get().reduce(@(res, unit) res == null || res.rank > unit.rank ? unit : res)?.name
}))

mainMenuUnitToShow.subscribe(@(unitId) unitId == null ? null : setHangarUnit(unitId))

let mkUnitName = @(unit, sf) {
  vplace = ALIGN_CENTER
  margin = const [0, hdpx(20)]
  flow = FLOW_HORIZONTAL
  gap = hdpx(24)
  children = [
    mkPlatoonOrUnitTitle(
      unit, {}, { maxWidth = centerBlockWidth }.__update(sf & S_HOVER ? { color = hoverColor } : {}))
    mkGradRank(unit.mRank)
  ]
}

function unitNameBlock() {
  let res = { watch = hangarUnit }
  if (hangarUnit.get() != null)
    res.__update({
      watch = [hangarUnit, unseenSkins, unitNameStateFlags]
      size = [SIZE_TO_CONTENT, unitNameBlockHeight]
      flow = FLOW_HORIZONTAL
      behavior = Behaviors.Button
      onElemState = @(sf) unitNameStateFlags.set(sf)
      onClick = @() unitDetailsWnd({ name = hangarUnit.get().name })
      children = [
        {
          size = unitNameBlockHeight
          rendObj = ROBJ_BOX
          bgColor = unitNameBgColor
          borderWidth = hdpx(2)
          borderColor = 0xFFA0A0A0
          children = [
            {
            rendObj = ROBJ_TEXT
            vplace = ALIGN_CENTER
            hplace = ALIGN_CENTER
            text = "i"
          }.__update(fontSmallShaded)
          hangarUnit.get().name not in unseenSkins.get() ? null
            : priorityUnseenMark.__merge({ hplace = ALIGN_RIGHT, pos = [hdpx(10), hdpx(-10)] })
        ]
        }
        mkUnitName(hangarUnit.get(), unitNameStateFlags.get())
      ]
      transform = { scale = unitNameStateFlags.get() & S_ACTIVE ? [0.98, 0.98] : [1, 1] }
    })
  return res
}

let campaignsBtn = @() {
  watch = [campaignsList, curCampaign, unseenCampaigns]
  children = campaignsList.value.len() <= 1 || curCampaign.value == null  ? null
    : [
        framedImageBtn(getCampaignPresentation(curCampaign.value).icon, chooseCampaignWnd,
          {
            padding = const [hdpx(0), hdpx(20), hdpx(0), hdpx(20) ]
            size = SIZE_TO_CONTENT
            sound = { click = "click" }
            imageSize = [hdpx(70) , hdpx(70)]
            flow = FLOW_HORIZONTAL
            gap = hdpx(20)
          },
          {
            size = FLEX_V
            rendObj = ROBJ_TEXT
            valign = ALIGN_CENTER
            color = 0xFFFFFFFF
            text = loc("changeCampaignShort")
            fontFx = FFT_GLOW
            fontFxFactor = 64
            fontFxColor = Color(0, 0, 0)
          }.__update(fontTinyAccented))
        unseenCampaigns.get().len() == 0 ? null
          : priorityUnseenMark.__merge({ hplace = ALIGN_RIGHT, pos = [hdpx(10), hdpx(-10)] })
      ]
}

let mkOnlineInfoText = @(total) {
  rendObj = ROBJ_TEXT
  text = loc("mainmenu/online_info/player_online", {
    playersOnline = total
  })
  color = 0xD0D0D0D0
}.__update(fontVeryTinyShaded)

let onlineInfo = @() {
  watch = [totalPlayers, allow_players_online_info]
  children = !allow_players_online_info.get() || totalPlayers.get() < 0 ? null
    : mkOnlineInfoText(totalPlayers.get())
}

let dropMenuBtn = mkDropMenuBtn(getTopMenuButtons, topMenuButtonsGenId)

let btnPremDailyBonus = @() {
  watch = allow_subscriptions
  children = !allow_subscriptions.get() ? null
    : translucentButton("ui/gameuiskin#prem_daily_bonus.svg", "", premDailyBonusWnd,
        @(_) @() {
          watch = canReceivePremDailyBonus
          hplace = ALIGN_RIGHT
          pos = [hdpx(4), hdpx(-4)]
          children = canReceivePremDailyBonus.get() ? priorityUnseenMark : null
        }, { iconSize = evenPx(84) })
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

let leftBottomButtons = {
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  children = @() curSlots.get().len() == 0 ? { watch = curSlots }
    : {
        watch = curSlots
        size = slotBarMainMenuSize
        children = slotBarMainMenu
      }
}

let leftTopButtons = {
  vplace = ALIGN_TOP
  flow = FLOW_VERTICAL
  children = [
    btnVerRow([
      mkGamercard(dropMenuBtn)
      {
        size = FLEX_H
        children = [
          {
            hplace = ALIGN_LEFT
            gap = translucentButtonsVGap
            flow = FLOW_HORIZONTAL
            children = [
              campaignsBtn
            ]
          }
          {
            size = 0
            hplace = ALIGN_RIGHT
            halign = ALIGN_RIGHT
            children = offerPromo
          }
        ]
      }
      @() {
        watch = newbieOfflineMissions
        children = newbieOfflineMissions.get() != null && DBGLEVEL == 0 ? null : btnVerRow([
          bpBanner
          btnHorRow([
            btnOpenQuests
            btnPremDailyBonus
            btnsOpenSpecialEvents
          ])
        ])
      }
      btnHorRow([
        btnVerRow([
          @() {
            watch = curSlots
            children = curSlots.get().len() == 0 ? btnOpenUnitAttr : null
          }
          btnHorRow([
            btnOpenUnitsTree
            @() {
              watch = curCampaignSlots
              children = !curCampaignSlots.get()
                ? null
                : translucentButton("ui/gameuiskin#icon_slot_preset.svg", "", openSlotPresetWnd)
            }
          ])
        ])
      ])
    ])
  ]
}

let gamercardBattleItemsBalanceBtns = @(){
  watch = [itemsOrder, specialEventGamercardItems, hangarUnit]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = specialEventGamercardItems.get().map(@(v) mkItemsBalance(v.itemId, @() openEventWnd(v.eventName), CS_GAMERCARD))
    .extend(itemsOrder.get()
      .filter(@(v) hangarUnit.get()?.name == null || isItemAllowedForUnit(v, hangarUnit.get().name))
      .map(@(id) mkItemsBalance(id, @() openShopWnd(SC_CONSUMABLES), CS_GAMERCARD)))
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
          watch = campConfigs
          size = [SIZE_TO_CONTENT, boostersHeight]
          valign = ALIGN_CENTER
          children = (campConfigs.get()?.allBoosters.len() ?? 0) > 0 ? boostersListActive : null
        }
      ]
    }
    {
      minHeight = battleInfoBlockMinHeight
      rendObj = ROBJ_9RECT
      image = gradTranspDoubleSideX
      padding = [ 0, 0, 0, saBorders[0] * 0.5]
      texOffs = [0 , gradDoubleTexOffset]
      screenOffs = [0, hdpx(70)]
      color = 0x50000000
      flow = FLOW_VERTICAL
      halign = ALIGN_RIGHT
      children = [
        onlineInfo
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

let centerTopBlock = {
  rendObj = ROBJ_BOX
  size = [centerBlockWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = centerBlockGap
  children = [
    mkUnitPkgForBattleDownloadInfo()
  ]
}

let centerBottomBlock = {
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  children = downloadInfoBlock
}

let centerBlock = {
  size = [SIZE_TO_CONTENT, saSize[1] - centerBlockTopMargin - centerBlockBottomMargin]
  pos = [0, centerBlockTopMargin]
  hplace = ALIGN_CENTER
  children = [
    centerTopBlock
    centerBottomBlock
  ]
}

return {
  key = {}
  size = saSize
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  onAttach = @() isMainMenuAttached(true)
  onDetach = @() isMainMenuAttached(false)
  children = [
    lqTexturesWarningHangar
    leftTopButtons
    leftBottomButtons
    toBattleButtonPlace
    centerBlock
  ]
  animations = wndSwitchAnim
  hotkeys = [
    [btnBEscUp, {action=exitMsgBox}]
  ]
}
