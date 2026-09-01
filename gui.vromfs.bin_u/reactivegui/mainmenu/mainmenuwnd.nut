from "%globalsDarg/darg_library.nut" import *
from "app" import exitGame
from "dagor.system" import DBGLEVEL
from "math" import round
from "wt.behaviors" import HangarCameraControl
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/underscore.nut" import prevIfEqual
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/loginState.nut" import isReadyToFullLoad
from "%appGlobals/pServer/campaign.nut" import curCampaign, campaignsList, campConfigs, isAnyCampaignSelected
from "%appGlobals/pServer/profile.nut" import curUnit, campUnitsCfg
from "%appGlobals/pServer/slots.nut" import curSlots
from "%appGlobals/permissions.nut" import allow_subscriptions
from "%appGlobals/updater/addonsState.nut" import unitSizes
from "%rGui/globals/fontUtils.nut" import getFontToFitWidth
from "%rGui/battlePass/battlePassState.nut" import isBpSeasonActive
import "%rGui/battlePass/bpBanner.nut" as bpBanner
from "%rGui/battlePass/eventPassState.nut" import isEpSeasonActive
from "%rGui/battlePass/newPlayerBpState.nut" import openNPWnd, isNPSeasonActive, hasUnseenNpPass,
  hasNpBpRewardsToReceive
from "%rGui/battlePass/operationPassState.nut" import isOPSeasonActive
from "%rGui/boosters/boostersListActive.nut" import boostersListActive, boostersHeight
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/imageButton.nut" import framedGradientImageBtn
from "%rGui/components/mkDropDownMenu.nut" import mkDropMenuBtn
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/translucentButton.nut" import translucentButtonsVGap, translucentButtonsWidth,
  translucentButton, translucentBtnStyles
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
import "%rGui/event/btnsOpenSpecialEvents.nut" as btnsOpenSpecialEvents
from "%rGui/event/eventState.nut" import isFitSeasonRewardsRequirements, isEventActive
import "%rGui/event/shouldShowEventMechanics.nut" as shouldShowEventMechanics
from "%rGui/gameModes/newbieOfflineMissions.nut" import isNextBattleNewbieOffline
from "%rGui/hudHints/lqTexturesWarning.nut" import lqTexturesWarningHangar
from "%rGui/mainMenu/chooseCampaignWnd.nut" import chooseCampaignWnd
from "%rGui/mainMenu/gamercard.nut" import mkGamercard
from "%rGui/mainMenu/mainMenuState.nut" import isMainMenuAttached
from "%rGui/mainMenu/toBattleButton.nut" import toBattleButtonForRandomBattles, randomBattleButtonDownloading
from "%rGui/mainMenu/topMenuButtonsList.nut" import getTopMenuButtons, topMenuButtonsGenId
from "%rGui/mainMenu/unseenCampaigns.nut" import unseenCampaigns
from "%rGui/quests/questsState.nut" import questsCfg, questsBySection
import "%rGui/seasonScene/mkSeasonSceneUnseenMark.nut" as mkSeasonSceneUnseenMark
from "%rGui/seasonScene/seasonSceneState.nut" import openSeasonScene, isQuestsTabVisible
import "%rGui/shop/eventShopBtn.nut" as mkEventShopBtn
import "%rGui/shop/offerPromo.nut" as offerPromo
from "%rGui/shop/calendarState.nut" import isActiveSubCalendar, canReceiveSubCalendarReward
from "%rGui/shop/shopCommon.nut" import defaultShopCategory
from "%rGui/shop/shopState.nut" import openShopWnd, hasUnseenGoodsByShop
from "%rGui/slotBar/slotBar.nut" import slotBarMainMenu, slotBarMainMenuSize, fakeSlotMainMenu
from "%rGui/slotBar/slotBarConsts.nut" import unitPlateSize, slotsGap
from "%rGui/slotBar/slotPresetsState.nut" import openSlotPresetWnd
import "%rGui/shop/subscribitionCalendarWnd.nut" as subscribitionCalendarWnd
import "%rGui/squad/squadPanel.nut" as squadPanel
from "%rGui/state/profilePremium.nut" import hasPremiumSubs
from "%rGui/style/gamercardStyle.nut" import gamercardHeight
from "%rGui/style/gradients.nut" import gradTranspDoubleSideX, gradDoubleTexOffset, mkColoredGradientY
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import textColor
from "%rGui/unit/components/unitInfoPanel.nut" import statsWidth
from "%rGui/unit/hangarUnit.nut" import setHangarUnit, hasBgUnitsByCamp
from "%rGui/unit/unitAccess.nut" import blockedCountries
import "%rGui/unitsTree/btnOpenUnitsTree.nut" as btnOpenUnitsTree
from "%rGui/unitsTree/unitsTreeNodesState.nut" import unitsResearchStatus, visibleNodes, selectedCountry,
  getResearchableCountries
