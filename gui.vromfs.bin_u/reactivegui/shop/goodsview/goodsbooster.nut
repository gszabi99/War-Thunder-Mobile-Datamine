from "%globalsDarg/darg_library.nut" import *
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getBoosterIcon } = require("%appGlobals/config/boostersPresentation.nut")
let { G_BOOSTER } = require("%appGlobals/rewardType.nut")
let { LIMIT_REACHED } = require("%rGui/shop/goodsStates.nut")
let { mkGoodsWrap, borderBg, mkCurrencyAmountTitleArea, mkPricePlate, mkGoodsCommonParts,
  mkSlotBgImg, goodsSmallSize, goodsBgH, mkBgParticles, underConstructionBg, mkGoodsLimitAndEndTimeExt,
  titleFontGradConsumables, mkBorderByCurrency, disabledBg
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
  margin = const [ hdpx(4), hdpx(10)]
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

let mkImgs = @(list) {
  size = flex()
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = -hdpx(40)
  children = list.map(@(b) boosterImage(b.id))
}

let getLocNameBooster = @(goods) comma.join(
  goods.rewards.filter(@(r) r.gType == G_BOOSTER).map(@(r) loc($"boosters/{r.id}")))

let getBoostersList = @(goods) goods.rewards.filter(@(r) r.gType == G_BOOSTER)

function mkGoodsBooster(goods, onClick, state, animParams, addChildren) {
  let { viewBaseValue = 0, isShowDebugOnly = false, isFreeReward = false, price = {} } = goods
  let nameBooster = @(id) loc($"boosters/{id}")
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])
  let boostersList = getBoostersList(goods)
  let border = mkBorderByCurrency(borderBg, isFreeReward, price?.currencyId)
  let hasLimitReached = Computed(@() null != boostersList.findvalue(function(b) {
    let { limit = 0 } = serverConfigs.get()?.allBoosters[b.id]
    return limit > 0 && limit <= (servProfile.get()?.boosters[b.id].battlesLeft ?? 0)
  }))
  let stateExt = Computed(@() state.get() | (hasLimitReached.get() ? LIMIT_REACHED : 0))
  return mkGoodsWrap(
    goods,
    @() hasLimitReached.get() ? null : onClick(),
    @(sf, _) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      bgParticles
      border
      sf & S_HOVER ? bgHiglight : null
      mkImgs(boostersList)
      slotNameBG.__merge({
        size = [hdpx(270), viewBaseValue > 0 ? hdpx(175) : hdpx(135)]
        padding = const [hdpx(20), 0]
        children = boostersList
          .map(@(b)
            mkCurrencyAmountTitleArea(b.count,
              viewBaseValue,
              titleFontGradConsumables,
              nameBooster(b.id)))
      })
      mkGoodsLimitAndEndTimeExt(goods, stateExt)
    ]
      .extend(mkGoodsCommonParts(goods, stateExt), addChildren)
      .append(@() {
        watch = hasLimitReached
        size = flex()
        children = hasLimitReached.get() ? disabledBg : null
      }),
    mkPricePlate(goods, stateExt, animParams), {size = goodsSmallSize})
}

return {
  mkGoodsBooster
  getLocNameBooster
}