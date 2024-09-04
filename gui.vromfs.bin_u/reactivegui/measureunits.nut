from "%globalsDarg/darg_library.nut" import *
let { round_by_value, round } = require("%sqstd/math.nut")

let rangeSeparator = " - "

let getMassText = @(mass) mass < 1 ? "".concat((1000 * mass).tointeger(), loc("measureUnits/gr"))
  : "".concat(round_by_value(mass, 0.01), loc("measureUnits/kg"))

let getMassLbsText = @(massLbs) "".concat(round_by_value(massLbs, 0.1), loc("measureUnits/lbs"))

let getSpeedText = @(speed) "".concat(round(speed * 3.6), loc("measureUnits/kmh"))

let getSpeedRangeText = @(speed1, speed2) speed1 == speed2 ? getSpeedText(speed1)
  : "".concat(round(speed1 * 3.6), rangeSeparator, round(speed2 * 3.6), loc("measureUnits/kmh"))

let getHeightText = @(height) "".concat(round(height), loc("measureUnits/meters_alt"))

let getHeightRangeText = @(height1, height2) height1 == height2 ? getSpeedText(height1)
  : "".concat(round(height1), rangeSeparator, round(height2), loc("measureUnits/meters_alt"))

let getDistanceText = @(distance) distance < 1000
  ? "".concat(round(distance), loc("measureUnits/meters_alt"))
  : "".concat(round_by_value(0.001 * distance, 0.1), loc("measureUnits/km_dist"))

return {
  getMassText
  getMassLbsText
  getSpeedText
  getSpeedRangeText
  getHeightText
  getHeightRangeText
  getDistanceText
}