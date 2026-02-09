from "%globalsDarg/darg_library.nut" import *

let interopGen = require("%rGui/interopGen.nut")
let { showRadarOverMap, IsRadarVisible } = require("%rGui/radar/radarState.nut")
let { registerInteropFunc } = require("%globalsDarg/interop.nut")

let compassState = {
  CompassValue = Watched(0)
  isCompassVisible = Computed(@() IsRadarVisible.get() && !showRadarOverMap.get())
  azimuthMarkersTrigger = Watched(0)
  azimuthMarkers = {}
  targetIds = []
}

interopGen({
  stateTable = compassState
  prefix = "compass"
  postfix = "Update"
})

compassState.isCompassVisible.subscribe(@(_) compassState.azimuthMarkers.clear())

registerInteropFunc("updateAzimuthMarker", function(id, target_time, age_rel, azimuth_world_deg, is_selected, is_detected, is_enemy) {
  if (!compassState.azimuthMarkers)
    compassState.azimuthMarkers = {}

  if (!compassState.azimuthMarkers?[id]) {
    compassState.targetIds.append(id)
    compassState.azimuthMarkers[id] <- {
      azimuthWorldDeg = azimuth_world_deg
      targetTime = target_time
      ageRel = age_rel
      isSelected = is_selected
      isDetected = is_detected
      isEnemy = is_enemy
      isUpdated = true
    }
  }
  else if (target_time + 0.001 > compassState.azimuthMarkers[id].targetTime) {
    let marker = compassState.azimuthMarkers[id]
    marker.azimuthWorldDeg = azimuth_world_deg
    marker.isSelected = is_selected
    marker.targetTime = target_time
    marker.ageRel = age_rel
    marker.isDetected = is_detected
    marker.isEnemy = is_enemy
    marker.isUpdated = true
  }
  else
    return

  compassState.azimuthMarkersTrigger.trigger()
})

registerInteropFunc("resetTargetsFlags", function() {
  foreach (marker in compassState.azimuthMarkers)
    if (marker)
      marker.isUpdated = false
})

registerInteropFunc("clearUnusedTargets", function() {
  local needUpdate = false
  foreach (id, marker in compassState.azimuthMarkers)
    if (marker && !marker.isUpdated) {
      compassState.azimuthMarkers[id] = null
      needUpdate = true
    }
  if (needUpdate)
    compassState.azimuthMarkersTrigger.trigger()
})

return compassState
