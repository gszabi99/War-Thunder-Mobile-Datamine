from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")
let { abTests } = require("%appGlobals/pServer/campaign.nut")

let CTRL_TYPE_STICK = "stick"
let CTRL_TYPE_ARROWS = "arrows"

let ctrlTypeInv = {
  [CTRL_TYPE_STICK] = CTRL_TYPE_ARROWS,
  [CTRL_TYPE_ARROWS] = CTRL_TYPE_STICK,
}

let cfgDefaultValue = Computed(@() abTests.value?.controlsTypeDefault ?? CTRL_TYPE_STICK)
let cfgNeedRecommend = Computed(@() (abTests.value?.controlsTypeRecommend ?? "true") == "true")

let dbgDefaultValueInvert = mkHardWatched("dbgDefaultValueInvert", false)
let dbgNeedRecommendInvert = mkHardWatched("dbgNeedRecommendInvert", false)

let defaultValue = Computed(@() dbgDefaultValueInvert.value ? ctrlTypeInv[cfgDefaultValue.value] : cfgDefaultValue.value)
let needRecommend = Computed(@() cfgNeedRecommend.value != dbgNeedRecommendInvert.value)

register_command(function() {
  dbgDefaultValueInvert(!dbgDefaultValueInvert.value)
  dlog("controlsTypeDefault:", defaultValue.value) // warning disable: -forbidden-function
}, "debug.abTests.controlsTypeDefault")

register_command(function() {
  dbgNeedRecommendInvert(!dbgNeedRecommendInvert.value)
  dlog("controlsTypeRecommend:", needRecommend.value) // warning disable: -forbidden-function
}, "debug.abTests.controlsTypeRecommend")

return {
  defaultValue
  needRecommend
}
