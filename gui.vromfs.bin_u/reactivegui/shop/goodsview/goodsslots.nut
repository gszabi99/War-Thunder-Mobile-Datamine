from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/goodsPresentation.nut" import getGoodsIcon
from "%appGlobals/pServer/campaign.nut" import todayPurchasesCount
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/userstats/serverTimeDay.nut" import serverTimeDay, getDay, dayOffset
from "%rGui/rewards/rewardViewInfo.nut" import isRewardEmpty
from "%rGui/shop/goodsPreviewState.nut" import openGoodsPreview
from "%rGui/shop/goodsView/goodsDefault.nut" import getLocNameDefault
from "%rGui/shop/goodsView/sharedParts.nut" import txt, mkPricePlate, mkGoodsCommonParts, underConstructionBg,
  mkGoodsLimitAndEndTime, goodsH, goodsSmallSize, goodsBgH, mkBgImg, mkBgParticles, borderBg, mkSquareIconBtn,
  skipPurchasedPlate, purchasedPlate, mkCanPurchase, goodsW, mkCanShowTimeProgress
from "%rGui/style/backgrounds.nut" import bgShaded


const fontIconPreview = "⌡"
let bgSize = [goodsSmallSize[0], goodsBgH]
let iconSize = [goodsSmallSize[0] - hdpxi(40), (goodsBgH * 0.9 + 0.5).tointeger()]

function mkGoodsWrap(goods, onClick, mkContent, pricePlate = null, ovr = {}, childOvr = {}) {
  let { limit = 0, dailyLimit = 0, id = null, limitResetPrice = {} } = goods
  let stateFlags = Watched(0)

  let isGoodsFull = Computed(@() !!serverConfigs.get().goodsRewardSlots?[goods.slotsPreset].variants
    .findvalue(@(r) !isRewardEmpty(r, servProfile.get())))

  let { price = 0, currencyId = "" } = limitResetPrice
  let hasLimitResetPrice = price > 0 && currencyId != ""

  let canPurchase = mkCanPurchase(id, limit, dailyLimit, isGoodsFull)
  let canShowTimeProgress = mkCanShowTimeProgress(goods)
  let canShowSkipPurchase = Computed(@() isGoodsFull.get() && canShowTimeProgress.get() && hasLimitResetPrice)

  return @() bgShaded.__merge({
    size = [ goodsW, goodsH ]
    watch = [stateFlags, canPurchase, canShowSkipPurchase]
    behavior = Behaviors.Button
    clickableInfo = loc("mainmenu/btnBuy")
    onClick = canPurchase.get() ? onClick : null
    onElemState = @(v) stateFlags.set(v)
    xmbNode = XmbNode()
    transform = {
      scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.97, 0.97] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    children = [
      {
        size = [ FLEX, goodsBgH ]
        children = mkContent?(stateFlags.get(), canPurchase.get())
      }.__update(childOvr)
      canPurchase.get()
          ? pricePlate
        : canShowSkipPurchase.get()
          ? skipPurchasedPlate
        : purchasedPlate
    ]
  }).__update(ovr)
}

function mkPricePlateWrap(goods, state, animParams) {
  let purchasesCount = Computed(function() {
    let { lastTime = 0, count = 0 } = todayPurchasesCount.get()?[goods?.id]
    return getDay(lastTime, dayOffset.get()) == serverTimeDay.get() ? count : 0
  })
  return @() {
    watch = purchasesCount
    size = FLEX
    children = mkPricePlate(goods, state, animParams, true, purchasesCount.get())
  }
}

function mkGoodsSlots(goods, _, state, animParams, addChildren) {
  let bg = mkBgImg("ui/gameuiskin/shop_bg_blue.avif")
  let bgParticles = mkBgParticles(bgSize)
  let onClick = @() openGoodsPreview(goods.id)
  return mkGoodsWrap(
    goods,
    onClick,
    @(_, canPurchase) [
      bg
      goods?.isShowDebugOnly ? underConstructionBg : null
      bgParticles
      borderBg
      {
        size = iconSize
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        image = Picture($"{getGoodsIcon(goods.id)}:{iconSize[0]}:{iconSize[1]}:P")
        keepAspect = true
      }
      txt({
        margin = const [hdpx(10), hdpx(20)]
        hplace = ALIGN_RIGHT
        text = getLocNameDefault(goods)
      }.__update(fontSmall))
      mkSquareIconBtn(fontIconPreview, onClick, { vplace = ALIGN_BOTTOM, margin = hdpx(20) })
      canPurchase ? mkGoodsLimitAndEndTime(goods) : null
    ].extend(mkGoodsCommonParts(goods, state), addChildren),
    mkPricePlateWrap(goods, state, animParams)
    { size = [goodsSmallSize[0], goodsH], onClick })
}

return {
  mkGoodsSlots
}
