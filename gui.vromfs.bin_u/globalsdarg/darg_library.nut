from "daRg" import *
from "math" import max, min, clamp

if (require_optional("json") != null) //no json module in the updater, and no need globalState in it.
  require("%sqstd/globalState.nut").setUniqueNestKey("darg")
let log = require("%globalScripts/logs.nut")
let { loc } = require("dagor.localize")
let dargBaseLib = require("%darg/darg_library.nut")
let screenUnits = require("screenUnits.nut")
let { safeArea } = require("%appGlobals/safeArea.nut")
let fontsStyle = require("fontsStyle.nut")

let colorArr = @(color) [(color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF, (color >> 24) & 0xFF]

let saBorders = [
  (sw((1.0 - safeArea) * 100) / 2).tointeger(),
  (sh((1.0 - safeArea) * 100) / 2).tointeger()
]
let saSize = [sw(100), sh(100)].map(@(v, i) v.tointeger() - 2 * saBorders[i])
let saBordersRv = [saBorders[1], saBorders[0]]

let appearAnim = @(delay, duration) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true }
  { prop = AnimProp.opacity, from = 0, to = 1, delay, duration, easing = OutQuad, play = true }
]

let Layers = freeze({
  Default = 0
  Upper = 1
  Tooltip = 2
  Inspector = 3
})

return dargBaseLib.__merge(
  log
  screenUnits
  fontsStyle
  require("daRg")
  require("frp")
  require("%sqstd/functools.nut")
{
  max
  min
  clamp
  loc
  //darg helpers
  colorArr
  appearAnim
  Layers
  defMarqueeDelay = [5, 1]

  //safeArea
  safeArea
  saSize
  saBorders
  saBordersRv //for paddings and margin
  saRatio = saSize[0].tofloat() / saSize[1]
  isWidescreen = (saSize[0].tofloat() / saSize[1]) >= 1.92

  //text helper
  colon = loc("ui/colon")
  comma = loc("ui/comma")
  ndash = loc("ui/ndash")
  colorize = @(color, text) text == "" || color == null ? text : $"<color={color}>{text}</color>"
  nbsp = "\u00A0" // Non-breaking space char

  TOUCH_BACKGROUND = -10
  TOUCH_MINOR = -1
})
