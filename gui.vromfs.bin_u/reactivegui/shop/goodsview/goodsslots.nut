from "%globalsDarg/darg_library.nut" import *
let { getLocNameDefault } = require("goodsDefault.nut")
let { mkGoodsWrap, txt, mkPricePlate, mkGoodsCommonParts, underConstructionBg, mkGoodsLimit,
  priceBgGradDefault, goodsH, goodsSmallSize, goodsBgH, mkBgImg, mkBgParticles, borderBg,
  mkSquareIconBtn
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { getGoodsIcon } = require("%appGlobals/config/goodsPresentation.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")


let fontIconPreview = "⌡"
let bgSize = [goodsSmallSize[0], goodsBgH]
let iconSize = [goodsSmallSize[0] - hdpxi(40), (goodsBgH * 0.9 + 0.5).tointeger()]

function mkGoodsSlots(goods, _, state, animParams) {
  let bg = mkBgImg("ui/gameuiskin/shop_bg_blue.avif")
  let bgParticles = mkBgParticles(bgSize)
  let onClick = @() openGoodsPreview(goods.id)
  return mkGoodsWrap(
    goods,
    onClick,
    @(_, _) [
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
      mkGoodsLimit(goods)
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, priceBgGradDefault, state, animParams)
    { size = [goodsSmallSize[0], goodsH], onClick })
}

return {
  mkGoodsSlots
}
