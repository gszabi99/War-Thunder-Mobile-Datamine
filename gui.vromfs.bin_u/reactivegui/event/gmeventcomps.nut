from "%globalsDarg/darg_library.nut" import *
let { onGoodsClick, mkGoodsState } = require("%rGui/shop/shopWndPage.nut")
let { mkGoodsWrap, mkSlotBgImg, mkPricePlate, mkGoodsCommonParts, mkBgParticles } = require("%rGui/shop/goodsView/sharedParts.nut")
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")

let priceBgGrad = mkColoredGradientY(0xFFD2A51E, 0xFF91620F, 12)

let icons = {
  air_cbt_p_38k = "ui/gameuiskin#p_38k_300x300_clear.avif"
  air_cbt_yak_3t = "ui/gameuiskin#yak_3t_300x300_clear.avif"
  air_cbt_fw_190c = "ui/gameuiskin#fw_190c_300x300_clear.avif"
}

let glareDelay = 3.0
let glareDuration = 0.2

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x0114181E
}

let goodsGap = hdpx(40)
let goodsW = hdpx(280)
let goodsH = hdpx(400)
let pricePlateH = hdpx(90)
let goodsSize = [goodsW, goodsH]
let goodsBgSize = [goodsW, goodsH - pricePlateH]

let mkGmText = @(text) {
  size = flex()
  padding = hdpx(15)
  valign = ALIGN_TOP
  halign = ALIGN_CENTER
  children = {
    maxWidth = goodsW - hdpx(30)
    halign = ALIGN_CENTER
    rendObj = ROBJ_TEXTAREA
    text
    color = 0xFFFFFFFF
    fontSize = hdpx(36)
    behavior = Behaviors.TextArea
    delay = defMarqueeDelay
    speed = hdpx(20)
  }
}

let mkGmImg = @(id) {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture(icons?[id] ?? "")
  keepAspect = true
}

function mkGmGoods(goods, onClick, state, animParams) {
  let bgParticles = mkBgParticles(goodsBgSize)

  return mkGoodsWrap(
    goods,
    onClick,
    @(sf, _) [
      mkSlotBgImg()
      bgParticles
      sf & S_HOVER ? bgHiglight : null
      mkGmImg(goods.id)
      mkGmText(loc(goods.id))
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, priceBgGrad, state, animParams),
    { size = goodsSize },
    { size = goodsBgSize })
}

let gmEventContent = @(goodsList) @() {
  watch = goodsList
  padding = [hdpx(10), 0]
  flow = FLOW_HORIZONTAL
  gap = goodsGap
  halign = ALIGN_CENTER
  children = goodsList.get().map(@(goods, idx) mkGmGoods(goods,
    @() onGoodsClick(goods),
    mkGoodsState(goods),
    {
      delay = idx * glareDuration + glareDelay
      repeatDelay = glareDuration
    }))
}

return {
  gmEventContent
  goodsSize
  goodsGap
}