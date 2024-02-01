from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { touchButtonSize, borderWidth, btnBgColor, borderColor, borderNoAmmoColor,
      imageColor
    } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { shipDebuffs, crewHealth} = require("%rGui/hud/shipStateModule.nut")
let { actionBarItems, startActionBarUpdate, stopActionBarUpdate } = require("%rGui/hud/actionBar/actionBarState.nut")
let { AB_SUPPORT_PLANE, AB_SUPPORT_PLANE_2, AB_SUPPORT_PLANE_3 } = require("%rGui/hud/actionBar/actionType.nut")
let { strategyDataRest, curAirGroupIndex } = require("%rGui/hud/strategyMode/strategyState.nut")
let { getNodeStyle, airGroupIcons, iconShip } = require("%rGui/hud/strategyMode/style.nut")
let { NODE_SELF } = require("guiStrategyMode")

function mkPathNodeSmall(nodeType, nodeSize, isActive) {
  let { icon, color } = getNodeStyle(nodeType)
  let iconSize = (nodeSize * 0.75).tointeger()
  return {
    rendObj = ROBJ_BOX
    size = [nodeSize, nodeSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    borderColor = borderColor
    borderWidth = borderWidth
    fillColor = isActive ? btnBgColor.broken : btnBgColor.ready
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [iconSize, iconSize]
        image = Picture($"{icon}:{iconSize}:{iconSize}:P")
        color = isActive ? imageColor : color
        keepAspect = KEEP_ASPECT_FIT
      }
    ]
  }
}

function mkStrategyCommandsUi(data) {
  local i = 0
  local delimiterAdded = false
  let nodeSize = hdpxi(50)
  let nodeListUi = []
  foreach(node in data.nodes) {
    if(node.type != NODE_SELF) {
      if (i < 3 || (i + 2 >= data.nodes.len())) {
        nodeListUi.append(mkPathNodeSmall(node.type, nodeSize, (i == 0 && data.isLaunched)))
      }
      else if (!delimiterAdded) {
        delimiterAdded = true
        nodeListUi.append({
          halign = ALIGN_CENTER
          valign = ALIGN_BOTTOM
          rendObj = ROBJ_TEXT
          size = [nodeSize, nodeSize]
          text = "..."
        }.__update(fontSmall))
      }
      i++
    }
  }
  return nodeListUi
}

function mkPlaneUi(actionItem, airGroupIndex) {
  let airGroupData = Computed(@() strategyDataRest.value?[airGroupIndex] )
  return {
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = [
      {
        rendObj = ROBJ_TEXT
        text = utf8ToUpper(loc(actionItem.weaponName))
      }.__update(fontSmall)
      @() {
        watch = airGroupData
        flow = FLOW_HORIZONTAL
        gap = hdpx(7)
        children = airGroupData.value ? mkStrategyCommandsUi(airGroupData.value) : null
      }
    ]
  }
}

let shipUi = {
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  children = [
    shipDebuffs
    crewHealth
  ]
}

function mkUnitSelectable(selectableIndex, icon, unitUi, count, countEx) {
  let stateFlags = Watched(0)
  let isSelected = Computed(@() curAirGroupIndex.value == selectableIndex)
  let buttonSize = touchButtonSize
  let iconSize = ((count > 0) ? buttonSize * 0.65 : buttonSize * 0.85).tointeger()
  return @() {
    watch = [isSelected, stateFlags]
    size = [hdpx(450), SIZE_TO_CONTENT]
    vplace = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    rendObj = ROBJ_BOX
    borderColor = borderColor
    borderWidth = isSelected.value ? borderWidth : 0
    fillColor = isSelected.value ? Color(0, 15, 25, 30) : btnBgColor.empty
    padding = hdpx(10)
    gap =  hdpx(10)
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick = @() (selectableIndex >= 0) ? curAirGroupIndex(selectableIndex) : null // TODO: remove if when ships strategy commands will be supported
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = OutQuad }]
    children = [
      {
        rendObj = ROBJ_BOX
        size = [buttonSize, buttonSize]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        padding = hdpx(5)
        gap = hdpx(5)
        flow = FLOW_VERTICAL
        borderWidth = borderWidth
        borderColor = borderNoAmmoColor
        fillColor = btnBgColor.ready
        children = [
          {
            rendObj = ROBJ_IMAGE
            size = [iconSize, iconSize]
            image = Picture($"{icon}:{iconSize}:{iconSize}:P")
            keepAspect = KEEP_ASPECT_FIT
            color = imageColor
          }
          count == 0 ? null
          : {
            rendObj = ROBJ_TEXT
            size = flex()
            halign = ALIGN_CENTER
            valign = ALIGN_BOTTOM
            fillColor = borderColor
            text = $"{count}/{countEx}"
          }
        ]
      }
      unitUi
    ]
  }
}

function mkPlaneSelectable(airGroupIndex, action) {
  let icon = airGroupIcons[airGroupIndex]
  let isActionAvailable = Computed(
    @()
      action.value?.available ?? false
  )
  return @() {
    watch = [isActionAvailable, action]
    children = !isActionAvailable.value
      ? null
      : mkUnitSelectable(airGroupIndex, icon, @() mkPlaneUi(action.value, airGroupIndex), action.value.count, action.value.countEx)
  }
}

let airGroupsUi = {
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    mkPlaneSelectable(0, Computed(@() actionBarItems.value?[AB_SUPPORT_PLANE]))
    mkPlaneSelectable(1, Computed(@() actionBarItems.value?[AB_SUPPORT_PLANE_2]))
    mkPlaneSelectable(2, Computed(@() actionBarItems.value?[AB_SUPPORT_PLANE_3]))
    mkUnitSelectable(-1, iconShip, shipUi, 0, 0)
  ]
  function onAttach() {
    startActionBarUpdate("strategyModeHud")
  }
  function onDetach() {
    stopActionBarUpdate("strategyModeHud")
  }
}

return airGroupsUi
