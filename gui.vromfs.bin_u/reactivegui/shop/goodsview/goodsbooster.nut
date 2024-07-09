from "%globalsDarg/darg_library.nut" import *
let { getBoosterIcon } = require("%appGlobals/config/boostersPresentation.nut")
let { mkGoodsWrap, borderBg, mkCurrencyAmountTitle, mkPricePlate, mkGoodsCommonParts,
  mkSlotBgImg, goodsSmallSize, goodsBgH, mkBgParticles, underConstructionBg, mkGoodsLimit
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { mkColoredGradientY, mkFontGradient,
  gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")

let iconSize = hdpxi(187)

let priceBgGrad = mkColoredGradientY(0xFF09C6F9, 0xFF00808E, 12)
let titleFontGrad = mkFontGradient(0xFF8bdeea, 0xFF8bdeea, 11, 6, 2)

let slotNameBG = {
  hplace = ALIGN_RIGHT
  color = 0x80000000
  rendObj = ROBJ_9RECT
  image = gradCircularSmallHorCorners
  screenOffs = [0, 0, hdpx(200), hdpx(200)]
  texOffs = gradCircCornerOffset
  margin = [ hdpx(4), hdpx(10)]
}

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x3F3F3F
}


let boosterImage = @(id){
  size = [iconSize, iconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"{getBoosterIcon(id)}:{iconSize}:{iconSize}:P")
}

let mkImgs = @(list){
  size = flex()
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = -hdpx(40)
  children = list.map(@(_, id) boosterImage(id)).values()
}

let getLocNameBooster = @(goods) comma.join(goods.boosters.keys().map(@(id) loc($"boosters/{id}")))

function mkGoodsBooster(goods, onClick, state, animParams) {
  let { viewBaseValue = 0, isShowDebugOnly = false } = goods
  let nameBooster = @(id) loc($"boosters/{id}")
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])
  let boostersList = goods.boosters
  return mkGoodsWrap(
    goods,
    onClick,
    @(sf, _) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      bgParticles
      borderBg
      sf & S_HOVER ? bgHiglight : null
      mkImgs(boostersList)
      slotNameBG.__merge({
        size = [hdpx(270), viewBaseValue > 0 ? hdpx(175) : hdpx(135)]
        padding = [hdpx(20), 0]
        children = boostersList.map(@(v, id)
          mkCurrencyAmountTitle(v,
            viewBaseValue,
            titleFontGrad,
            nameBooster(id))).values()
      })
      mkGoodsLimit(goods)
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, priceBgGrad, state, animParams), {size = goodsSmallSize})
}

return {
  mkGoodsBooster
  getLocNameBooster
}