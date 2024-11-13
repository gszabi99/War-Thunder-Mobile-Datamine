let { sw, sh } = require("daRg")
let { round } =  require("math")

let HDPX_H = 1080

let minScreenRatio = 16.0 / 9.0
let swMul = 1.0 / minScreenRatio
let swMulPrc = swMul * 100
let canScaleBySh = sh(100) <= sw(swMulPrc)

let hdpx = canScaleBySh
  ? @(pixels) sh(100.0 * pixels / HDPX_H)
  : @(pixels) sw(swMulPrc * pixels / HDPX_H)
let notZero = @(basePx, resPx) resPx != 0 || basePx == 0 ? resPx
  : basePx > 0 ? 1
  : -1
let hdpxi = @(px) notZero(px, hdpx(px).tointeger())
let evenPx = @(px) notZero(px, hdpx(px / 2.0).tointeger() * 2)
let oddPx = @(px) notZero(px, 1 + hdpx((px - 1) / 2.0).tointeger() * 2)
let fsh = canScaleBySh ? sh : @(v) sw(swMul * v)
let shHud = @(value) (fsh(value)).tointeger()

let scaleEven = @(px, scale) notZero(px, 2 * round(0.5 * px * scale).tointeger())

return {
  hdpx
  hdpxi
  evenPx
  oddPx
  fsh
  shHud
  scaleEven
}
