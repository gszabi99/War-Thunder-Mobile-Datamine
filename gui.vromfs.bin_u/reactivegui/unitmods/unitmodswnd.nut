from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { modsInProgress, buy_unit_mod } = require("%appGlobals/pServer/pServerApi.nut")
let { mkGamercardUnitCampaign, gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let { isUnitModsOpen, closeUnitModsWnd, modsCategories, curCategoryId, curMod, curModId,
  modsSorted, unit, curModIndex, enableCurUnitMod, disableCurUnitMod,
  isCurModPurchased, isCurModEnabled, isCurModLocked, setCurUnitSeenModsCurrent,
  getModCurrency, getModCost, curUnitAllModsCost
} = require("%rGui/unitMods/unitModsState.nut")
let { mkModsCategories, tabW, tabH } = require("%rGui/unitMods/unitModsWndTabs.nut")
let { mkMods, modW, modTotalH, modsGap } = require("%rGui/unitMods/unitModsCarousel.nut")
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
let catsHeight = Computed(@() min((tabH + tabsGap) * modsCategories.get().len() - tabsGap, catsBlockHeight))
let emptyCatSlotHeight = Computed(@() catsBlockHeight - catsHeight.get() - tabsGap)

let pageWidth = saSize[0] + saBorders[0] - tabW
let pageMask = mkBitmapPictureLazy((pageWidth / 10).tointeger(), 2, mkGradientCtorDoubleSideX(0, 0xFFFFFFFF, 0.05))

let modsScrollHandler = ScrollHandler()
let catsScrollHandler = ScrollHandler()

let scrollToMod = @() curModIndex.get() == null ? null
  : modsScrollHandler.scrollToX(curModIndex.get() * (modW + modsGap) - (modsWidth - modW) / 2)

curCategoryId.subscribe(@(v) v == null ? null
  : catsScrollHandler.scrollToY((modsCategories.get().findindex(@(cat) cat == v) ?? 0)
    * (tabH + tabsGap) - catsHeight.get() + tabH))

let mkVerticalPannableArea = @(content) {
  clipChildren = true
  size = [tabW, flex()]
  children = {
    size = flex()
    behavior = Behaviors.Pannable
    touchMarginPriority = TOUCH_BACKGROUND
    scrollHandler = catsScrollHandler
    children = content
    xmbNode = XmbContainer()
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
      touchMarginPriority = TOUCH_BACKGROUND
      scrollHandler = modsScrollHandler
      children = content
      xmbNode = XmbContainer({ scrollSpeed = 2.0 })
    }
  ]

}

let categoriesBlock = @() {
  watch = modsCategories
  size = FLEX_H
  children = mkModsCategories(modsCategories.get()?.map(@(cat) {
    id = cat
    locId = cat == "" ? null : $"modification/{cat}"
  }),
  curCategoryId
)}

let modsBlock = @() {
  watch = modsSorted
  size = FLEX_V
  children = mkMods(modsSorted.get(), scrollToMod)
}

let mkModIcon = @() {
  watch = curMod
  size = [iconSize * 2.3, iconSize]
  rendObj = ROBJ_IMAGE
  image = curMod.get()?.name ? Picture($"ui/gameuiskin#{curMod.get().name}.avif:0:P") : null
  keepAspect = KEEP_ASPECT_FILL
}

let mkModsInfo = @() panelBg.__merge({
  watch = [unit, curMod]
  size = curMod.get() ? [modW * 2, SIZE_TO_CONTENT] : [ 0, 0]
  margin = [0, saBorders[0], 0, 0]
  padding = [hdpx(30), saBorders[0]]
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  children = unit.get() == null ? null
    : [
        @() {
          watch = [curMod, curModId]
          size = FLEX_H
          flow = FLOW_VERTICAL
          gap = hdpx(5)
          children = curModId.get() == null ? null
            : [
                {
                  size = FLEX_H
                  flow = FLOW_HORIZONTAL
                  children = [
                    mkModIcon
                    {
                      size = flex()
                      rendObj = ROBJ_TEXTAREA
                      behavior = Behaviors.TextArea
                      halign = ALIGN_RIGHT
                      text = loc($"modification/{curMod.get()?.name}")
                    }.__update(fontSmall)
                  ]
                }

                {
                  size = FLEX_H
                  rendObj = ROBJ_TEXTAREA
                  behavior = Behaviors.TextArea
                  text = loc($"modification/{curMod.get()?.name}/desc")
                }.__update(fontTiny)

                unit.get().level >= (curMod.get()?.reqLevel ?? 0) ? null
                  : {
                      size = FLEX_H
                      rendObj = ROBJ_TEXT
                      text = loc("mod/reqLevel", { level = curMod.get()?.reqLevel })
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
  let unitName = unit.get().name
  let modName = curMod.get().name
  let price = getModCost(curMod.get(), curUnitAllModsCost.get())
  let currencyId = getModCurrency(curMod.get())
  openMsgBoxPurchase({
    text = loc("shop/needMoneyQuestion",
      { item = colorize(userlogTextColor, loc($"modification/{modName}")) }),
    price = { price, currencyId },
    purchase = @() buy_unit_mod(unitName, modName, currencyId, price),
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_UNIT_MODS, PURCH_TYPE_UNIT_MOD, $"{unitName} {modName}")
  })
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
  touchMarginPriority = TOUCH_BACKGROUND
  flow = FLOW_VERTICAL
  children = [
    @(){
      watch = curCampaign
      children = mkGamercardUnitCampaign(onClose, getCampaignPresentation(curCampaign.get()).levelUnitModLocId)
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
          children = emptyCatSlotHeight.get() <= 0 ? mkVerticalPannableArea(categoriesBlock)
            : [
                categoriesBlock
                {
                  margin = [tabsGap, 0, 0, tabExtraWidth]
                  size = [tabW - tabExtraWidth, emptyCatSlotHeight.get()]
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
              size = FLEX_H
              margin = [hdpx(25), saBorders[0], hdpx(25), 0]
              halign = ALIGN_RIGHT
              children = !curMod.get() ? null
                : isCurModLocked.get()
                  ? textButtonVehicleLevelUp(utf8ToUpper(loc("mainmenu/btnLevelBoost")), curMod.get()?.reqLevel,
                    @() buyUnitLevelWnd(unit.get().name), { hotkeys = ["^J:Y"] })
                : modsInProgress.get() != null ? spinner
                : !isCurModPurchased.get() ? textButtonPurchase(loc("mainmenu/btnBuy"), onPurchase)
                : !isCurModEnabled.get() ? textButtonPrimary(loc("mod/enable"), enableCurUnitMod)
                : !curMod.get()?.isAlwaysOn ? textButtonPrimary(loc("mod/disable"), disableCurUnitMod)
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