from "%rGui/unlocks/userstat.nut" import addUnlocksUpdater, removeUnlocksUpdater
import "%rGui/updater/downloadInfoBlock.nut" as downloadInfoBlock
from "%rGui/updater/updaterState.nut" import registerAutoDownloadUnits, DLP_MEDIUM
import "battleItemsBtn.nut" as battleItemsBtn


const battleInfoBlockMinHeight = hdpx(120)
const centerBlockGap = hdpx(20)
let centerBlockWidth = saSize[0] - 2 * statsWidth
let centerBlockTopMargin = gamercardHeight + translucentButtonsVGap
let centerBlockBottomMargin = defButtonHeight + battleInfoBlockMinHeight
let bgPresetsBtn = mkColoredGradientY(0xFF383B3E, 0xFF191616, 2)
const bgPresetsBtnIconSize = hdpxi(50)
let { PRIMARY } = translucentBtnStyles
let campBtnSize = [translucentButtonsVGap * 2 + translucentButtonsWidth * 3, PRIMARY.size[1]]
let campBtnImageSize = [hdpx(60), hdpx(60)]
const campBtnGap = hdpx(10)

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

let needShopUnseenMark = Computed(@() hasUnseenGoodsByShop.get()?.common.findvalue(@(c) c) ?? false)
let mainMenuUnitNameToShow = keepref(Computed(@() isMainMenuAttached.get() ? mainMenuUnit.get()?.name : null))

mainMenuUnitNameToShow.subscribe(@(unitId) unitId == null ? null : setHangarUnit(unitId))

registerAutoDownloadUnits(
  Computed(function(prev) {
    if (!isReadyToFullLoad.get() || mainMenuUnit.get() == null)
      return prevIfEqual(prev, {})

    let { name } = mainMenuUnit.get()
    let res = { [name] = true }

    if (hasBgUnitsByCamp?[curCampaign.get()])
      foreach (s in curSlots.get())
        if (s.name != "" && s.name != name)
          res[s.name] <- true

    let sizes = unitSizes.get()
    return prevIfEqual(prev, res.filter(@(_, u) (sizes?[u] ?? -1) != 0))
  }),
  DLP_MEDIUM)

function campaignsBtn() {
  let maxTxtWidth = campBtnSize[0] - campBtnImageSize[0] - campBtnGap
  let btnTxt = {
    size = FLEX
    rendObj = ROBJ_TEXT
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    color = 0xFFFFFFFF
    maxWidth = maxTxtWidth
    text = loc("changeCampaignShort")
  }.__update(fontBoldTinyAccentedShaded)

  return {
    watch = [campaignsList, curCampaign, unseenCampaigns]
    children = campaignsList.get().len() <= 1 || curCampaign.get() == null  ? null
      : [
          framedGradientImageBtn("gradient_button.svg", getCampaignPresentation(curCampaign.get()).icon, chooseCampaignWnd,
            {
              padding = hdpx(10)
              size = campBtnSize
              color = 0xFF000000
              sound = { click = "click" }
              imageSize = campBtnImageSize
              flow = FLOW_HORIZONTAL
              gap = campBtnGap
            },
            btnTxt.__update(getFontToFitWidth(btnTxt, maxTxtWidth, [fontBoldVeryTinyAccentedShaded, fontBoldTinyAccentedShaded])))
          unseenCampaigns.get().len() == 0 ? null
            : priorityUnseenMark.__merge({ hplace = ALIGN_RIGHT, pos = const [hdpx(10), hdpx(-10)] })
        ].filter(@(v) v != null)
  }
}

