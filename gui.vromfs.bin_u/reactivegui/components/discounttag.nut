from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")

let discountTagW = hdpxi(100)
let discountTagH = hdpxi(50)
let discountTagBigW = hdpxi(120)
let discountTagBigH = hdpxi(60)
let discountOfferTagW = hdpxi(150)
let discountOfferTagH = hdpxi(50)
let discountOfferTagHTexOffs = [ 0, discountOfferTagH / 10, 0, discountOfferTagH / 2 ]

let discountTag = @(discountPrc, ovr = {}, textOvr = {}) discountPrc <= 0 || discountPrc >= 100 ? null : {
  size  = [ discountTagW, discountTagH ]
  pos = [ -discountTagW * 0.25, -discountTagH * 0.6 ]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#tag_discount.svg:{discountTagW}:{discountTagH}:P")
  color = 0xE0E00000
  children = {
    pos = [ 0, hdpx(4) ]
    hplace = ALIGN_CENTER
    rendObj = ROBJ_TEXT
    text = $"-{round(discountPrc)}%"
    color = 0xFFFFFFFF
  }.__update(fontTiny, textOvr)
}.__update(ovr)

let discountTagBig = @(discountPrc, ovr = {}) discountPrc <= 0 || discountPrc >= 100 ? null : {
  size  = [ discountTagBigW, discountTagBigH ]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#tag_discount.svg:{discountTagBigW}:{discountTagBigH}:P")
  color = 0xFFD22A19
  children = {
    pos = [ 0, hdpx(5) ]
    hplace = ALIGN_CENTER
    rendObj = ROBJ_TEXT
    text = $"-{round(discountPrc)}%"
    color = 0xFFFFFFFF
  }.__update(fontSmallShaded)
}.__update(ovr)

let discountTagOffer = @(discountPrc, ovr = {}) discountPrc <= 0 || discountPrc >= 100 ? null : {
  size  = [ discountOfferTagW, discountOfferTagH ]
  rendObj = ROBJ_9RECT
  image = Picture($"ui/gameuiskin#tag_first_purchase.svg:{discountOfferTagW}:{discountOfferTagH}:P")
  screenOffs = discountOfferTagHTexOffs
  texOffs = discountOfferTagHTexOffs
  color = 0xFFD22A19
  children = {
    pos = [ 0, hdpx(5) ]
    hplace = ALIGN_CENTER
    rendObj = ROBJ_TEXT
    text = $"-{round(discountPrc)}%"
  }.__update(fontTinyAccentedShaded)
}.__update(ovr)

function discountTagUnitCtor(discount, height, ovr) {
  let markTexOffs = [ 0, height / 2, 0, 0 ]
  let discountPrc = (discount * 100 + 0.5).tointeger()
  return discountPrc <= 0 || discountPrc >= 100 ? null : {
    size = [SIZE_TO_CONTENT, height]
    rendObj = ROBJ_9RECT
    image = Picture($"ui/gameuiskin#tag_popular.svg:{height}:{height}:P")
    screenOffs = markTexOffs
    texOffs = markTexOffs
    color = 0xFFD22A19
    children = {
      rendObj = ROBJ_TEXT
      text = $"-{round(discountPrc)}%"
      color = 0xFFFFFFFF
    }.__update(fontTinyShaded, ovr)
  }
}

return {
  discountOfferTagH

  discountTag
  discountTagBig
  discountTagOffer
  discountTagUnit = @(discount)
    discountTagUnitCtor(discount, hdpxi(42), { margin = const [0, hdpx(30), 0, hdpx(15)] pos = [0, hdpx(3)] }.__update(fontTinyShaded))
  discountTagUnitBig = @(discount)
    discountTagUnitCtor(discount, hdpxi(60), { margin = const [0, hdpx(40), 0, hdpx(20)] pos = [0, hdpx(5)] }.__update(fontSmallShaded))
  discountTagUnitSmall = @(discount)
    discountTagUnitCtor(discount, hdpxi(36), { margin = const [0, hdpx(15), 0, hdpx(5)] pos = [0, hdpx(3)] }.__update(fontVeryTinyAccentedShaded))
}