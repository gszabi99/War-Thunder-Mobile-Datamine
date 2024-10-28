from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { borderWidth, btnBgColor, borderColor, borderNoAmmoColor, imageColor
    } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { shipDebuffs, crewHealth} = require("%rGui/hud/shipStateModule.nut")
let { actionBarItems, startActionBarUpdate, stopActionBarUpdate } = require("%rGui/hud/actionBar/actionBarState.nut")
let { AB_SUPPORT_PLANE, AB_SUPPORT_PLANE_2, AB_SUPPORT_PLANE_3 } = require("%rGui/hud/actionBar/actionType.nut")
let { strategyDataRest, curAirGroupIndex, optDebugDraw } = require("%rGui/hud/strategyMode/strategyState.nut")
let { getNodeStyle, airGroupIcons, airGroupButtonWidth, airGroupButtonHeight,
      iconShip, debugTextColor
    } = require("%rGui/hud/strategyMode/style.nut")
let { NODE_SELF } = require("guiStrategyMode")
let { mkSquareButtonBg } = require("%rGui/hud/buttons/squareTouchHudButtons.nut")
let { mkActionGlare } = require("%rGui/hud/weaponsButtonsAnimations.nut")
let { playSound } = require("sound_wt")

local prevAirGroupHealth = {}

