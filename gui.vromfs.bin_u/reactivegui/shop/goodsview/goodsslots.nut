from "%globalsDarg/darg_library.nut" import *
let { getLocNameDefault } = require("goodsDefault.nut")
let { txt, mkPricePlate, mkGoodsCommonParts, underConstructionBg, mkGoodsLimitAndEndTime,
  goodsH, goodsSmallSize, goodsBgH, mkBgImg, mkBgParticles, borderBg,
  mkSquareIconBtn, skipPurchasedPlate, purchasedPlate, mkCanPurchase, goodsW, mkCanShowTimeProgress
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { getGoodsIcon } = require("%appGlobals/config/goodsPresentation.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { isRewardEmpty } = require("%rGui/rewards/rewardViewInfo.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")


let fontIconPreview = "⌡"
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
    onElemState = @(v) stateFlags(v)
    xmbNode = XmbNode()
    transform = {
      scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.97, 0.97] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    children = [
      {
        size = [ flex(), goodsBgH ]
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
        margin = [hdpx(10), hdpx(20)]
        hplace = ALIGN_RIGHT
        text = getLocNameDefault(goods)
      }.__update(fontSmall))
      mkSquareIconBtn(fontIconPreview, onClick, { vplace = ALIGN_BOTTOM, margin = hdpx(20) })
      canPurchase ? mkGoodsLimitAndEndTime(goods) : null
    ].extend(mkGoodsCommonParts(goods, state), addChildren),
    mkPricePlate(goods, state, animParams)
    { size = [goodsSmallSize[0], goodsH], onClick })
}

return {
  mkGoodsSlots
}
