from "%globalsDarg/darg_library.nut" import *
from "%globalsDarg/interop.nut" import registerInteropFunc
import "%rGui/interopGen.nut" as interopGen


let radarState = {
  IsRadarVisible = Watched(false)
  IsRadar2Visible = Watched(false)
  IsRadarHudVisible = Watched(false)
  targetAspectEnabled = Watched(false)
  currentTime = Watched(0.0)
  SelectedTargetBlinking = Watched(false)
  SelectedTargetSpeedBlinking = Watched(false)
  IsBScopeVisible = Watched(false)
  showRadarOverMap = Watched(false)

  IsForestallVisible = Watched(false)
  ForestallX = Watched(0.0)
  ForestallY = Watched(0.0)
  SelectedTargetX = Watched(0.0)
  SelectedTargetY = Watched(0.0)
}

registerInteropFunc("updateForestall", function(x, y) {
  radarState.ForestallX.set(x)
  radarState.ForestallY.set(y)
})

registerInteropFunc("updateSelectedTarget", function(x, y) {
  radarState.SelectedTargetX.set(x)
  radarState.SelectedTargetY.set(y)
})

interopGen({
  stateTable = radarState
  prefix = "radar"
  postfix = "Update"
})

return radarState
