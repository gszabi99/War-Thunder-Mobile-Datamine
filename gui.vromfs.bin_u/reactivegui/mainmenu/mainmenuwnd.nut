from "%globalsDarg/darg_library.nut" import *
from "app" import exitGame
let { round } =  require("math")
let { HangarCameraControl } = require("wt.behaviors")
let { prevIfEqual } = require("%sqstd/underscore.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { isReadyToFullLoad } = require("%appGlobals/loginState.nut")
let { unitSizes } = require("%appGlobals/updater/addonsState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { mkGamercard } = require("%rGui/mainMenu/gamercard.nut")
let offerPromo = require("%rGui/shop/offerPromo.nut")
let mkEventShopBtn = require("%rGui/shop/eventShopBtn.nut")
let { translucentButtonsVGap, translucentButtonsWidth, translucentButton, translucentBtnStyles
} = require("%rGui/components/translucentButton.nut")
let { setHangarUnit, hasBgUnitsByCamp } = require("%rGui/unit/hangarUnit.nut")
let { curUnit, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { curCampaign, campaignsList, campConfigs, isAnyCampaignSelected } = require("%appGlobals/pServer/campaign.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")
let { chooseCampaignWnd } = require("%rGui/mainMenu/chooseCampaignWnd.nut")
let { textColor } = require("%rGui/style/stdColors.nut")
let downloadInfoBlock = require("%rGui/updater/downloadInfoBlock.nut")
let { registerAutoDownloadUnits, DLP_MEDIUM } = require("%rGui/updater/updaterState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { isNextBattleNewbieOffline } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let { allow_subscriptions } = require("%appGlobals/permissions.nut")
let { lqTexturesWarningHangar } = require("%rGui/hudHints/lqTexturesWarning.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset, mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { canReceivePremDailyBonus, hasPremiumSubs } = require("%rGui/state/profilePremium.nut")
let squadPanel = require("%rGui/squad/squadPanel.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let btnsOpenSpecialEvents = require("%rGui/event/btnsOpenSpecialEvents.nut")
let { isFitSeasonRewardsRequirements, isEventActive } = require("%rGui/event/eventState.nut")
let shouldShowEventMechanics = require("%rGui/event/shouldShowEventMechanics.nut")
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
let { framedGradientImageBtn } = require("%rGui/components/imageButton.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { boostersListActive, boostersHeight } = require("%rGui/boosters/boostersListActive.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { DBGLEVEL } = require("dagor.system")
let { slotBarMainMenu, slotBarMainMenuSize, fakeSlotMainMenu } = require("%rGui/slotBar/slotBar.nut")
let { unseenCampaigns } = require("%rGui/mainMenu/unseenCampaigns.nut")
let { openSlotPresetWnd } = require("%rGui/slotBar/slotPresetsState.nut")
let battleItemsBtn = require("battleItemsBtn.nut")
let { blockedCountries } = require("%rGui/unit/unitAccess.nut")
let { openNPWnd, isNPSeasonActive, hasUnseenNpPass, hasNpBpRewardsToReceive } = require("%rGui/battlePass/newPlayerBpState.nut")
let { addUnlocksUpdater, removeUnlocksUpdater } = require("%rGui/unlocks/userstat.nut")
let { unitPlateSize, slotsGap } = require("%rGui/slotBar/slotBarConsts.nut")
let { defaultShopCategory } = require("%rGui/shop/shopCommon.nut")
let { openShopWnd, hasUnseenGoodsByShop } = require("%rGui/shop/shopState.nut")
let { openSeasonScene, isQuestsTabVisible } = require("%rGui/seasonScene/seasonSceneState.nut")
let { questsCfg, questsBySection } = require("%rGui/quests/questsState.nut")
let mkSeasonSceneUnseenMark = require("%rGui/seasonScene/mkSeasonSceneUnseenMark.nut")


let battleInfoBlockMinHeight = hdpx(120)
let centerBlockGap = hdpx(20)
let centerBlockWidth = saSize[0] - 2 * statsWidth
let centerBlockTopMargin = gamercardHeight + translucentButtonsVGap
let centerBlockBottomMargin = defButtonHeight + battleInfoBlockMinHeight
let bgPresetsBtn = mkColoredGradientY(0xFF383B3E, 0xFF191616, 2)
let bgPresetsBtnIconSize = hdpxi(50)
let { PRIMARY } = translucentBtnStyles
let campBtnSize = [translucentButtonsVGap * 2 + translucentButtonsWidth * 3, PRIMARY.size[1]]
let campBtnImageSize = [hdpx(60), hdpx(60)]
let campBtnGap = hdpx(10)

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

let campaignsBtn = @() {
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
          {
            size = FLEX
            rendObj = ROBJ_TEXT
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            color = 0xFFFFFFFF
            maxWidth = campBtnSize[0] - campBtnImageSize[0] - campBtnGap
            text = loc("changeCampaignShort")
          }.__update(fontBoldTinyAccentedShaded))
        unseenCampaigns.get().len() == 0 ? null
          : priorityUnseenMark.__merge({ hplace = ALIGN_RIGHT, pos = [hdpx(10), hdpx(-10)] })
      ].filter(@(v) v != null)
}

let dropMenuBtn = mkDropMenuBtn(getTopMenuButtons, topMenuButtonsGenId)

let btnPremDailyBonus = @() {
  watch = [allow_subscriptions, hasPremiumSubs, canReceivePremDailyBonus]
  children = !allow_subscriptions.get() || !hasPremiumSubs.get() || !canReceivePremDailyBonus.get() ? null
    : translucentButton("ui/gameuiskin#prem_daily_bonus.svg", premDailyBonusWnd, null,
        @(_) @() {
          watch = canReceivePremDailyBonus
          hplace = ALIGN_RIGHT
          vplace = ALIGN_TOP
          children = !canReceivePremDailyBonus.get() ? priorityUnseenMark : null
        }, { iconSize = evenPx(75), size = PRIMARY.size })
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
    pos = [-hdpx(4), hdpx(4)]
    children = needShopUnseenMark.get() ? priorityUnseenMark : null
  },
  { iconMul = 0.8 })

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
        btnHorRow([campaignsBtn, btnPremDailyBonus])
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
              pos = [0, hdpx(-15)]
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
