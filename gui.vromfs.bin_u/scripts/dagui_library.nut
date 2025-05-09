from "math" import max, min, clamp
require("%sqstd/globalState.nut").setUniqueNestKey("dagui")
let { kwarg } = require("%sqstd/functools.nut")
let { Computed, Watched, WatchedRo } = require("%sqstd/frp.nut")
let log = require("%globalScripts/logs.nut")
let mkWatched = require("%globalScripts/mkWatched.nut")
let { loc } = require("dagor.localize")
let getTblValue = @(key, tbl, defValue = null) key in tbl ? tbl[key] : defValue
let isInArray = @(v, arr) arr.contains(v)
let utf8 = require("utf8")

function colorize(color, text) {
  if (color == "" || text == "")
    return text
  return "".concat("<color=", color, ">", text, "</color>")
}

let screen_width = getroottable()?["screen_width"] ?? @() 1920
let screen_height = getroottable()?["screen_height"] ?? @() 1080

return log.__merge({
  max
  min
  clamp
  screen_width
  screen_height
  colorize
  loc
  getTblValue
  isInArray
  utf8
  
  Watched
  Computed
  mkWatched
  WatchedRo

  
  kwarg
})
