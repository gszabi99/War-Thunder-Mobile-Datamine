from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { abTests } = require("%appGlobals/pServer/campaign.nut")

let arrBattlesMin = [ 2, 5 ]
let arrKillsMin = [ 2, 0 ]
let arrPlaceMax = [ 99, 3 ]

let cfgBattlesMin = Computed(@() abTests.value?.reviewCueBattlesMin.tointeger() ?? arrBattlesMin[0])
let cfgKillsMin = Computed(@() abTests.value?.reviewCueKillsMin.tointeger() ?? arrKillsMin[0])
let cfgPlaceMax = Computed(@() abTests.value?.reviewCuePlaceMax.tointeger() ?? arrPlaceMax[0])

let dbgBattlesMinShift = hardPersistWatched("dbgBattlesMinShift", 0)
let dbgKillsMinShift = hardPersistWatched("dbgKillsMinShift", 0)
let dbgPlaceMaxShift = hardPersistWatched("dbgPlaceMaxShift", 0)

let battlesMin = Computed(@() dbgBattlesMinShift.value == 0
  ? cfgBattlesMin.value
  : arrBattlesMin[((arrBattlesMin.indexof(cfgBattlesMin.value) ?? 0) + dbgBattlesMinShift.value) % arrBattlesMin.len()]
)
let killsMin = Computed(@() dbgKillsMinShift.value == 0
  ? cfgKillsMin.value
  : arrKillsMin[((arrKillsMin.indexof(cfgKillsMin.value) ?? 0) + dbgKillsMinShift.value) % arrKillsMin.len()]
)
let placeMax = Computed(@() dbgPlaceMaxShift.value == 0
  ? cfgPlaceMax.value
  : arrPlaceMax[((arrPlaceMax.indexof(cfgPlaceMax.value) ?? 0) + dbgPlaceMaxShift.value) % arrPlaceMax.len()]
)

register_command(function() {
  dbgBattlesMinShift((dbgBattlesMinShift.value + 1) % arrBattlesMin.len())
  dlog("reviewCueBattlesMin:", battlesMin.value) // warning disable: -forbidden-function
}, "debug.abTests.reviewCueBattlesMin")

register_command(function() {
  dbgKillsMinShift((dbgKillsMinShift.value + 1) % arrKillsMin.len())
  dlog("reviewCueKillsMin:", killsMin.value) // warning disable: -forbidden-function
}, "debug.abTests.reviewCueKillsMin")

register_command(function() {
  dbgPlaceMaxShift((dbgPlaceMaxShift.value + 1) % arrPlaceMax.len())
  dlog("reviewCuePlaceMax:", placeMax.value) // warning disable: -forbidden-function
}, "debug.abTests.reviewCuePlaceMax")

let isTestingBattlesMin = Computed(@() abTests.value?.reviewCueBattlesMin != null)

return {
  battlesMin
  killsMin
  placeMax
  isTestingBattlesMin
}
