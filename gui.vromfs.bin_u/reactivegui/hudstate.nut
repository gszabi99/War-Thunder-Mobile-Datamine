from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
require("%rGui/onlyAfterLogin.nut")
let { register_command } = require("console")
let { round } =  require("math")
let { setDrawNativeAirCrosshair, setDrawNativeHitIndicator } = require("hudState")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let interopGet = require("interopGen.nut")
let { battleUnitName } = require("%appGlobals/clientState/clientState.nut")
let { DM_TEST_EMPTY } = require("crosshair")
let isAppLoaded = require("%globalScripts/isAppLoaded.nut")

let hudStateNative = {
  playerUnitName = ""
  targetUnitName = ""
  unitType = ""
  playerArmyForHud = -1
  isPlayingReplay = false
  isInSpectatorMode = false
  isInArtilleryMap = false
  isInStrategyMode = false
  isInAntiairMode = false
  hasTarget = false
  hasTargetCandidate = false
  groupAttack = false
  targetState = 0
  torpedoDistToLive = 0
  canZoom = false
  isInZoom = false
  isTrackingActive = false
  isFreeCamera = false
  zoomMult = 1.0
  playerRoundKills = 0
  playerAiRoundKills = 0
  tankCrosshairColor = 0xFFFFFFFF
  tankCrosshairDmTestResult = DM_TEST_EMPTY
  aircraftCrosshairColor = 0xFFFFFFFF
  tankZoomAutoAimMode = false
  isUnitDelayed = false
  isUnitAlive = false
  inKillZone = false
  groupIsInAir = false
  group2IsInAir = false
  group3IsInAir = false
  group4IsInAir = false
  threatRockets = []
  hasCountermeasures = false
  repairAssistAllow = 0
}.map(@(val, key) mkWatched(persist, key, val))

interopGet({
  stateTable = hudStateNative
  prefix = "hud"
  postfix = "Update"
})

let nativeToUnitType = {
  aircraft = AIR
  helicopter = HELICOPTER
  tank = TANK
  ship = SHIP
  shipEx = SUBMARINE
}

let nativeUnitType = hudStateNative.unitType
let unitType = Computed(@() nativeToUnitType?[nativeUnitType.value])

let { playerUnitName } = hudStateNative
let hudUnitType = Computed(@() playerUnitName.get() == "" ? unitType.get()
  : getUnitType(playerUnitName.get()))

let isUnitDelayedNative = hudStateNative.isUnitDelayed
let forceDelayed = mkWatched(persist, "forceDelayed", false)
let areHintsHidden = mkWatched(persist, "areHintsHidden", false)
let areSightHidden = mkWatched(persist, "areSightHidden", false)
let isUnitDelayed = Computed(@() isUnitDelayedNative.value || forceDelayed.value)
register_command(@() forceDelayed(!forceDelayed.value), "debug.hud.isUnitDelayed")

playerUnitName.subscribe(@(v) (v ?? "") != "" ? battleUnitName(v) : null)

isUnitDelayed.subscribe(@(v) v ? null : anim_start("unitDelayFinished"))

let HM_COMMON = 0x001
let HM_MANUAL_ANTIAIR = 0x002

let isInAntiairMode = hudStateNative.isInAntiairMode
let hudMode = Computed(@() isInAntiairMode.value ? HM_MANUAL_ANTIAIR : HM_COMMON)

let aircraftCrosshairColorNative = hudStateNative.aircraftCrosshairColor
let aircraftCrosshairColor = Computed(function() {
  local res = aircraftCrosshairColorNative.get()
  if ((res & 0xFF000000) == 0xFF000000)
    return res
  let mul = ((res & 0xFF000000) >> 24) / 255.0
  let r = round(mul * ((res & 0xFF0000) >> 16)).tointeger()
  let g = round(mul * ((res & 0xFF00) >> 8)).tointeger()
  let b = round(mul * (res & 0xFF)).tointeger()
  return (res & 0xFF000000) + (r << 16) + (g << 8) + b
})

setDrawNativeAirCrosshair(false)
setDrawNativeHitIndicator(false)
isAppLoaded.subscribe(function(_) {
  setDrawNativeAirCrosshair(false)
  setDrawNativeHitIndicator(false)
})

return hudStateNative.__merge({
  areHintsHidden
  areSightHidden
  unitType
  hudUnitType
  isUnitDelayed
  hudMode
  HM_COMMON
  HM_MANUAL_ANTIAIR
  aircraftCrosshairColor
})
