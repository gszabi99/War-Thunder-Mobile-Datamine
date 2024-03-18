from "%globalsDarg/darg_library.nut" import *
let { mkColoredGradientY, mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, borderBg, mkSlotBgImg, goodsSmallSize, mkSquareIconBtn,
   mkPricePlate, mkGoodsCommonParts, goodsBgH, mkBgParticles, underConstructionBg, mkTimeLeft
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { mkLoootboxImage, getLootboxName } = require("%rGui/unlocks/rewardsView/lootboxPresentation.nut")
let { mkGradGlowText } = require("%rGui/components/gradTexts.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")



let priceBgGrad = mkColoredGradientY(0xFF72A0D0, 0xFF588090, 12)
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

let mkLootboxTitle = @(fontTex, title) @() {
  watch = title
  margin = textMargin
  hplace = ALIGN_RIGHT
  clipChildren = true
  children = mkGradGlowText(title.get(), fontSmall, fontTex, {
    behavior = Behaviors.Marquee
    maxWidth = goodsSmallSize[0] - contentMargin * 2
  })
}

function getGoodsLootboxName(goods, serverConfigsV) {
  let lootbox = serverConfigsV?.lootboxesCfg[goods?.lootboxes.findindex(@(_) true)]
  return lootbox == null ? goods.id : getLootboxName(lootbox.name, lootbox?.meta.event)
}

let mkLootboxNameComp = @(goods) Computed(@() getGoodsLootboxName(goods, serverConfigs.get()))

function mkGoodsLootbox(goods, _, state, animParams) {
  let { lootboxes, isShowDebugOnly = false, timeRange = null } = goods
  let lootboxId = lootboxes.findindex(@(_) true)
  let onClick = @() openGoodsPreview(goods.id)
  return mkGoodsWrap(onClick,
    @(sf) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      mkBgParticles([goodsSmallSize[0], goodsBgH])
      borderBg
      sf & S_HOVER ? bgHiglight : null
      lootboxId == null ? null
        : mkLoootboxImage(lootboxId, lootboxIconSize, { hplace = ALIGN_CENTER, vplace = ALIGN_CENTER, pos = [0, lootboxIconSize * 0.1] })
      mkLootboxTitle(titleFontGrad, mkLootboxNameComp(goods))
      mkSquareIconBtn(fonticonPreview, onClick, { vplace = ALIGN_BOTTOM, margin = contentMargin })
      timeRange == null ? null
        : mkTimeLeft(timeRange.end, { vplace = ALIGN_BOTTOM, margin = textMargin })
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, priceBgGrad, state, animParams), { size = goodsSmallSize })
}

return {
  mkGoodsLootbox
  getLocNameLootbox = @(goods) getGoodsLootboxName(goods, serverConfigs.get())
}