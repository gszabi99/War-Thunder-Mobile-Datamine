from "%globalsDarg/darg_library.nut" import *
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, borderBg, mkSlotBgImg, goodsSmallSize, mkSquareIconBtn,
   mkPricePlate, mkGoodsCommonParts, goodsBgH, mkBgParticles, underConstructionBg, mkTimeLeft,
   mkGoodsLimitText, mkBorderByCurrency, mkCurrencyAmountTitle
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { getLootboxName, mkLoootboxImage, customGoodsLootboxScale } = require("%appGlobals/config/lootboxPresentation.nut")
let { mkGradGlowText } = require("%rGui/components/gradTexts.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")


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

function getGoodsLootboxName(goods, serverConfigsV) {
  let lootbox = serverConfigsV?.lootboxesCfg[goods?.lootboxes.findindex(@(_) true)]
  return lootbox == null ? goods.id : getLootboxName(lootbox.name, lootbox?.meta.event)
}

let mkLootboxNameComp = @(goods) Computed(@() getGoodsLootboxName(goods, serverConfigs.get()))

let function mkLootboxTitle(goods, ovr = {}) {
  let title = mkLootboxNameComp(goods)
  return @() {
    watch = title
    margin = textMargin
    hplace = ALIGN_RIGHT
    halign = ALIGN_RIGHT
    clipChildren = true
    flow = FLOW_VERTICAL
    children = [
      mkGradGlowText(title.get(), fontSmall, titleFontGrad, {
        behavior = Behaviors.Marquee
        maxWidth = goodsSmallSize[0] - contentMargin * 2
      })
      { size = flex() }
      mkGoodsLimitText(goods, titleFontGrad)
    ]
  }.__update(ovr)
}

function mkGoodsLootbox(goods, _, state, animParams, addChildren) {
  let { lootboxes, isShowDebugOnly = false, timeRange = null, isFreeReward = false, price = {} } = goods
  let lootboxId = lootboxes.findindex(@(_) true)
  let onClick = @() openGoodsPreview(goods.id)
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])
  let border = mkBorderByCurrency(borderBg, isFreeReward, price?.currencyId)
  let amount = lootboxes?[lootboxId] ?? 0
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
      amount <= 1
        ? null
        : mkCurrencyAmountTitle(lootboxes?[lootboxId], 0, titleFontGrad).__update({ margin = [hdpx(32), 0] })
      mkLootboxTitle(goods, timeRange == null ? { size = flex() } : {})
      !canPurchase ? null : mkSquareIconBtn(fonticonPreview, onClick, { vplace = ALIGN_BOTTOM, margin = contentMargin })
      timeRange == null ? null
        : mkTimeLeft(timeRange.end, { vplace = ALIGN_BOTTOM, margin = textMargin })
    ].extend(mkGoodsCommonParts(goods, state), addChildren),
    mkPricePlate(goods, state, animParams), { size = goodsSmallSize })
}

return {
  mkGoodsLootbox
  getLocNameLootbox = @(goods) getGoodsLootboxName(goods, serverConfigs.get())
}