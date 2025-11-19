from "daRg" import *
from "math" import max, min, clamp
if (require_optional("json") != null) 
  require("%sqstd/globalState.nut").setUniqueNestKey("darg")
let log = require("%globalScripts/logs.nut")
let { loc } = require("dagor.localize")
let dargBaseLib = require("%darg/darg_library.nut")
let { getSubArray, getSubTable } = require("%sqstd/underscore.nut")
let screenUnits = require("screenUnits.nut")
let { safeAreaW, safeAreaH } = require("%appGlobals/safeArea.nut")
let fontsStyle = require("fontsStyle.nut")

let colorArr = @(color) [(color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF, (color >> 24) & 0xFF]

let saBorders = [
  (sw((1.0 - safeAreaW) * 100) / 2).tointeger(),
  (sh((1.0 - safeAreaH) * 100) / 2).tointeger()
]
let saSize = [sw(100), sh(100)].map(@(v, i) v.tointeger() - 2 * saBorders[i])
let saBordersRv = [saBorders[1], saBorders[0]]

let saRatio = saSize[0].tofloat() / saSize[1]

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

let XmbContainer = @(ovr = {}) {
  canFocus = false
  scrollSpeed = 2
  isViewport = true
  scrollToEdge = false
  screenSpaceNav = true
  wrap = false
}.__update(ovr)

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
  getSubArray
  getSubTable

  
  colorArr
  appearAnim
  Layers
  defMarqueeDelay = [5, 0.3]
  defMarqueeDelayVert = [1, 2]

  
  safeAreaW
  safeAreaH
  saSize
  saBorders
  saBordersRv 
  saRatio
  isWidescreen = saRatio >= 1.92

  
  colon = loc("ui/colon")
  comma = loc("ui/comma")
  ndash = loc("ui/ndash")
  colorize = @(color, text) text == "" || color == null ? text : $"<color={color}>{text}</color>"
  nbsp = "\u00A0" 

  TOUCH_BACKGROUND = -10
  TOUCH_MINOR = -1

  XmbContainer
})
