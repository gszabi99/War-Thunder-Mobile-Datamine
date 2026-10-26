from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/passPresentation.nut" import getPointsPresentation
from "%rGui/shop/goodsPreviewState.nut" import openGoodsPreview
from "%rGui/shop/goodsView/sharedParts.nut" import mkGoodsWrap, borderBg, mkSlotBgImg, goodsSmallSize,
  mkSquareIconBtn, mkGoodsTimeLeftText, mkPricePlate, mkGoodsCommonParts, goodsBgH, mkBgParticles,
  underConstructionBg, mkGoodsLimitText, mkBorderByCurrency, mkCurrencyAmountTitle,
  titleFontGradCommon, defIconSize
from "%rGui/textFormatByLang.nut" import decimalFormat


const fonticonPreview = "⌡"
const contentMargin = hdpx(20)
let textMargin = [hdpx(15), contentMargin]

let bgHiglight = {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = 0x3F3F3F
}

function getLocNameBpPoints(goods) {
  let amount = goods.rewards?[0].count ?? 0
  return loc("shop/item/bpPoints/amount", { amountTxt = decimalFormat(amount), amount })
}

let mkIcon = @(count) {
  size = defIconSize
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"{getPointsPresentation(count).img}:{defIconSize[0]}:{defIconSize[1]}:P")
  keepAspect = true
}

function mkGoodsBpPoints(goods, onClick, state, animParams, addChildren) {
  let { viewBaseValue = 0, isShowDebugOnly = false, isFreeReward = false, price = {}, rewards = [] } = goods
  let { count = 0 } = rewards?[0]
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])
  let border = mkBorderByCurrency(borderBg, isFreeReward, price?.currencyId)
  let goodsLimit = mkGoodsLimitText(goods, titleFontGradCommon, { margin = textMargin })
  let timeLeft = mkGoodsTimeLeftText(goods, { vplace = ALIGN_BOTTOM, margin = textMargin })
  let icon = mkIcon(count)
  let amount = mkCurrencyAmountTitle(count, viewBaseValue, titleFontGradCommon)
  let goodsCommonParts = mkGoodsCommonParts(goods, state)
  let slotBgImg = mkSlotBgImg()
  let previewBtn = mkSquareIconBtn(fonticonPreview, @() openGoodsPreview(goods.id), { vplace = ALIGN_BOTTOM, margin = contentMargin })
  return mkGoodsWrap(
    goods,
    onClick,
    @(sf, _) [
      slotBgImg
      isShowDebugOnly ? underConstructionBg : null
      bgParticles
      border
      sf & S_HOVER ? bgHiglight : null
      icon
      goodsLimit
      previewBtn
      timeLeft
      amount
    ].extend(goodsCommonParts, addChildren),
    mkPricePlate(goods, state, animParams),
    { size = goodsSmallSize })
}

return {
  mkGoodsBpPoints
  getLocNameBpPoints
}