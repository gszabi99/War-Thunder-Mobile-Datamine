from "daRg" import sw, sh
from "math" import round


const HDPX_H = 1080

const minScreenRatio = 16.0 / 9.0
const swMul = 1.0 / minScreenRatio
const swMulPrc = swMul * 100
const canScaleBySh = sh(100) <= sw(swMulPrc)

let hdpx = canScaleBySh
  ? @[pure, nodiscard](pixels) sh(100.0 * pixels / HDPX_H)
  : @[pure, nodiscard](pixels) sw(swMulPrc * pixels / HDPX_H)

let notZero = @[pure, nodiscard](basePx, resPx) resPx != 0 || basePx == 0 ? resPx
  : basePx > 0 ? 1
  : -1

let hdpxi = @[pure, nodiscard](px) notZero(px, hdpx(px).tointeger())
let evenPx = @[pure, nodiscard](px) notZero(px, hdpx(px / 2.0).tointeger() * 2)
let oddPx = @[pure, nodiscard](px) notZero(px, 1 + hdpx((px - 1) / 2.0).tointeger() * 2)
let fsh = canScaleBySh ? sh : @[pure, nodiscard](v) sw(swMul * v)
let shHud = @[pure, nodiscard](value) (fsh(value)).tointeger()

let scaleEven = @[pure, nodiscard](px, scale) notZero(px, 2 * round(0.5 * px * scale).tointeger())

return {
  hdpx
  hdpxi
  evenPx
  oddPx
  fsh
  shHud
  scaleEven
}
