from "%globalsDarg/darg_library.nut" import *
let { inspectorToggle } = require("%darg/helpers/inspector.nut")
let { register_command } = require("console")
let { round } =  require("math")
let { format } =  require("string")
let { hexStringToInt } = require("%sqstd/string.nut")

register_command(@() inspectorToggle(), "ui.inspector")

register_command(function(colorStr, multiplier) {
  if (type(colorStr) != "string" || (colorStr.len() != 8 && colorStr.len() != 6))
    return log("first param must be string with len 6 or 8")
  if ((type(multiplier) != "float" && type(multiplier) != "integer") || multiplier < 0)
    return log("second param must be numeric > 0")

  let colorInt = hexStringToInt(colorStr)
  let a = round(min(255, multiplier * (colorStr.len() == 8 ? ((colorInt & 0xFF000000) >> 24) : 255))).tointeger()
  let r = round(min(255, multiplier * ((colorInt & 0xFF0000) >> 16))).tointeger()
  let g = round(min(255, multiplier * ((colorInt & 0xFF00) >> 8))).tointeger()
  let b = round(min(255, multiplier * (colorInt & 0xFF))).tointeger()
  let resColor = (a << 24) + (r << 16) + (g << 8) + b
  log(format("color = 0x%X, Color(%d, %d, %d, %d)", resColor, r, g, b, a))
}, "debug.multiply_color")