from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { prevIfEqual } = require("%sqstd/underscore.nut")
let { G_LOOTBOX } = require("%appGlobals/rewardType.nut")
let { registerScene, setSceneBgFallback, setSceneBg } = require("%rGui/navState.nut")
let { GPT_LOOTBOX, previewType, previewGoods, closeGoodsPreview, openPreviewCount
} = require("%rGui/shop/goodsPreviewState.nut")
let { getCampaignStatsId, purchasesCount, todayPurchasesCount } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { getLootboxName, getLootboxPreviewBg } = require("%appGlobals/config/lootboxPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { mkPreviewHeader, mkTimeBlockCentered, mkPriceBlockCentered, opacityAnims, horGap,
  ANIM_SKIP, ANIM_SKIP_DELAY
} = require("%rGui/shop/goodsPreview/goodsPreviewPkg.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { lootboxImageWithTimer, lootboxContentBlock, mkJackpotProgress
} = require("%rGui/shop/lootboxPreviewContent.nut")
let { getStepsToNextFixed } = require("%rGui/shop/lootboxPreviewState.nut")
let mkGiftSchRewardBtn = require("%rGui/shop/goodsPreview/mkGiftSchRewardBtn.nut")
let { schRewards } = require("%rGui/shop/schRewardsState.nut")
let { doubleSideGradient, doubleSideGradientPaddingX } = require("%rGui/components/gradientDefComps.nut")
let { serverTimeDay, getDay, dayOffset } = require("%appGlobals/userstats/serverTimeDay.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")

let wndHeaderHeight = hdpx(110)
let contentGap = hdpx(30)
let wndContentHeight = saSize[1] - wndHeaderHeight - contentGap
let contentGradientSize = [contentGap, saBorders[1]]
let rewardsBlockWidth = saSize[0] - hdpx(650)
let btnW = hdpx(300)
let gapBtn = hdpx(20)


let aTimeHeaderStart = 0.5
let aTimePriceStart = aTimeHeaderStart + 0.1

let countPurchases = 10

let skipAnimsOnce = Watched(false)

let openCount = Computed(@() previewType.get() == GPT_LOOTBOX ? openPreviewCount.get() : 0)
let lootbox = Computed(@(prev) prevIfEqual(prev,
  serverConfigs.get()?.lootboxesCfg[
    previewGoods.get()?.rewards.findvalue(@(r) r.gType == G_LOOTBOX).id
  ]))
let lootboxAmount = Computed(@() previewGoods.get()?.rewards.findvalue(@(r) r.gType == G_LOOTBOX).count)
let bgImage = keepref(Computed(@() getLootboxPreviewBg(lootbox.get()?.name)))


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
          children = mkGiftSchRewardBtn(
            schRewards.get()?[$"gift_{getCampaignStatsId(previewGoods.get()?.meta.campaign)}_goods_preview"],
            aTimeHeaderStart)
        }
      ]
    }
    balanceButtons
  ]
}

function canBuyNGoods(goods, purchCount, todayPurchCount, dOffset, servTimeDay) {
  let { id, limit = 0, dailyLimit = 0 } = goods
  if (limit > 0 && limit <= (purchCount?[id].count ?? 0) + countPurchases)
    return false
  if (dailyLimit > 0) {
    let { lastTime = 0, count = 0 } = todayPurchCount?[id]
    let today = getDay(lastTime, dOffset) == servTimeDay ? count : 0
    if (dailyLimit <= (today + countPurchases))
      return false
  }
  return true
}

let btnOvr = {
  size = [btnW, defButtonHeight]
  minWidth = btnW
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
      watch = [lootbox, lootboxAmount, purchasesCount, todayPurchasesCount, dayOffset, serverTimeDay, previewGoods]
      size = flex()
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      children = lootbox.get() == null ? null
        : [
            { size = flex() }
            lootboxImageWithTimer(lootbox.get(), lootboxAmount.get())
            { size = flex(3) }
            mkJackpotProgress(Computed(@() getStepsToNextFixed(lootbox.get(), serverConfigs.get(), servProfile.get())))
            { size = const [0, hdpx(10)] }
            mkTimeBlockCentered(aTimePriceStart)
            { size = const [0, hdpx(10)] }
            doubleSideGradient.__merge({
              size = [btnW * 2 + gapBtn, SIZE_TO_CONTENT]
              flow = FLOW_HORIZONTAL
              gap = gapBtn
              halign = ALIGN_CENTER
              children = [
                mkPriceBlockCentered(aTimePriceStart, 1, btnOvr)
                canBuyNGoods(previewGoods.get(), purchasesCount.get(), todayPurchasesCount.get(),
                    dayOffset.get(), serverTimeDay.get())
                  ? mkPriceBlockCentered(aTimePriceStart + 0.2, countPurchases, btnOvr)
                  : null
              ]
            })
          ]
    }
  ]
}

let previewWnd = @() {
  key = openCount
  size = flex()

  function onAttach() {
    if (!skipAnimsOnce.get())
      return

    skipAnimsOnce.set(false)
    defer(function() {
      anim_skip(ANIM_SKIP)
      anim_skip_delay(ANIM_SKIP_DELAY)
    })
  }
  onDetach = @() skipAnimsOnce.set(openCount.get() > 0)
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
