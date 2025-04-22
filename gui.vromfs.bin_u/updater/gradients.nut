from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPicture, setMaxCachedSize } = require("%darg/helpers/bitmap.nut")

setMaxCachedSize(max(sw(15) * sh(15), 128 * 128))

let gradTexSize = 64
let colorParts = @(color) {
  r = (color >> 16) & 0xFF
  g = (color >> 8) & 0xFF
  b = color & 0xFF
  a = (color >> 24) & 0xFF
}
let partsToColor = @(c) Color(c.r, c.g, c.b, c.a)

let lerpColorParts = @(c1, c2, value) value <= 0 ? c1
  : value >= 1 ? c2
  : c1.map(@(v1, k) v1 + ((c2[k] - v1) * value + 0.5).tointeger())

let mkGradientCtorDoubleSideX = @(color1, color2, middle = 0.4) function(params, bmp) {
  let { w, h } = params
  let c1 = colorParts(color1)
  let c2 = colorParts(color2)
  for (local x = 0; x < w; x++) {
    let rel = x.tofloat() / (w - 1)
    let v = rel < middle ? rel / middle
      : rel > 1.0 - middle ? (1.0 - rel) / middle
      : 1.0
    let color = partsToColor(lerpColorParts(c1, c2, v))
    for (local y = 0; y < h; y++)
      bmp.setPixel(x, y, color)
  }
}

let gradTranspDoubleSideX = mkBitmapPicture(gradTexSize, 4, mkGradientCtorDoubleSideX(0, 0xFFFFFFFF))

let mkColoredGradientY = @(colorTop, colorBottom, height = 12)
  mkBitmapPicture(4, height,
    function(params, bmp) {
      let { w, h } = params
      let c1 = colorParts(colorBottom)
      let c2 = colorParts(colorTop)
      for (local y = 0; y < h; y++) {
        let color = partsToColor(lerpColorParts(c1, c2, y.tofloat() / (h - 1)))
        for (local x = 0; x < w; x++)
          bmp.setPixel(x, y, color)
      }
    })

return {
  
  gradTexSize
  gradDoubleTexOffset = (0.5 * gradTexSize).tointeger() - 2
  
  gradTranspDoubleSideX
  
  mkGradientCtorDoubleSideX
  mkColoredGradientY
}