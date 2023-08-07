from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { abTests } = require("%appGlobals/pServer/campaign.nut")

let arrBattlesMin = [ 2, 0 ]
let arrKillsMin = [ 2, 0 ]
let arrPlaceMax = [ 99, 3 ]

let cfgBattlesMin = Computed(@() abTests.value?.reviewCueBattlesMin.tointeger() ?? arrBattlesMin[0])
let cfgKillsMin = Computed(@() abTests.value?.reviewCueKillsMin.tointeger() ?? arrKillsMin[0])
let cfgPlaceMax = Computed(@() abTests.value?.reviewCuePlaceMax.tointeger() ?? arrPlaceMax[0])
let cfgReqVictory = Computed(@() (abTests.value?.reviewCueReqVictory ?? "true") == "true")
let cfgReqMultiplayer = Computed(@() (abTests.value?.reviewCueReqMultiplayer ?? "true") == "true")
let cfgReqNoExtraScenes = Computed(@() (abTests.value?.reviewCueReqNoExtraScenes ?? "true") == "true")

let dbgBattlesMinShift = hardPersistWatched("dbgBattlesMinShift", 0)
let dbgKillsMinShift = hardPersistWatched("dbgKillsMinShift", 0)
let dbgPlaceMaxShift = hardPersistWatched("dbgPlaceMaxShift", 0)
let dbgReqVictory = hardPersistWatched("dbgReqVictory", false)
let dbgReqMultiplayer = hardPersistWatched("dbgReqMultiplayer", false)
let dbgReqNoExtraScenes = hardPersistWatched("dbgReqNoExtraScenes", false)

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
let reqVictory = Computed(@() cfgReqVictory.value != dbgReqVictory.value)
let reqMultiplayer = Computed(@() cfgReqMultiplayer.value != dbgReqMultiplayer.value)
let reqNoExtraScenes = Computed(@() cfgReqNoExtraScenes.value != dbgReqNoExtraScenes.value)

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

register_command(function() {
  dbgReqVictory(!dbgReqVictory.value)
  dlog("reviewCueReqVictory:", dbgReqVictory.value) // warning disable: -forbidden-function
}, "debug.abTests.reviewCueReqVictory")

register_command(function() {
  dbgReqMultiplayer(!dbgReqMultiplayer.value)
  dlog("reviewCueReqMultiplayer:", dbgReqMultiplayer.value) // warning disable: -forbidden-function
}, "debug.abTests.reviewCueReqMultiplayer")

register_command(function() {
  dbgReqNoExtraScenes(!dbgReqNoExtraScenes.value)
  dlog("reviewCueReqNoExtraScenes:", dbgReqNoExtraScenes.value) // warning disable: -forbidden-function
}, "debug.abTests.reviewCueReqNoExtraScenes")

let isTestingBattlesMin = Computed(@() (abTests.value?.reviewCueBattlesMin ?? "0") != "0")

return {
  battlesMin
  killsMin
  placeMax
  reqVictory
  reqMultiplayer
  reqNoExtraScenes
  isTestingBattlesMin
}
