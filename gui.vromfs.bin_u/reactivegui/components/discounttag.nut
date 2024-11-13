from "%globalsDarg/darg_library.nut" import *

let discountTagW = hdpxi(100)
let discountTagH = hdpxi(50)
let discountTagBigW = hdpxi(120)
let discountTagBigH = hdpxi(60)

let discountTag = @(discountPrc, ovr = {}) discountPrc <= 0 || discountPrc >= 100 ? null : {
  size  = [ discountTagW, discountTagH ]
  pos = [ -discountTagW * 0.25, -discountTagH * 0.6 ]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#tag_discount.svg:{discountTagW}:{discountTagH}")
  color = 0xE0E00000
  children = {
    pos = [ 0, hdpx(4) ]
    hplace = ALIGN_CENTER
    rendObj = ROBJ_TEXT
    text = $"-{discountPrc}%"
    color = 0xFFFFFFFF
  }.__update(fontTiny)
}.__update(ovr)

let discountTagBig = @(discountPrc, ovr = {}) discountPrc <= 0 || discountPrc >= 100 ? null : {
  size  = [ discountTagBigW, discountTagBigH ]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#tag_discount.svg:{discountTagBigW}:{discountTagBigH}")
  color = 0xFFD22A19
  children = {
    pos = [ 0, hdpx(5) ]
    hplace = ALIGN_CENTER
    rendObj = ROBJ_TEXT
    text = $"-{discountPrc}%"
    color = 0xFFFFFFFF
    fontFx = FFT_GLOW
    fontFxFactor = hdpxi(64)
    fontFxColor = 0xFF000000
  }.__update(fontSmall)
}.__update(ovr)

function discountTagUnitCtor(discount, height, ovr) {
  let markTexOffs = [ 0, height / 2, 0, 0 ]
  let discountPrc = (discount * 100 + 0.5).tointeger()
  return discountPrc <= 0 || discountPrc >= 100 ? null : {
    size = [SIZE_TO_CONTENT, height]
    rendObj = ROBJ_9RECT
    image = Picture($"ui/gameuiskin#tag_popular.svg:{height}:{height}:P")
    keepAspect = KEEP_ASPECT_NONE
    screenOffs = markTexOffs
    texOffs = markTexOffs
    color = 0xFFD22A19
    children = {
      rendObj = ROBJ_TEXT
      text = $"-{discountPrc}%"
      color = 0xFFFFFFFF
      fontFx = FFT_GLOW
      fontFxFactor = hdpxi(64)
      fontFxColor = 0xFF000000
    }.__update(ovr)
  }
}

return {
  discountTag
  discountTagBig
  discountTagUnit = @(discount)
    discountTagUnitCtor(discount, hdpxi(42), { margin = [0, hdpx(30), 0, hdpx(15)] pos = [0, hdpx(3)] }.__update(fontTiny))
  discountTagUnitBig = @(discount)
    discountTagUnitCtor(discount, hdpxi(60), { margin = [0, hdpx(40), 0, hdpx(20)] pos = [0, hdpx(5)] }.__update(fontSmall))
  discountTagUnitSmall = @(discount)
    discountTagUnitCtor(discount, hdpxi(36), { margin = [0, hdpx(15), 0, hdpx(5)] pos = [0, hdpx(3)] }.__update(fontVeryTinyAccented))
}