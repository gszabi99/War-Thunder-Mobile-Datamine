from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { sqrt, fabs } = require("math")

let getDistance = @(x, y) sqrt(x * x + y * y)

function mkWhite(partF) {
  let part = (0xFF * partF).tointeger()
  return part + (part << 8) + (part << 16) + (part << 24)
}

//cutRadius > 0 - cutFrom inner side.  cutRadius < 0 - cutFrom outher side
function mkLensFlareCutRadiusLeft(radius, outherWidth, innerWidth, cutRadius, cutWidth, cutOffset) {
  let center = radius + outherWidth + 1
  let cutCenter = cutRadius > 0 ? cutRadius + cutWidth : center + cutRadius
  let calcCutMul = cutRadius > 0
    ? function(x, y) {
        let distanceCut = getDistance(0.5 + x - cutCenter - cutOffset, 0.5 + y - center) - cutRadius
        if (distanceCut <= 0)
          return 0
        return cutWidth == 0 ? 1.0 : min(1.0, distanceCut / cutWidth)
      }
    : function(x, y) {
        let distanceCut = getDistance(0.5 + x - cutCenter - cutOffset, 0.5 + y - center) + cutRadius
        if (distanceCut >= 0)
          return 0
        return cutWidth == 0 ? 1.0 : min(1.0, -distanceCut / cutWidth)
      }

  return mkBitmapPictureLazy(center, center * 2,
    function(params, bmp) {
      let { w, h } = params
      for (local y = 0; y < h; y++)
        for (local x = 0; x < w; x++) {
          let cutMul = calcCutMul(x, y)
          if (cutMul == 0) {
            bmp.setPixel(x, y, 0)
            continue
          }
          let distance = getDistance(0.5 + x - center, 0.5 + y - center) - radius
          let mul = distance >= 0 ? distance / outherWidth : -distance / innerWidth
          bmp.setPixel(x, y, mkWhite(max(0.0, (1.0 - mul) * cutMul)))
        }
    })
}

let mkLensLine = @(width, height, middle = 0.4) mkBitmapPictureLazy(width, height,
  function(params, bmp) {
    let { w, h } = params
    let yMul = array(h).map(function(_, y) {
      let rel = fabs(2.0 * (0.5 - y.tofloat() / (h - 1)))
      return (1.0 - rel) * (1.0 - rel)
    })
    for (local x = 0; x < w; x++) {
      let rel = x.tofloat() / (w - 1)
      let xMul = rel < middle ? rel / middle
        : rel > 1.0 - middle ? (1.0 - rel) / middle
        : 1.0
      for (local y = 0; y < h; y++)
        bmp.setPixel(x, y, mkWhite(xMul * yMul[y]))
    }
  })

let lensLine = mkLensLine(64, 16)

return {
  mkLensFlareCutRadiusLeft
  lensLine
}