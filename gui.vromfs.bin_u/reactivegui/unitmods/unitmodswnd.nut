from "%globalsDarg/darg_library.nut" import *
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { mkGamercard, gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let { isUnitModsOpen, closeUnitModsWnd, modsCategories, curCategoryId, curMod, curModId,
  modsSorted, unit, curModIndex, buyCurUnitMod, enableCurUnitMod, disableCurUnitMod,
  isCurModPurchased, isCurModEnabled, isCurModLocked, getModCost, getModCurrency
} = require("unitModsState.nut")
let { mkModsCategories, tabW, tabH } = require("unitModsWndTabs.nut")
let { mkMods, modW, modTotalH, modsGap } = require("unitModsCarousel.nut")
let { textButtonPrimary, textButtonPurchase } = require("%rGui/components/textButton.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { mkPlatoonOrUnitTitle } = require("%rGui/unit/components/unitInfoPanel.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { modsInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { tabsGap } = require("%rGui/components/tabs.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")

let blocksGap = hdpx(40)
let modsWidth = saSize[0] - modW - blocksGap
let catsHeight = saSize[1] - tabH - gamercardHeight

let modsScrollHandler = ScrollHandler()
let catsScrollHandler = ScrollHandler()

curModIndex.subscribe(@(v) v == null ? null
  : modsScrollHandler.scrollToX(v * (modW + modsGap) - (modsWidth - modW) / 2))

curCategoryId.subscribe(@(v) v == null ? null
  : catsScrollHandler.scrollToY((modsCategories.value.findindex(@(cat) cat == v) ?? 0)
    * (tabH + tabsGap) - catsHeight + tabH))

let mkVerticalPannableArea = @(content) {
  clipChildren = true
  size = [tabW, flex()]
  margin = [hdpx(24), 0, 0, 0]
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
  clipChildren = true
  size = [flex(), modTotalH]
  children = {
    size = flex()
    behavior = Behaviors.Pannable
    scrollHandler = modsScrollHandler
    children = content
    xmbNode = {
      canFocus = false
      scrollSpeed = 5.0
      isViewport = true
    }
  }
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
  children = mkMods(modsSorted.value)
}

let mkModsInfo = @() {
  watch = unit
  rendObj = ROBJ_IMAGE
  size = [modW * 1.5, SIZE_TO_CONTENT]
  pos = [saBorders[0], 0]
  image = Picture("ui/gameuiskin#debriefing_bg_grad@@ss.avif:O:P")
  color = 0x60090F16
  padding = [hdpx(30), saBorders[0]]
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  children = [
    mkPlatoonOrUnitTitle(unit.value)
    @() curModId.value == null ? { watch = curModId }
      : {
          watch = curModId
          size = [flex(), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc($"modification/{curModId.value}/desc")
        }.__update(fontTiny)
  ]
}

let spinner = {
  size = [buttonStyles.defButtonMinWidth, buttonStyles.defButtonHeight]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = mkSpinner
}

let onPurchase = @() openMsgBoxPurchase(
  loc("shop/needMoneyQuestion",
    { item = colorize(userlogTextColor, loc($"modification/{curMod.value.name}")) }),
  { price = getModCost(curMod.value), currencyId = getModCurrency(curMod.value) },
  buyCurUnitMod)

let unitModsWnd = {
  key = {}
  size = flex()
  padding = saBordersRv
  behavior = Behaviors.HangarCameraControl
  flow = FLOW_VERTICAL
  children = [
    mkGamercard(@() isUnitModsOpen(false), true)
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = blocksGap
      children = [
        mkVerticalPannableArea(categoriesBlock)
        {
          size = flex()
          flow = FLOW_VERTICAL
          halign = ALIGN_RIGHT
          gap = blocksGap
          children = [
            mkModsInfo
            { size = flex() }
            @() {
              watch = [isCurModPurchased, isCurModEnabled, isCurModLocked, curMod, modsInProgress]
              size = [flex(), buttonStyles.defButtonHeight]
              halign = ALIGN_RIGHT
              children = isCurModLocked.value || !curMod.value ? null
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