function mkPathNodeSmall(nodeType, nodeSize, isActive) {
  let { icon, color } = getNodeStyle(nodeType)
  let iconSize = (nodeSize * 0.75).tointeger()
  return {
    rendObj = ROBJ_BOX
    size = [nodeSize, nodeSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    borderColor = borderNoAmmoColor
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
  let nodeSize = (airGroupButtonHeight * 0.45).tointeger()
  let nodeListUi = []
  foreach(node in data.nodes) {
    if(node.type != NODE_SELF) {
      if (i < 2 || (i + 2 >= data.nodes.len())) {
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
  let airGroupData = Computed(@() strategyDataRest.value?[airGroupIndex])
  return {
    flow = FLOW_VERTICAL
    gap = hdpx(7)
    children = [
      @() {
        watch = actionItem
        rendObj = ROBJ_TEXT
        hplace = ALIGN_RIGHT
        text = utf8ToUpper(loc(actionItem.get()?.weaponName ?? ""))
      }.__update(fontSmall)
      @() {
        watch = airGroupData
        flow = FLOW_HORIZONTAL
        hplace = ALIGN_RIGHT
        gap = hdpx(7)
        children = airGroupData.value ? mkStrategyCommandsUi(airGroupData.value) : null
      }
    ]
  }
}

function mkPlaneDebugInfo(airGroupIndex) {
  let airGroupData = Computed(@() strategyDataRest.value?[airGroupIndex] )
  return @() {
    size = [hdpx(450), 0]
    watch = airGroupData
    halign = ALIGN_RIGHT
    flow = FLOW_VERTICAL
    padding = hdpx(10)
    children = [
      {
        rendObj = ROBJ_TEXT
        color = debugTextColor
        text = $"Beh={airGroupData.value?.behaviour}"
      }
      {
        rendObj = ROBJ_TEXT
        color = debugTextColor
        text = $"ON_AIR={airGroupData.value?.groupSizeAlive}/{airGroupData.value?.groupSizeLaunched}, HP={airGroupData.value?.groupHealth}, CD={airGroupData.value?.cooldown}"
      }
      {
        rendObj = ROBJ_TEXT
        color = debugTextColor
        text = $"BOMBS={airGroupData.value?.groupBombs}, TORPEDOS={airGroupData.value?.groupTorpedos}"
      }
      {
        rendObj = ROBJ_TEXT
        color = debugTextColor
        text = $"BULLETS={airGroupData.value?.groupBullets}, ROCKETS={airGroupData.value?.groupRockets}"
      }
      {
        rendObj = ROBJ_TEXT
        color = debugTextColor
        text = $"DMG={airGroupData.value?.appliedDamage}, KILLS={airGroupData.value?.appliedKills}"
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

function mkUnitSelectable(selectableIndex, icon, border, unitUi, actionItem, trigger) {
  let stateFlags = Watched(0)
  let isSelected = Computed(@() curAirGroupIndex.value == selectableIndex)
  let buttonSize = airGroupButtonHeight
  let iconSize = (buttonSize * 0.65).tointeger()
  return @() {
    watch = [isSelected, stateFlags, actionItem]
    size = [airGroupButtonWidth, SIZE_TO_CONTENT]
    rendObj = ROBJ_BOX
    hplace = ALIGN_RIGHT
    borderColor = isSelected.value ? borderColor : 0x21212121
    borderWidth = border
    fillColor = isSelected.value ? 0x20072224 : btnBgColor.empty
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick = @() (selectableIndex >= 0) ? curAirGroupIndex(selectableIndex) : null // TODO: remove if when ships strategy commands will be supported
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = OutQuad }]
    children = [
      {
        size = flex()
        rendObj = ROBJ_BOX
        fillColor = 0
        animations = [{ prop = AnimProp.fillColor, from = Color(150, 50, 25, 150), duration = 1.5, easing = OutCubic, trigger }]
      }
      {
        flow = FLOW_HORIZONTAL
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_RIGHT
        gap =  hdpx(10)
        padding = hdpx(10)
        children = [
          unitUi
          {
            size = [buttonSize, buttonSize]
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = [
              actionItem == null ? null : mkActionGlare(actionItem.value, buttonSize)
              actionItem == null || actionItem.value?.count == 0 ? null
                : mkSquareButtonBg(actionItem.get(), buttonSize, @() playSound("weapon_secondary_ready"))
              {
                size = flex()
                padding = hdpx(5)
                gap = hdpx(5)
                rendObj = ROBJ_BOX
                flow = FLOW_VERTICAL
                halign = ALIGN_CENTER
                valign = ALIGN_CENTER
                borderWidth = borderWidth
                borderColor = isSelected.value ? borderColor : 0x21212121
                fillColor = actionItem == null ? btnBgColor.ready : btnBgColor.empty
                children = [
                  {
                    rendObj = ROBJ_IMAGE
                    size = [iconSize, iconSize]
                    image = Picture($"{icon}:{iconSize}:{iconSize}:P")
                    keepAspect = KEEP_ASPECT_FIT
                    color = imageColor
                  }
                  actionItem == null ? null : {
                    rendObj = ROBJ_TEXT
                    halign = ALIGN_CENTER
                    valign = ALIGN_BOTTOM
                    fillColor = borderColor
                    text = $"{actionItem.value?.count}"
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
}

function mkPlaneSelectable(airGroupIndex, actionItem) {
  let icon = airGroupIcons[airGroupIndex]
  return @() {
    watch = optDebugDraw
    flow = FLOW_HORIZONTAL
    children = [
      !optDebugDraw.value ? null
        : mkPlaneDebugInfo(airGroupIndex)
      mkUnitSelectable(airGroupIndex, icon, borderWidth, mkPlaneUi(actionItem, airGroupIndex),
        actionItem, $"airGroupHealthReduced{airGroupIndex}")
    ]
  }
}

strategyDataRest.subscribe(function(data) {
  foreach(idx, v in data) {
    if ((idx in prevAirGroupHealth) && v.isLaunched && v.groupHealth < prevAirGroupHealth[idx])
      anim_start($"airGroupHealthReduced{idx}")
  }
  prevAirGroupHealth = data.map(@(v) v.groupHealth)
})

let airGroupsUi = {
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    mkPlaneSelectable(0, Computed(@() actionBarItems.value?[AB_SUPPORT_PLANE]))
    mkPlaneSelectable(1, Computed(@() actionBarItems.value?[AB_SUPPORT_PLANE_2]))
    mkPlaneSelectable(2, Computed(@() actionBarItems.value?[AB_SUPPORT_PLANE_3]))
    mkUnitSelectable(-1, iconShip, 0, shipUi, null, null)
  ]
  function onAttach() {
    startActionBarUpdate("strategyModeHud")
  }
  function onDetach() {
    stopActionBarUpdate("strategyModeHud")
  }
}

return airGroupsUi
