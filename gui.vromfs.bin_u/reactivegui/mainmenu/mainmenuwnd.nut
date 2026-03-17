from "%globalsDarg/darg_library.nut" import *
from "app" import exitGame
let { HangarCameraControl } = require("wt.behaviors")
let { prevIfEqual } = require("%sqstd/underscore.nut")
let { isReadyToFullLoad } = require("%appGlobals/loginState.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { unitSizes } = require("%appGlobals/updater/addonsState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { mkGamercard } = require("%rGui/mainMenu/gamercard.nut")
let offerPromo = require("%rGui/shop/offerPromo.nut")
let mkEventShopBtn = require("%rGui/shop/eventShopBtn.nut")
let { translucentButtonsVGap, translucentButton } = require("%rGui/components/translucentButton.nut")
let { hangarUnit, setHangarUnit, hasBgUnitsByCamp } = require("%rGui/unit/hangarUnit.nut")
let { curUnit, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let { btnOpenUnitAttr } = require("%rGui/attributes/unitAttr/btnOpenUnitAttr.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { totalPlayers } = require("%appGlobals/gameModes/gameModes.nut")
let { curCampaign, campaignsList, campConfigs, isAnyCampaignSelected } = require("%appGlobals/pServer/campaign.nut")
let { curCampaignSlots, curSlots } = require("%appGlobals/pServer/slots.nut")
let { chooseCampaignWnd } = require("%rGui/mainMenu/chooseCampaignWnd.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { hoverColor, textColor } = require("%rGui/style/stdColors.nut")
let downloadInfoBlock = require("%rGui/updater/downloadInfoBlock.nut")
let { registerAutoDownloadUnits } = require("%rGui/updater/updaterState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { newbieOfflineMissions } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let { allow_players_online_info, allow_subscriptions } = require("%appGlobals/permissions.nut")
let { lqTexturesWarningHangar } = require("%rGui/hudHints/lqTexturesWarning.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset, simpleHorGrad } = require("%rGui/style/gradients.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { canReceivePremDailyBonus, hasPremiumSubs } = require("%rGui/state/profilePremium.nut")
let squadPanel = require("%rGui/squad/squadPanel.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { btnOpenQuests } = require("%rGui/quests/btnOpenQuests.nut")
let btnsOpenSpecialEvents = require("%rGui/event/btnsOpenSpecialEvents.nut")
let { isFitSeasonRewardsRequirements, isEventActive } = require("%rGui/event/eventState.nut")
let { isBpSeasonActive } = require("%rGui/battlePass/battlePassState.nut")
let { isOPSeasonActive } = require("%rGui/battlePass/operationPassState.nut")
let { isEpSeasonActive } = require("%rGui/battlePass/eventPassState.nut")
let bpBanner = require("%rGui/battlePass/bpBanner.nut")
let premDailyBonusWnd = require("%rGui/shop/premDailyBonusWnd.nut")
let btnOpenUnitsTree = require("%rGui/unitsTree/btnOpenUnitsTree.nut")
let { unitsResearchStatus, visibleNodes, selectedCountry, getResearchableCountries
} = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { mkDropMenuBtn } = require("%rGui/components/mkDropDownMenu.nut")
let { getTopMenuButtons, topMenuButtonsGenId } = require("%rGui/mainMenu/topMenuButtonsList.nut")
let { toBattleButtonForRandomBattles, randomBattleButtonDownloading } = require("%rGui/mainMenu/toBattleButton.nut")
let { framedImageBtn } = require("%rGui/components/imageButton.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { boostersListActive, boostersHeight } = require("%rGui/boosters/boostersListActive.nut")
let { unseenSkins } = require("%rGui/unitCustom/unitSkins/unseenSkins.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { DBGLEVEL } = require("dagor.system")
let { slotBarMainMenu, slotBarMainMenuSize } = require("%rGui/slotBar/slotBar.nut")
let { unseenCampaigns } = require("%rGui/mainMenu/unseenCampaigns.nut")
let { openSlotPresetWnd } = require("%rGui/slotBar/slotPresetsState.nut")
let { getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let battleItemsBtn = require("battleItemsBtn.nut")
let { blockedCountries } = require("%rGui/unit/unitAccess.nut")
let { openNPWnd, isNPSeasonActive } = require("%rGui/battlePass/newPlayerBpState.nut")

let unitNameStateFlags = Watched(0)

let battleInfoBlockMinHeight = hdpx(120)
let centerBlockGap = hdpx(20)
let centerBlockWidth = saSize[0] - 2 * statsWidth
let centerBlockTopMargin = gamercardHeight + translucentButtonsVGap
let centerBlockBottomMargin = defButtonHeight + battleInfoBlockMinHeight
let unitNameBlockHeight = hdpx(60)
let translucentButtonsWidth = hdpx(115)
let unitNameBgColor = 0x90000000

let mainMenuUnit = Computed(function() {
  if (curUnit.get() != null)
    return curUnit.get()
  if (!isAnyCampaignSelected.get())
    return null
  let allCountries = getResearchableCountries(visibleNodes.get(), unitsResearchStatus.get(), blockedCountries.get())
  let curCountry = allCountries.contains(selectedCountry.get()) ? selectedCountry.get() : allCountries?[0]
  return campUnitsCfg.get()?[unitsResearchStatus.get().findindex(@(r) r.canResearch && visibleNodes.get()?[r.name].country == curCountry)]
    ?? campUnitsCfg.get().reduce(@(res, unit) res == null || res.rank > unit.rank ? unit : res)
})

let mainMenuUnitNameToShow = keepref(Computed(@() isMainMenuAttached.get() ? mainMenuUnit.get()?.name : null))

mainMenuUnitNameToShow.subscribe(@(unitId) unitId == null ? null : setHangarUnit(unitId))

registerAutoDownloadUnits(Computed(function(prev) {
  if (!isReadyToFullLoad.get() || mainMenuUnit.get() == null)
    return prevIfEqual(prev, {})

  let { name, platoonUnits = [] } = mainMenuUnit.get()
  let res = {}
  res[getTagsUnitName(name)] <- true
  foreach (p in platoonUnits)
    res[getTagsUnitName(p.name)] <- true

  if (hasBgUnitsByCamp?[curCampaign.get()] && platoonUnits.len() == 0)
    foreach (s in curSlots.get())
      if (s.name != "" && s.name != name)
        res[getTagsUnitName(s.name)] <- true

  let sizes = unitSizes.get()
  return prevIfEqual(prev, res.filter(@(_, u) (sizes?[u] ?? -1) != 0))
}))

let mkUnitName = @(unit, sf) {
  size = FLEX_H
  rendObj = ROBJ_TEXT
  text = getPlatoonOrUnitName(unit, loc)
  color = sf & S_HOVER ? hoverColor : 0xFFFFFFFF
  behavior = Behaviors.Marquee
  delay = defMarqueeDelay
  speed = hdpx(50)
}.__update(fontSmallShaded)

function unitNameBlock() {
  let res = { watch = hangarUnit }
  if (hangarUnit.get() != null)
    res.__update({
      watch = [hangarUnit, unseenSkins, unitNameStateFlags]
      size = [flex(), unitNameBlockHeight]
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      behavior = Behaviors.Button
      padding = [hdpx(20), hdpx(10)]
      onElemState = @(sf) unitNameStateFlags.set(sf)
      onClick = @() unitDetailsWnd({ name = hangarUnit.get().name })
      gap = hdpx(20)
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
  children = campaignsList.get().len() <= 1 || curCampaign.get() == null  ? null
    : [
        framedImageBtn(getCampaignPresentation(curCampaign.get()).icon, chooseCampaignWnd,
          {
            padding = const [hdpx(10), hdpx(20), hdpx(10), hdpx(20) ]
            size = SIZE_TO_CONTENT
            sound = { click = "click" }
            imageSize = [hdpx(60) , hdpx(60)]
            flow = FLOW_HORIZONTAL
            gap = hdpx(20)
            minWidth = translucentButtonsVGap*2 + translucentButtonsWidth*3
          },
          {
            size = FLEX_V
            rendObj = ROBJ_TEXT
            valign = ALIGN_CENTER
            color = 0xFFFFFFFF
            text = loc("changeCampaignShort")
          }.__update(fontTinyAccentedShadedBold))
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
  watch = [allow_subscriptions, hasPremiumSubs, canReceivePremDailyBonus]
  children = !allow_subscriptions.get() || !hasPremiumSubs.get() || !canReceivePremDailyBonus.get() ? null
    : translucentButton("ui/gameuiskin#prem_daily_bonus.svg", "", premDailyBonusWnd,
        @(_) @() {
          watch = canReceivePremDailyBonus
          hplace = ALIGN_RIGHT
          pos = [hdpx(4), hdpx(-4)]
          children = canReceivePremDailyBonus.get() ? priorityUnseenMark : null
        }, { iconSize = evenPx(84) })
}

let btnNewPlayerBpWnd = @() {
  watch = isNPSeasonActive
  children = isNPSeasonActive.get()
    ? translucentButton("ui/gameuiskin#icon_newbie_pass.svg", "", openNPWnd)
    : null
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

let isPassActive = Computed(@() isBpSeasonActive.get() || isOPSeasonActive.get() || isEpSeasonActive.get())
let hasBanner = Computed(@() isFitSeasonRewardsRequirements.get() && (isPassActive.get() || isEventActive.get()))

let leftTopButtons = {
  vplace = ALIGN_TOP
  flow = FLOW_VERTICAL
  children = [
    btnVerRow([
      mkGamercard(dropMenuBtn)
      {
        size = FLEX_H
        children = [
          campaignsBtn
          {
            size = 0
            pos = [0, hdpx(-45)]
            hplace = ALIGN_RIGHT
            halign = ALIGN_RIGHT
            flow = FLOW_HORIZONTAL
            gap = hdpx(30)
            children = [
              {
                pos = [0, hdpx(-15)]
                children = mkEventShopBtn()
              }
              offerPromo
            ]
          }
        ]
      }
      @() {
        watch = [newbieOfflineMissions, hasBanner, isPassActive, isEventActive]
        children = newbieOfflineMissions.get() != null && DBGLEVEL == 0 ? null
          : !hasBanner.get() ? btnHorRow([btnOpenQuests("no_banner"), btnsOpenSpecialEvents, btnNewPlayerBpWnd])
          : btnVerRow([
              bpBanner(isPassActive.get(), isEventActive.get())
              btnHorRow([
                btnOpenQuests("banner")
                btnsOpenSpecialEvents
                btnNewPlayerBpWnd
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
              watch = [curCampaignSlots, curCampaign]
              children = !curCampaignSlots.get()
                ? null
                : translucentButton(getCampaignPresentation(curCampaign.get()).slotsPresetBtnIcon,
                     "", openSlotPresetWnd)
            }
            btnPremDailyBonus
          ])
        ])
      ])
    ])
  ]
}

let toBattleButtonPlace = {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  children = [
    {
      size = FLEX_H
      halign = ALIGN_RIGHT
      flow = FLOW_VERTICAL
      children = [
        squadPanel
        {
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          halign = ALIGN_RIGHT
          children = [
            battleItemsBtn
            { size = flex() }
            @() {
              watch = campConfigs
              size = [SIZE_TO_CONTENT, boostersHeight]
              valign = ALIGN_CENTER
              children = (campConfigs.get()?.allBoosters.len() ?? 0) > 0 ? boostersListActive : null
            }
          ]
        }
      ]
    }
    {
      padding = [hdpx(10), 0, hdpx(10),0]
      rendObj = ROBJ_IMAGE
      size = [flex(), SIZE_TO_CONTENT]
      image = simpleHorGrad
      color = 0xAA000000
      flipX = true
      flow = FLOW_VERTICAL
      gap = hdpx(20)
      children = [
        onlineInfo
        unitNameBlock
      ]
    }
    {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      children = toBattleButtonForRandomBattles
    }
  ]
}

let exitMsgBox = @() openMsgBox({
  text = loc("mainmenu/questionQuitGame")
  buttons = [
    { id = "cancel", isCancel = true }
    { text = loc("mainmenu/btnQuit"), styleId = "PRIMARY", cb = exitGame }
  ]
})

let textArea = @(text) {
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, hdpx(50)]
  color = 0x90000000
  padding = const [hdpx(5), hdpx(20)]
  gap = hdpx(20)
  children = @() {
    size = [saSize[0] - 2 * statsWidth, SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    color = textColor
    halign = ALIGN_CENTER
    text
  }.__update(fontTinyShaded)
}

let centerTopBlock = @() {
  watch = randomBattleButtonDownloading
  rendObj = ROBJ_BOX
  size = [centerBlockWidth, SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  gap = centerBlockGap
  flow = FLOW_VERTICAL
  children = [
    randomBattleButtonDownloading.get().len() > 0 ? textArea(loc("msg/downloadPackToUseUnitOnline")) : null,
    lqTexturesWarningHangar
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
  onAttach = @() isMainMenuAttached.set(true)
  onDetach = @() isMainMenuAttached.set(false)
  children = [
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
