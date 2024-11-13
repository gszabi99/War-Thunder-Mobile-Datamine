from "%globalsDarg/darg_library.nut" import *

let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { tacticalMap } = require("%rGui/hud/components/tacticalMap.nut")
let { strategyStateUpdateStart, strategyStateUpdateStop } = require("%rGui/hud/strategyMode/strategyState.nut")
let { pathInputUi } = require("%rGui/hud/strategyMode/strategyPathInput.nut")
let { pathNodesUi, pathCommandsUi } = require("%rGui/hud/strategyMode/strategyPathView.nut")
let { hitCamera } = require("%rGui/hud/hitCamera/hitCamera.nut")
let airGroupsUi = require("%rGui/hud/strategyMode/airGroupsView.nut")

let areaTopLeft = {
  flow = FLOW_HORIZONTAL
  gap = hdpx(40)
  children = [
    backButton(@() toggleShortcut("ID_SHIP_STRATEGY_MODE_BACK"))
    tacticalMap
  ]
}

let areaTopBottom = {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  gap = hdpx(40)
  children = hitCamera(1)
}

let areaBottomLeft = @() {
  vplace = ALIGN_BOTTOM
  children = pathCommandsUi
}

let areaBottomRight = {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = hdpx(40)
  children = airGroupsUi
}

return {
  size = flex()
  children = [
    pathInputUi
    pathNodesUi
    {
      size = flex()
      padding = saBordersRv
      children = [
        areaTopLeft
        areaTopBottom
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
