from "%globalsDarg/darg_library.nut" import *
from "%globalsDarg/interop.nut" import registerInteropFunc
import "%rGui/interopGen.nut" as interopGen
from "%rGui/radar/radarState.nut" import showRadarOverMap, IsRadarVisible


let compassState = {
  CompassValue = Watched(0)
  isCompassVisible = Computed(@() IsRadarVisible.get() && !showRadarOverMap.get())
}
let azimuthMarkers = Watched({})

interopGen({
  stateTable = compassState
  prefix = "compass"
  postfix = "Update"
})

compassState.isCompassVisible.subscribe(@(_) azimuthMarkers.mutate(@(v) v.clear()))

registerInteropFunc("resetTargetsFlags", function() {
  azimuthMarkers.mutate(function(markers) {
    foreach (k in markers.keys())
      if (markers[k].isUpdated)
        markers[k] = markers[k].__merge({ isUpdated = false })
  })
})

registerInteropFunc("updateAzimuthMarker", function(id, target_time, age_rel, azimuth_world_deg, is_selected, is_detected, is_enemy) {
  let existingMarker = azimuthMarkers.get()?[id]
  if (existingMarker != null && target_time + 0.001 <= existingMarker.targetTime)
    return
  azimuthMarkers.mutate(@(v) v[id] <- {
    azimuthWorldDeg = azimuth_world_deg
    targetTime = target_time
    ageRel = age_rel
    isSelected = is_selected
    isDetected = is_detected
    isEnemy = is_enemy
    isUpdated = true
  })
})

registerInteropFunc("clearUnusedTargets", function() {
  let unusedMarkers = []
  foreach (id, marker in azimuthMarkers.get())
    if (!marker.isUpdated)
      unusedMarkers.append(id)
  if (unusedMarkers.len() == 0)
    return
  azimuthMarkers.mutate(function(v) {
    foreach (id in unusedMarkers)
      v.$rawdelete(id)
  })
})

return compassState.__merge({
  azimuthMarkers
})
