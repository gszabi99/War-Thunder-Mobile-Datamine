from "%globalsDarg/darg_library.nut" import *
let interopGen = require("%rGui/interopGen.nut")
let { registerInteropFunc } = require("%globalsDarg/interop.nut")

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
}

let forestall = {
  x = 0.0
  y = 0.0
}
let selectedTarget = {
  x = 0.0
  y = 0.0
}
let IsForestallVisible = Watched(false)

registerInteropFunc("updateForestall", function(x, y) {
  forestall.x = x
  forestall.y = y
})

registerInteropFunc("updateSelectedTarget", function(x, y) {
  selectedTarget.x = x
  selectedTarget.y = y
})

radarState.__update({
  IsForestallVisible, forestall, selectedTarget
})



interopGen({
  stateTable = radarState
  prefix = "radar"
  postfix = "Update"
})

return radarState