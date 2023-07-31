from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { register_command } = require("console")
let interopGet = require("interopGen.nut")
let { isDmgIndicatorVisible } = require("gameplayBinding")
let { battleUnitName } = require("%appGlobals/clientState/clientState.nut")
let { DM_TEST_EMPTY } = require("crosshair")

let hudStateNative = {
  playerUnitName = ""
  targetUnitName = ""
  unitType = ""
  playerArmyForHud = -1
  isPlayingReplay = false
  isInSpectatorMode = false
  isInArtilleryMap = false
  isVisibleDmgIndicator = isDmgIndicatorVisible()
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
  tankCrosshairColor = Color(255, 255, 255)
  tankCrosshairDmTestResult = DM_TEST_EMPTY
  tankZoomAutoAimMode = false
  isUnitDelayed = false
  isUnitAlive = false
  inKillZone = false
  groupIsInAir = false
  group2IsInAir = false
  group3IsInAir = false
  group4IsInAir = false
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

let isUnitDelayedNative = hudStateNative.isUnitDelayed
let forceDelayed = mkWatched(persist, "forceDelayed", false)
let isUnitDelayed = Computed(@() isUnitDelayedNative.value || forceDelayed.value)
register_command(@() forceDelayed(!forceDelayed.value), "debug.hud.isUnitDelayed")

hudStateNative.playerUnitName.subscribe(@(v) (v ?? "") != "" ? battleUnitName(v) : null)

isUnitDelayed.subscribe(@(v) v ? null : anim_start("unitDelayFinished"))

return hudStateNative.__merge({
  unitType
  isUnitDelayed
})
