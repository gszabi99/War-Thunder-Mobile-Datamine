from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getSubsPresentation, getSubsName } = require("%appGlobals/config/subsPresentation.nut")
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, mkBgImg, borderBgGold, mkSubsPricePlate,
  mkSlotBgImg, mkSquareIconBtn,
  goodsSmallSize, goodsBgH, mkBgParticles
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { mkGradGlowMultiLine } = require("%rGui/components/gradTexts.nut")


let fontIconPreview = "⌡"
let contentMargin = hdpx(20)
let mkSubsIcon = @(id) mkBgImg($"{getSubsPresentation(id).icon}:0:P")
  .__update({
    size = const [hdpx(300), hdpx(200)]
    pos = [0, hdpx(30)]
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
  })
let titleFontGrad = mkFontGradient(0xFFF2E46B, 0xFFCE733B, 11, 6, 2)

let bgHiglight =  {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x0134130A
}

let mkTitle = @(id) mkGradGlowMultiLine(utf8ToUpper(getSubsName(id)), fontWtMediumAccented, titleFontGrad, goodsSmallSize[0], {
  pos = [0, hdpx(10)]
  hplace = ALIGN_CENTER
})

function mkSubscriptionCard(subs, onClick, state, animParams) {
  let { id } = subs
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])
  let icon = mkSubsIcon(id)
  let title = mkTitle(id)
  let previewBtn = mkSquareIconBtn(fontIconPreview, onClick, { vplace = ALIGN_BOTTOM, margin = contentMargin })
  return mkGoodsWrap(
    subs,
    onClick,
    @(sf, _) [
      mkSlotBgImg()
      bgParticles
      borderBgGold
      sf & S_HOVER ? bgHiglight : null
      icon
      title
      previewBtn
    ],
    mkSubsPricePlate(subs, state, animParams),
    { size = goodsSmallSize })
}

return {
  mkSubscriptionCard
}
