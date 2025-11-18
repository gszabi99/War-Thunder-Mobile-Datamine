from "%globalsDarg/darg_library.nut" import *
let { G_LOOTBOX } = require("%appGlobals/rewardType.nut")
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, borderBg, mkSlotBgImg, goodsSmallSize, mkSquareIconBtn, mkGoodsTimeLeftText,
   mkPricePlate, mkGoodsCommonParts, goodsBgH, mkBgParticles, underConstructionBg,
   mkGoodsLimitText, mkBorderByCurrency, mkCurrencyAmountTitle
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { getLootboxName, mkLoootboxImage, customGoodsLootboxScale } = require("%appGlobals/config/lootboxPresentation.nut")
let { mkGradGlowText } = require("%rGui/components/gradTexts.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")


let titleFontGrad = mkFontGradient(0xFFFFFFFF, 0xFFE0E0E0, 11, 6, 2)
let lootboxIconSize = (goodsSmallSize[0] * 0.65).tointeger()
let fonticonPreview = "⌡"
let contentMargin = hdpx(20)
let textMargin = [hdpx(15), contentMargin]

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x3F3F3F
}

function getLocNameLootbox(goods) {
  let name = goods?.rewards.findvalue(@(r) r.gType == G_LOOTBOX).id
    ?? goods?.lootboxes.findindex(@(_) true) 
  return name == null ? goods.id : getLootboxName(name)
}

let mkLootboxTitle = @(goods) {
  margin = textMargin
  hplace = ALIGN_RIGHT
  halign = ALIGN_RIGHT
  clipChildren = true
  flow = FLOW_VERTICAL
  children = [
    mkGradGlowText(getLocNameLootbox(goods), fontSmall, titleFontGrad, {
      behavior = Behaviors.Marquee
      maxWidth = goodsSmallSize[0] - contentMargin * 2
    })
    { size = flex() }
    mkGoodsLimitText(goods, titleFontGrad)
  ]
}

function getGoodsLootbox(goods) {
  let { rewards = null, lootboxes = {} } = goods
  if (rewards != null) {
    let r = goods?.rewards.findvalue(@(r) r.gType == G_LOOTBOX).id
    return { lootboxId = r?.id, lootboxAmount = r?.count ?? 0 }
  }
  
  let lootboxId = lootboxes.findindex(@(_) true)
  return { lootboxId, lootboxAmount = lootboxes?[lootboxId] ?? 0 }
}

function mkGoodsLootbox(goods, _, state, animParams, addChildren) {
  let { isShowDebugOnly = false, isFreeReward = false, price = {} } = goods
  let { lootboxId, lootboxAmount } = getGoodsLootbox(goods)
  let onClick = @() openGoodsPreview(goods.id)
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])
  let border = mkBorderByCurrency(borderBg, isFreeReward, price?.currencyId)
  return mkGoodsWrap(
    goods,
    onClick,
    @(sf, canPurchase) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      bgParticles
      border
      sf & S_HOVER ? bgHiglight : null
      lootboxId == null ? null
        : mkLoootboxImage(lootboxId, lootboxIconSize, customGoodsLootboxScale?[lootboxId] ?? 1)
            .__update({ hplace = ALIGN_CENTER, vplace = ALIGN_CENTER, pos = [0, lootboxIconSize * 0.1] })
      lootboxAmount <= 1
        ? null
        : mkCurrencyAmountTitle(lootboxAmount, 0, titleFontGrad).__update({ margin = const [hdpx(32), 0] })
      mkLootboxTitle(goods)
      !canPurchase ? null : mkSquareIconBtn(fonticonPreview, onClick, { vplace = ALIGN_BOTTOM, margin = contentMargin })
      mkGoodsTimeLeftText(goods, { vplace = ALIGN_BOTTOM, margin = textMargin })
    ].extend(mkGoodsCommonParts(goods, state), addChildren),
    mkPricePlate(goods, state, animParams), { size = goodsSmallSize })
}

return {
  mkGoodsLootbox
  getLocNameLootbox
}