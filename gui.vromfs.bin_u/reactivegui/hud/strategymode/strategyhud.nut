from "%globalsDarg/darg_library.nut" import *

let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { tacticalMap } = require("%rGui/hud/components/tacticalMap.nut")
let { strategyStateUpdateStart, strategyStateUpdateStop } = require("%rGui/hud/strategyMode/strategyState.nut")
let { setStrategyViewZoom } = require("guiStrategyMode")
let { pathNodesUi, pathCommandsUi } = require("%rGui/hud/strategyMode/strategyPathView.nut")
let airGroupsUi = require("%rGui/hud/strategyMode/airGroupsView.nut")

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//
// FIXME: This is temporaty solution to control camera zoom
// and must be removed in favor of implementing gestures support
//
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
let zoomFactor = Watched(0.5)
function mkZoomSlider() {
  let fValue = zoomFactor.value
  let minVal = 0
  let maxVal = 1

  setStrategyViewZoom(zoomFactor.value)

  let knob = {
    size  = [flex(), hdpx(50)]
    rendObj = ROBJ_SOLID
    pos = [0, hdpx(-10)]
  }

  return {
    watch = zoomFactor
    flow = FLOW_VERTICAL
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    children = [
      {
        rendObj = ROBJ_TEXT
        halign = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        padding = hdpx(5)
        text = zoomFactor.value
      }
      {
        rendObj = ROBJ_SOLID
        behavior = Behaviors.Slider

        fValue = fValue

        knob = knob
        min = minVal
        max = maxVal
        unit = 0.1
        orientation = O_VERTICAL
        size = [hdpx(50), hdpx(250)]
        color = Color(0, 10, 20)
        flow = FLOW_VERTICAL

        children = [
          {
            size = [0, flex(maxVal - fValue)]
          }
          knob
          {
            rendObj = ROBJ_SOLID
            size = [hdpx(50), flex(fValue - minVal)]
            color = 0xFF808080
          }
        ]

        onChange = function(val) {
          zoomFactor(1 - val)
          setStrategyViewZoom(1 - val)
        }
      }
    ]
  }
}
// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

let areaTopLeft = {
  flow = FLOW_HORIZONTAL
  gap = hdpx(40)
  children = [
    backButton(@() toggleShortcut("ID_SHIP_STRATEGY_MODE_BACK"))
    tacticalMap
  ]
}

let areaBottomLeft = @() {
  vplace = ALIGN_BOTTOM
  children = airGroupsUi
}

let areaBottomRight = {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = hdpx(40)
  children = [
    mkZoomSlider
    pathCommandsUi
  ]
}

return {
  size = flex()
  children = [
    pathNodesUi
    {
      size = flex()
      padding = saBordersRv
      children = [
        areaTopLeft
        areaBottomLeft
        areaBottomRight
      ]
    }
  ]
  animations = wndSwitchAnim
  function onAttach() {
    strategyStateUpdateStart()
  }
  function onDetach() {
    strategyStateUpdateStop()
  }
}
