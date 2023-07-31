from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")
let { abTests } = require("%appGlobals/pServer/campaign.nut")

let CTRL_TYPE_STICK = "stick"
let CTRL_TYPE_STICK_STATIC = "stick_static"
let CTRL_TYPE_ARROWS = "arrows"

let ctrlTypesList = [ CTRL_TYPE_STICK_STATIC, CTRL_TYPE_STICK, CTRL_TYPE_ARROWS ]
let typesTotal = ctrlTypesList.len()

let cfgDefaultValue = Computed(@() abTests.value?.controlsTypeDefault ?? CTRL_TYPE_STICK_STATIC)
let cfgNeedRecommend = Computed(@() (abTests.value?.controlsTypeRecommend ?? "true") == "true")
let cfgNeedForceShow = Computed(@() (abTests.value?.controlsTypeForceShow ?? "true") == "true")

let dbgDefaultValueShift = mkHardWatched("dbgDefaultValueShift", 0)
let dbgNeedRecommend = mkHardWatched("dbgNeedRecommend", false)
let dbgNeedForceShow = mkHardWatched("dbgNeedForceShow", false)

let defaultValue = Computed(@() dbgDefaultValueShift.value == 0
  ? cfgDefaultValue.value
  : ctrlTypesList[((ctrlTypesList.indexof(cfgDefaultValue.value) ?? 0) + dbgDefaultValueShift.value) % typesTotal]
)
let needRecommend = Computed(@() cfgNeedRecommend.value != dbgNeedRecommend.value)
let needForceShow = Computed(@() cfgNeedForceShow.value != dbgNeedForceShow.value)

register_command(function() {
  dbgDefaultValueShift((dbgDefaultValueShift.value + 1) % typesTotal)
  dlog("controlsTypeDefault:", defaultValue.value) // warning disable: -forbidden-function
}, "debug.abTests.controlsTypeDefault")

register_command(function() {
  dbgNeedRecommend(!dbgNeedRecommend.value)
  dlog("controlsTypeRecommend:", needRecommend.value) // warning disable: -forbidden-function
}, "debug.abTests.controlsTypeRecommend")

register_command(function() {
  dbgNeedForceShow(!dbgNeedForceShow.value)
  dlog("controlsTypeForceShow:", needForceShow.value) // warning disable: -forbidden-function
}, "debug.abTests.controlsTypeForceShow")

return {
  defaultValue
  needRecommend
  needForceShow
}
