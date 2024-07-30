from "%globalsDarg/darg_library.nut" import *
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, borderBg, mkSlotBgImg, goodsSmallSize, mkSquareIconBtn,
   mkPricePlate, mkGoodsCommonParts, goodsBgH, mkBgParticles, underConstructionBg, mkTimeLeft,
   mkGoodsLimitText, priceBgGradDefault
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { getLootboxName, mkLoootboxImage } = require("%appGlobals/config/lootboxPresentation.nut")
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

function mkGoodsLootbox(goods, _, state, animParams) {
  let { lootboxes, isShowDebugOnly = false, timeRange = null } = goods
  let lootboxId = lootboxes.findindex(@(_) true)
  let onClick = @() openGoodsPreview(goods.id)
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])

  return mkGoodsWrap(
    goods,
    onClick,
    @(sf, canPurchase) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      bgParticles
      borderBg
      sf & S_HOVER ? bgHiglight : null
      lootboxId == null ? null
        : mkLoootboxImage(lootboxId, lootboxIconSize, { hplace = ALIGN_CENTER, vplace = ALIGN_CENTER, pos = [0, lootboxIconSize * 0.1] })
      mkLootboxTitle(goods, timeRange == null ? { size = flex() } : {})
      !canPurchase ? null : mkSquareIconBtn(fonticonPreview, onClick, { vplace = ALIGN_BOTTOM, margin = contentMargin })
      timeRange == null ? null
        : mkTimeLeft(timeRange.end, { vplace = ALIGN_BOTTOM, margin = textMargin })
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, priceBgGradDefault, state, animParams), { size = goodsSmallSize })
}

return {
  mkGoodsLootbox
  getLocNameLootbox = @(goods) getGoodsLootboxName(goods, serverConfigs.get())
}