from "%globalsDarg/darg_library.nut" import *
let { getBoosterIcon } = require("%appGlobals/config/boostersPresentation.nut")
let { mkGoodsWrap, borderBg, mkCurrencyAmountTitleArea, mkPricePlate, mkGoodsCommonParts,
  mkSlotBgImg, goodsSmallSize, goodsBgH, mkBgParticles, underConstructionBg, mkGoodsLimitAndEndTime,
  titleFontGradConsumables, mkBorderByCurrency
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")

let iconSize = hdpxi(187)

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
  let { viewBaseValue = 0, isShowDebugOnly = false, isFreeReward = false, price = {} } = goods
  let nameBooster = @(id) loc($"boosters/{id}")
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])
  let boostersList = goods.boosters
  let border = mkBorderByCurrency(borderBg, isFreeReward, price?.currencyId)
  return mkGoodsWrap(
    goods,
    onClick,
    @(sf, _) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      bgParticles
      border
      sf & S_HOVER ? bgHiglight : null
      mkImgs(boostersList)
      slotNameBG.__merge({
        size = [hdpx(270), viewBaseValue > 0 ? hdpx(175) : hdpx(135)]
        padding = [hdpx(20), 0]
        children = boostersList.map(@(v, id)
          mkCurrencyAmountTitleArea(v,
            viewBaseValue,
            titleFontGradConsumables,
            nameBooster(id))).values()
      })
      mkGoodsLimitAndEndTime(goods)
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, state, animParams), {size = goodsSmallSize})
}

return {
  mkGoodsBooster
  getLocNameBooster
}