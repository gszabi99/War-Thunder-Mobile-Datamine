from "%globalsDarg/darg_library.nut" import *
let { prevIfEqual } = require("%sqstd/underscore.nut")
let { registerScene, setSceneBgFallback, setSceneBg } = require("%rGui/navState.nut")
let { GPT_LOOTBOX, previewType, previewGoods, closeGoodsPreview, openPreviewCount
} = require("%rGui/shop/goodsPreviewState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { getLootboxName, lootboxPreviewBg } = require("%appGlobals/config/lootboxPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { mkPreviewHeader, mkTimeBlockCentered, mkPriceBlockCentered, opacityAnims, horGap
} = require("goodsPreviewPkg.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { lootboxImageWithTimer, lootboxContentBlock, mkJackpotProgress
} = require("%rGui/shop/lootboxPreviewContent.nut")
let { getStepsToNextFixed } = require("%rGui/shop/lootboxPreviewState.nut")
let mkGiftSchRewardBtn = require("mkGiftSchRewardBtn.nut")
let { schRewards } = require("%rGui/shop/schRewardsState.nut")
let { doubleSideGradientPaddingX } = require("%rGui/components/gradientDefComps.nut")
let wndHeaderHeight = hdpx(110)
let contentGap = hdpx(30)
let wndContentHeight = saSize[1] - wndHeaderHeight - contentGap
let contentGradientSize = [contentGap, saBorders[1]]
let rewardsBlockWidth = saSize[0] - hdpx(500)

let aTimeHeaderStart = 0.5
let aTimePriceStart = aTimeHeaderStart + 0.3

let openCount = Computed(@() previewType.get() == GPT_LOOTBOX ? openPreviewCount.get() : 0)
let lootbox = Computed(@(prev)
  prevIfEqual(prev, serverConfigs.get()?.lootboxesCfg[previewGoods.get()?.lootboxes.findindex(@(_) true)]))
let lootboxAmount = Computed(@() previewGoods.get()?.lootboxes.findvalue(@(_) true))
let bgImage = keepref(Computed(@() lootboxPreviewBg?[lootbox.get()?.name]))


let header = mkPreviewHeader(
  Computed(@() lootbox.get() == null ? "" : getLootboxName(lootbox.get().name)),
  closeGoodsPreview,
  aTimeHeaderStart)

function balanceButtons() {
  let { currencyId = "" } = previewGoods.get()?.price
  return {
    watch = previewGoods
    hplace = ALIGN_RIGHT
    children = currencyId == "" ? null : mkCurrenciesBtns([currencyId])
    animations = opacityAnims(1, aTimePriceStart + 0.5)
  }
}

let headerPanel = {
  size = [flex(), wndHeaderHeight]
  vplace = ALIGN_TOP
  hplace = ALIGN_LEFT
  valign = ALIGN_CENTER
  children = [
    {
      pos = [-doubleSideGradientPaddingX, 0]
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = horGap
      children = [
        header
        @() {
          watch = [previewGoods, schRewards]
          children = mkGiftSchRewardBtn(schRewards.get()?[$"gift_{previewGoods.get()?.meta.campaign}_goods_preview"],
            aTimeHeaderStart)
        }
      ]
    }
    balanceButtons
  ]
}

let pannableArea = verticalPannableAreaCtor(wndContentHeight + contentGradientSize[0] + contentGradientSize[1],
  contentGradientSize)
let scrollHandler = ScrollHandler()
let content = @() {
  size = flex()
  flow = FLOW_HORIZONTAL
  gap = contentGap
  children = [
    {
      size = [rewardsBlockWidth, wndContentHeight]
      children = [
        pannableArea(
          lootboxContentBlock(lootbox, rewardsBlockWidth),
          {},
          { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
        mkScrollArrow(scrollHandler, MR_B, scrollArrowImageSmall, { vplace = ALIGN_TOP, pos = [0, wndContentHeight] })
      ]
    }
    @() {
      watch = [lootbox, lootboxAmount]
      size = flex()
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      children = lootbox.get() == null ? null
        : [
            lootboxImageWithTimer(lootbox.get(), lootboxAmount.get())
            { size = flex() }
            mkJackpotProgress(Computed(@() getStepsToNextFixed(lootbox.get(), serverConfigs.get(), servProfile.get())))
            { size = const [0, hdpx(10)] }
            mkTimeBlockCentered(aTimePriceStart)
            { size = const [0, hdpx(10)] }
            mkPriceBlockCentered(aTimePriceStart)
          ]
    }
  ]
}

let previewWnd = @() {
  key = openCount
  size = flex()

  children = {
    size = saSize
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = contentGap
    children = [
      headerPanel
      content
    ]
  }
  animations = wndSwitchAnim
}

let sceneId = "goodsLootboxPreviewWnd"
registerScene(sceneId, previewWnd, closeGoodsPreview, openCount)
setSceneBgFallback(sceneId, "ui/images/event_bg.avif")
setSceneBg(sceneId, bgImage.get())
bgImage.subscribe(@(v) setSceneBg(sceneId, v))
