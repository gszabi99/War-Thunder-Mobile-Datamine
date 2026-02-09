from "%globalsDarg/darg_library.nut" import *
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { ALL_PURCHASED } = require("%rGui/shop/goodsStates.nut")
let { mkDecalIcon } = require("%rGui/unitCustom/unitDecals/unitDecalsComps.nut")
let { mkGoodsWrap, mkPricePlate, mkGoodsCommonParts, underConstructionBg, mkGoodsLimitAndEndTime, mkSlotBgImg,
  mkBgParticles, goodsSmallSize, goodsBgH, mkBorderByCurrency, borderBg, goodsH, limitFontGrad, titlePadding
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { mkGradText } = require("%rGui/components/gradTexts.nut")

let decalSize = (goodsH * 0.9 + 0.5).tointeger()
let getLocNameDecal = @(goods) $"{loc("reward/decal")} {loc($"decals/{goods.rewards?[0].id ?? goods.id}")}"
let mkGradeTitle = @(title, fontTex) {
  padding = [hdpx(20), titlePadding]
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  hplace = ALIGN_RIGHT
  clipChildren = true
  children = mkGradText(title, fontWtSmall, fontTex, {
    behavior = Behaviors.Marquee,
    delay = defMarqueeDelay
    maxWidth = goodsSmallSize[0] - titlePadding * 2,
  })
}

function mkGoodsDecal(goods, onClick, state, animParams, addChildren) {
  let decalId = goods.rewards?[0].id ?? ""
  let isPurchased = Computed(@() decalId in servProfile.get()?.decals)
  let stateExt = Computed(@() state.get() | (isPurchased.get() ? ALL_PURCHASED : 0))
  return mkGoodsWrap(
    goods,
    @() isPurchased.get() ? null : onClick(),
    @(_, _) [
      mkSlotBgImg()
      goods?.isShowDebugOnly ? underConstructionBg : null
      mkBgParticles([goodsSmallSize[0], goodsBgH])
      mkBorderByCurrency(borderBg, goods?.isFreeReward ?? false, goods?.price.currencyId)
      mkGoodsLimitAndEndTime(goods)
      mkDecalIcon(decalId, decalSize).__update({vplace = ALIGN_CENTER, hplace = ALIGN_CENTER})
      mkGradeTitle(getLocNameDecal(goods), limitFontGrad)
    ].extend(mkGoodsCommonParts(goods, stateExt), addChildren),
    mkPricePlate(goods, stateExt, animParams)
    { size = [goodsSmallSize[0], goodsH] })
}

return {
  getLocNameDecal
  mkGoodsDecal
}