let dropMenuBtn = mkDropMenuBtn(getTopMenuButtons, topMenuButtonsGenId)

let subCalendarImgSize = evenPx(84)
let subCalendarImg = {
  rendObj = ROBJ_IMAGE
  size = subCalendarImgSize
  color = 0xFFFFC400
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  image = Picture($"ui/gameuiskin#shop_eagles.svg:{subCalendarImgSize}:P")
  keepAspect = true
}

let btnSubCalendar = @() {
  watch = [allow_subscriptions, hasPremiumSubs, isActiveSubCalendar]
  children = !allow_subscriptions.get() || !hasPremiumSubs.get() || !isActiveSubCalendar.get() ? null
    : translucentButton(subCalendarImg, subscribitionCalendarWnd, null,
        @(_) @() {
          watch = canReceiveSubCalendarReward
          hplace = ALIGN_RIGHT
          children = canReceiveSubCalendarReward.get() ? priorityUnseenMark : null
        }, { size = [hdpx(84), PRIMARY.size[1]]})
}

let btnNewPlayerBpWnd = @() {
  watch = isNPSeasonActive
  children = isNPSeasonActive.get()
    ? translucentButton("ui/gameuiskin#icon_newbie_pass.svg", openNPWnd,
        null,
        @(_) @() {
          watch = [hasNpBpRewardsToReceive, hasUnseenNpPass]
          key = isNPSeasonActive
          onAttach = @() addUnlocksUpdater("npPassUnseen")
          onDetach = @() removeUnlocksUpdater("npPassUnseen")
          hplace = ALIGN_RIGHT
          vplace = ALIGN_TOP
          children = !hasNpBpRewardsToReceive.get() && !hasUnseenNpPass.get() ? null
            : priorityUnseenMark
        })
    : null
}

let btnShop = @() translucentButton("ui/gameuiskin#icon_shop.svg",
  @() openShopWnd(defaultShopCategory),
  utf8ToUpper(loc("topmenu/store")),
  @(_) @() {
    watch = needShopUnseenMark
    hplace = ALIGN_RIGHT
    vplace = ALIGN_TOP
    pos = const [-hdpx(4), hdpx(4)]
    children = needShopUnseenMark.get() ? priorityUnseenMark : null
  },
  { iconMul = 0.8, key = "shop_btn" }) 

let isAchievementsAndPromoBtnVisible = Computed(@() isQuestsTabVisible("", questsCfg.get(), questsBySection.get()))

let btnOnlyAchievementsAndPromo = @() {
  watch = isAchievementsAndPromoBtnVisible
  children = !isAchievementsAndPromoBtnVisible.get() ? null
    : translucentButton("ui/gameuiskin#prizes_icon.svg",
        @() openSeasonScene(""),
        null,
        @(_) mkSeasonSceneUnseenMark("", { hplace = ALIGN_RIGHT, vplace = ALIGN_TOP }))}

