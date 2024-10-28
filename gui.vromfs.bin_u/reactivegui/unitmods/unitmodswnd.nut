from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { modsInProgress, buy_unit_mod } = require("%appGlobals/pServer/pServerApi.nut")
let { mkGamercardUnitCampaign, gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let { isUnitModsOpen, closeUnitModsWnd, modsCategories, curCategoryId, curMod, curModId,
  modsSorted, unit, curModIndex, enableCurUnitMod, disableCurUnitMod,
  isCurModPurchased, isCurModEnabled, isCurModLocked, setCurUnitSeenModsCurrent,
  getModCurrency, getModCost, curUnitAllModsCost
} = require("unitModsState.nut")
let { mkModsCategories, tabW, tabH } = require("unitModsWndTabs.nut")
let { mkMods, modW, modTotalH, modsGap } = require("unitModsCarousel.nut")
let { textButtonPrimary, textButtonPurchase } = require("%rGui/components/textButton.nut")
let { textButtonVehicleLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { tabsGap, bgColor, tabExtraWidth } = require("%rGui/components/tabs.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_UNIT_MODS, PURCH_TYPE_UNIT_MOD, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { mkGradientCtorDoubleSideX } = require("%rGui/style/gradients.nut")
let panelBg = require("%rGui/components/panelBg.nut")
let buyUnitLevelWnd = require("%rGui/attributes/unitAttr/buyUnitLevelWnd.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")

let blocksGap = hdpx(60)
let iconSize = hdpxi(140)
let modsWidth = saSize[0] - modW - blocksGap
let catsBlockMargin = hdpx(24)
let catsBlockHeight = saSize[1] - gamercardHeight - catsBlockMargin
let catsHeight = Computed(@() min((tabH + tabsGap) * modsCategories.value.len() - tabsGap, catsBlockHeight))
let emptyCatSlotHeight = Computed(@() catsBlockHeight - catsHeight.value - tabsGap)

let pageWidth = saSize[0] + saBorders[0] - tabW
let pageMask = mkBitmapPictureLazy((pageWidth / 10).tointeger(), 2, mkGradientCtorDoubleSideX(0, 0xFFFFFFFF, 0.05))

let modsScrollHandler = ScrollHandler()
let catsScrollHandler = ScrollHandler()

let scrollToMod = @() curModIndex.get() == null ? null
  : modsScrollHandler.scrollToX(curModIndex.get() * (modW + modsGap) - (modsWidth - modW) / 2)

curCategoryId.subscribe(@(v) v == null ? null
  : catsScrollHandler.scrollToY((modsCategories.value.findindex(@(cat) cat == v) ?? 0)
    * (tabH + tabsGap) - catsHeight.value + tabH))

let mkVerticalPannableArea = @(content) {
  clipChildren = true
  size = [tabW, flex()]
  children = {
    size = flex()
    behavior = Behaviors.Pannable
    scrollHandler = catsScrollHandler
    children = content
    xmbNode = {
      canFocus = false
      scrollSpeed = 5.0
      isViewport = true
    }
  }
}

let mkHorizontalPannableArea = @(content) {
  rendObj = ROBJ_MASK
  image = pageMask()
  clipChildren = true
  size = [flex(), modTotalH]
  flow = FLOW_HORIZONTAL
  children = [
    { size = [blocksGap, flex()] }
    {
      size = flex()
      padding = [0, saBorders[0], 0, 0]
      behavior = Behaviors.Pannable
      scrollHandler = modsScrollHandler
      children = content
      xmbNode = {
        canFocus = false
        scrollSpeed = 2.0
        isViewport = true
        scrollToEdge = false
      }
    }
  ]

}

let categoriesBlock = @() {
  watch = modsCategories
  size = [flex(), SIZE_TO_CONTENT]
  children = mkModsCategories(modsCategories.value?.map(@(cat) {
    id = cat
    locId = cat == "" ? null : $"modification/{cat}"
  }),
  curCategoryId
)}

let modsBlock = @() {
  watch = modsSorted
  size = [SIZE_TO_CONTENT, flex()]
  children = mkMods(modsSorted.value, scrollToMod)
}

let mkModIcon = @() {
  watch = curMod
  size = [iconSize * 2.3, iconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{curMod.value?.name}.avif:0:P")
  keepAspect = KEEP_ASPECT_FILL
}

let mkModsInfo = @() panelBg.__merge({
  watch = [unit, curMod]
  size = curMod.value ? [modW * 2, SIZE_TO_CONTENT] : [ 0, 0]
  margin = [0, saBorders[0], 0, 0]
  padding = [hdpx(30), saBorders[0]]
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  children = unit.value == null ? null
    : [
        @() {
          watch = [curMod, curModId]
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          gap = hdpx(5)
          children = curModId.value == null ? null
            : [
                {
                  size = [flex(), SIZE_TO_CONTENT]
                  flow = FLOW_HORIZONTAL
                  children = [
                    mkModIcon
                    {
                      size = flex()
                      rendObj = ROBJ_TEXTAREA
                      behavior = Behaviors.TextArea
                      halign = ALIGN_RIGHT
                      text = loc($"modification/{curMod.value?.name}")
                    }.__update(fontSmall)
                  ]
                }

                {
                  size = [flex(), SIZE_TO_CONTENT]
                  rendObj = ROBJ_TEXTAREA
                  behavior = Behaviors.TextArea
                  text = loc($"modification/{curMod.value?.name}/desc")
                }.__update(fontTiny)

                unit.value.level >= (curMod.value?.reqLevel ?? 0) ? null
                  : {
                      size = [flex(), SIZE_TO_CONTENT]
                      rendObj = ROBJ_TEXT
                      text = loc("mod/reqLevel", { level = curMod.value?.reqLevel })
                    }.__update(fontSmall)
              ]
        }
      ]
})

let spinner = {
  size = [buttonStyles.defButtonMinWidth, buttonStyles.defButtonHeight]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = mkSpinner
}

function onPurchase() {
  let unitName = unit.value.name
  let modName = curMod.value.name
  let price = getModCost(curMod.value, curUnitAllModsCost.value)
  let currencyId = getModCurrency(curMod.value)
  openMsgBoxPurchase(
    loc("shop/needMoneyQuestion",
      { item = colorize(userlogTextColor, loc($"modification/{modName}")) }),
    { price, currencyId },
    @() buy_unit_mod(unitName, modName, currencyId, price),
    mkBqPurchaseInfo(PURCH_SRC_UNIT_MODS, PURCH_TYPE_UNIT_MOD, $"{unitName} {modName}"))
}

function onClose() {
  setCurUnitSeenModsCurrent()
  closeUnitModsWnd()
}

let unitModsWnd = {
  key = {}
  size = flex()
  padding = saBordersRv
  behavior = HangarCameraControl
  eventPassThrough = true //compatibility with 2024.09.26 (before touchMarginPriority introduce)
  touchMarginPriority = TOUCH_BACKGROUND
  flow = FLOW_VERTICAL
  children = [
    @(){
      watch = curCampaign
      children = mkGamercardUnitCampaign(onClose, $"gamercard/levelUnitMod/desc/{curCampaign.value}")
    }
    {
      size = [saSize[0] + saBorders[0], flex()]
      flow = FLOW_HORIZONTAL
      children = [
        @() {
          watch = emptyCatSlotHeight
          size = [tabW, flex()]
          margin = [catsBlockMargin, 0, 0, 0]
          flow = FLOW_VERTICAL
          children = emptyCatSlotHeight.value <= 0 ? mkVerticalPannableArea(categoriesBlock)
            : [
                categoriesBlock
                {
                  margin = [tabsGap, 0, 0, tabExtraWidth]
                  size = [tabW - tabExtraWidth, emptyCatSlotHeight.value]
                  rendObj = ROBJ_SOLID
                  color = bgColor
                }
              ]
        }
        {
          size = flex()
          flow = FLOW_VERTICAL
          halign = ALIGN_RIGHT
          children = [
            mkModsInfo
            { size = flex() }
            @() {
              watch = [isCurModPurchased, isCurModEnabled,
                isCurModLocked, curMod, modsInProgress]
              size = [flex(), SIZE_TO_CONTENT]
              margin = [hdpx(25), saBorders[0], hdpx(25), 0]
              halign = ALIGN_RIGHT
              children = !curMod.value ? null
                : isCurModLocked.value
                  ? textButtonVehicleLevelUp(utf8ToUpper(loc("mainmenu/btnLevelBoost")), curMod.value?.reqLevel,
                    @() buyUnitLevelWnd(unit.value.name), { hotkeys = ["^J:Y"] })
                : modsInProgress.value != null ? spinner
                : !isCurModPurchased.value ? textButtonPurchase(loc("mainmenu/btnBuy"), onPurchase)
                : !isCurModEnabled.value ? textButtonPrimary(loc("mod/enable"), enableCurUnitMod)
                : !curMod.value?.isAlwaysOn ? textButtonPrimary(loc("mod/disable"), disableCurUnitMod)
                : null
            }
            mkHorizontalPannableArea(modsBlock)
          ]
        }
      ]
    }
  ]
  animations = wndSwitchAnim
}

registerScene("unitModsWnd", unitModsWnd, closeUnitModsWnd, isUnitModsOpen)
