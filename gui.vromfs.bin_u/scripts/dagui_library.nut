
let { kwarg } = require("%sqstd/functools.nut")
let { Computed, Watched } = require("frp")
let log = require("%globalScripts/logs.nut")
let mkWatched = require("%globalScripts/mkWatched.nut")
let { debugTableData, toString } = require("%sqStdLibs/helpers/toString.nut")
let { loc } = require("dagor.localize")
let getTblValue = @(key, tbl, defValue = null) key in tbl ? tbl[key] : defValue
let isInArray = @(v, arr) arr.contains(v)
let utf8 = require("utf8")

let function colorize(color, text) {
  if (color == "" || text == "")
    return text
  return "".concat("<color=", color, ">", text, "</color>")
}


return log.__merge({
  debugTableData
  colorize
  toString
  loc
  getTblValue
  isInArray
  utf8
  //frp
  Watched
  Computed
  mkWatched

  //function tools
  kwarg
})
