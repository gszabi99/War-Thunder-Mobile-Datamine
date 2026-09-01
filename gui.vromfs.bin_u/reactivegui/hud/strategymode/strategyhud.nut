from "%globalsDarg/darg_library.nut" import *
from "%globalScripts/controls/shortcutActions.nut" import toggleShortcut
from "%rGui/components/backButton.nut" import backButton
from "%rGui/hud/components/tacticalMap.nut" import tacticalMap
from "%rGui/hud/hitCamera/hitCamera.nut" import hitCamera
import "%rGui/hud/strategyMode/airGroupsView.nut" as airGroupsUi
from "%rGui/hud/strategyMode/strategyPathInput.nut" import pathInputUi
from "%rGui/hud/strategyMode/strategyPathView.nut" import pathNodesUi, pathCommandsUi
from "%rGui/hud/strategyMode/strategyState.nut" import strategyStateUpdateStart, strategyStateUpdateStop
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


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
  size = FLEX
  children = [
    pathInputUi
    pathNodesUi
    {
      size = FLEX
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
