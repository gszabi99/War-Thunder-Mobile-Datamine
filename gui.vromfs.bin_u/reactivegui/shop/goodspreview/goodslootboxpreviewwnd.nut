from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import defer
from "%sqstd/underscore.nut" import prevIfEqual
from "%appGlobals/config/lootboxPresentation.nut" import getLootboxName, getLootboxPreviewBg
from "%appGlobals/currenciesState.nut" import commonCurrencies
from "%appGlobals/pServer/campaign.nut" import purchasesCount, todayPurchasesCount
from "%appGlobals/pServer/seasonCurrencies.nut" import currencyToFullId
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/rewardType.nut" import G_LOOTBOX, G_CURRENCY
from "%appGlobals/userstats/serverTimeDay.nut" import serverTimeDay, getDay, dayOffset
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/gradientDefComps.nut" import doubleSideGradient
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/components/scrollArrows.nut" import mkScrollArrow, scrollArrowImageSmall
from "%rGui/mainMenu/gamercard.nut" import mkCurrenciesBtns
from "%rGui/navState.nut" import registerScene, setSceneBgFallback, setSceneBg
from "%rGui/rewards/rewardViewInfo.nut" import getAllLootboxRewardsViewInfo
from "%rGui/shop/goodsPreview/goodsPreviewPkg.nut" import mkPreviewHeader, mkTimeBlockCentered, mkPriceBlockCentered,
  opacityAnims, ANIM_SKIP, ANIM_SKIP_DELAY
import "%rGui/shop/goodsPreview/mkGiftSchRewardBtn.nut" as mkGiftSchRewardBtn
from "%rGui/shop/goodsPreviewState.nut" import GPT_LOOTBOX, previewType, previewGoods, closeGoodsPreview,
  openPreviewCount
from "%rGui/shop/lootboxPreviewContent.nut" import lootboxImageWithTimer, lootboxContentBlock, mkJackpotProgress
from "%rGui/shop/lootboxPreviewState.nut" import getStepsToNextFixed
from "%rGui/shop/schRewardsState.nut" import schRewards
from "%rGui/style/gradients.nut" import simpleHorGrad
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const wndHeaderHeight = hdpx(110)
const contentGap = hdpx(30)
let wndContentHeight = saSize[1] - wndHeaderHeight - contentGap
let contentGradientSize = [contentGap, saBorders[1]]
let rewardsBlockWidth = saSize[0] - hdpx(650)
const btnW = hdpx(300)
const gapBtn = hdpx(20)


const aTimeHeaderStart = 0.5
const aTimePriceStart = aTimeHeaderStart + 0.1

const countPurchases = 10

let skipAnimsOnce = Watched(false)

let openCount = Computed(@() previewType.get() == GPT_LOOTBOX ? openPreviewCount.get() : 0)
let lootbox = Computed(@(prev) prevIfEqual(prev,
  serverConfigs.get()?.lootboxesCfg[
    previewGoods.get()?.rewards.findvalue(@(r) r.gType == G_LOOTBOX).id
  ]))
let lootboxAmount = Computed(@() previewGoods.get()?.rewards.findvalue(@(r) r.gType == G_LOOTBOX).count)
let bgImage = keepref(Computed(@() getLootboxPreviewBg(lootbox.get()?.name)))

function balanceButtons() {
  let { currencyId = "" } = previewGoods.get()?.price
  let currencyIds = { [currencyId] = true }
  if (lootbox.get() != null)
    foreach (r in getAllLootboxRewardsViewInfo(lootbox.get())) {
      let cId = currencyToFullId.get()?[r.id] ?? r.id
      if (r.rType == G_CURRENCY && !commonCurrencies.keys().contains(cId))
        currencyIds[cId] <- true
    }
  currencyIds.$rawdelete("")
  return {
    watch = [previewGoods, lootbox, currencyToFullId]
    pos = [saBorders[0], 0]
    padding = [hdpx(10), saBorders[0]]
    rendObj = ROBJ_IMAGE
    image = simpleHorGrad
    color = 0x70000000
    hplace = ALIGN_RIGHT
    children = currencyIds.len() == 0 ? null
      : mkCurrenciesBtns(currencyIds.keys(), null, {size = SIZE_TO_CONTENT})
    animations = opacityAnims(1, aTimePriceStart + 0.5)
  }
}

let header = mkPreviewHeader(
  Computed(@() lootbox.get() == null ? "" : getLootboxName(lootbox.get().name)),
  closeGoodsPreview,
  aTimeHeaderStart,
  [
    @() {
      watch = [previewGoods, schRewards]
      children = mkGiftSchRewardBtn(
        schRewards.get()?[$"gift_{previewGoods.get()?.meta.campaign}_goods_preview"],
        aTimeHeaderStart)
    }
  ],
  balanceButtons)

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
  size = FLEX
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
      size = FLEX
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      children = lootbox.get() == null ? null
        : [
            { size = FLEX }
            lootboxImageWithTimer(lootbox.get(), lootboxAmount.get())
            { size = flex(3) }
            mkJackpotProgress(Computed(@() getStepsToNextFixed(lootbox.get(), serverConfigs.get(), servProfile.get())))
            { size = const [0, hdpx(10)] }
            mkTimeBlockCentered(aTimePriceStart)
            { size = const [0, hdpx(10)] }
            doubleSideGradient.__merge({
              size = const [btnW * 2 + gapBtn, SIZE_TO_CONTENT]
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
  size = FLEX

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
    children = [
      header
      content
    ]
  }
  animations = wndSwitchAnim
}

const sceneId = "goodsLootboxPreviewWnd"
registerScene(sceneId, previewWnd, closeGoodsPreview, openCount)
setSceneBgFallback(sceneId, "ui/images/event_bg.avif")
setSceneBg(sceneId, bgImage.get().bg, bgImage.get()?.bgColor)
bgImage.subscribe(@(v) setSceneBg(sceneId, v.bg, v?.bgColor))