function btnChangeSlotsPreset() {
  let stateFlags = Watched(0)

  return {
    size = [round(unitPlateSize[0] * 0.25).tointeger(), unitPlateSize[1]]
    margin = [0, 0, 0, (unitPlateSize[0] + slotsGap) * curSlots.get().len()]
    behavior = Behaviors.Button
    rendObj = ROBJ_IMAGE
    image = bgPresetsBtn
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_LEFT
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    sound = { click = "click" }
    onElemState = @(sf) stateFlags.set(sf)
    onClick = openSlotPresetWnd
    children = [
      {
        size = bgPresetsBtnIconSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#decor_change_icon.svg:{bgPresetsBtnIconSize}:{bgPresetsBtnIconSize}:P")
        keepAspect = true
        transform = { rotate = 90 }
      }
      @() {
        watch = stateFlags
        size = FLEX
        rendObj = ROBJ_BOX
        borderWidth = hdpx(3)
        borderColor = stateFlags.get() & S_HOVER ? 0xFFFFFFFF : 0xFFA0A0A0
      }
    ]
  }
}

let btnHorRow = @(children) {
  flow = FLOW_HORIZONTAL
  gap = translucentButtonsVGap
  children
}

let btnVerRow = @(children, ovr = {}) {
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children
}.__update(ovr)

let leftBottomButtons = @() {
  watch = [curSlots, curCampaign]
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = hdpx(-10)
  children = curSlots.get().len() > 0
    ? [
        btnOpenUnitsTree
        {
          children = [
            {
              size = slotBarMainMenuSize
              children = slotBarMainMenu
            }
            btnChangeSlotsPreset
          ]
        }
      ]
    : [
        btnOpenUnitsTree
        fakeSlotMainMenu()
      ]
}

let eventsTitleBlock = {
  rendObj = ROBJ_TEXT
  text = utf8ToUpper(loc("shop/category/events"))
  color = 0xFFFFFFFF
}.__update(fontVeryTinyAccented)

let isPassActive = Computed(@() isBpSeasonActive.get() || isOPSeasonActive.get() || isEpSeasonActive.get())
let hasBanner = Computed(@() shouldShowEventMechanics.get()
  && isFitSeasonRewardsRequirements.get()
  && (isPassActive.get() || isEventActive.get()))

let leftTopButtons = {
  vplace = ALIGN_TOP
  children = btnVerRow([
    mkGamercard(dropMenuBtn)
    {
      size = FLEX_H
      margin = [centerBlockGap, 0, 0, 0]
      children = [
        btnHorRow([campaignsBtn, btnSubCalendar])
        {
          size = 0
          pos = [0, hdpx(-45)]
          hplace = ALIGN_RIGHT
          halign = ALIGN_RIGHT
          flow = FLOW_HORIZONTAL
          gap = hdpx(30)
          children = [
            @() {
              watch = shouldShowEventMechanics
              pos = const [0, hdpx(-15)]
              children = shouldShowEventMechanics.get() ? mkEventShopBtn() : null
            }
            offerPromo
          ]
        }
      ]
    }
    @() {
      watch = [isNextBattleNewbieOffline, hasBanner, isPassActive, isEventActive]
      children = isNextBattleNewbieOffline.get() && DBGLEVEL == 0 ? null
        : btnVerRow([
            hasBanner.get() ? bpBanner(isPassActive.get(), isEventActive.get()) : btnOnlyAchievementsAndPromo
            btnVerRow([
              eventsTitleBlock
              btnHorRow([
                btnsOpenSpecialEvents
                btnNewPlayerBpWnd
              ])
            ], { gap = hdpx(-10) })
            btnHorRow([btnShop()])
          ].filter(@(v) v != null))
    }
  ])
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
      gap = hdpx(20)
      children = [
        squadPanel
        {
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          halign = ALIGN_RIGHT
          children = [
            battleItemsBtn
            { size = FLEX }
            @() {
              watch = campConfigs
              size = [SIZE_TO_CONTENT, boostersHeight]
              valign = ALIGN_CENTER
              children = (campConfigs.get()?.allBoosters.len() ?? 0) > 0 ? boostersListActive("hangar") : null
            }
          ]
        }
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
