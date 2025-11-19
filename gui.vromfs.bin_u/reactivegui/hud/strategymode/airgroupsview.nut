from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { borderWidth, btnBgStyle, borderColor, borderNoAmmoColor, imageColor
} = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkShipDebuffs, mkCrewHealthCtor, defHealthSize } = require("%rGui/hud/shipStateModule.nut")
let { actionBarItems, startActionBarUpdate, stopActionBarUpdate } = require("%rGui/hud/actionBar/actionBarState.nut")
let { AB_SUPPORT_PLANE, AB_SUPPORT_PLANE_2, AB_SUPPORT_PLANE_3 } = require("%rGui/hud/actionBar/actionType.nut")
let { strategyDataRest, strategyDataShip, curGroupIndex, optDebugDraw } = require("%rGui/hud/strategyMode/strategyState.nut")
let { getNodeStyle, airGroupIcons, airGroupButtonWidth, airGroupButtonHeight,
  iconShip, debugTextColor
} = require("%rGui/hud/strategyMode/style.nut")
let { onGroupSelected, NODE_SELF } = require("guiStrategyMode")
let { mkSquareButtonBg } = require("%rGui/hud/buttons/squareTouchHudButtons.nut")
let { mkActionGlare } = require("%rGui/hud/weaponsButtonsAnimations.nut")
let { playSound } = require("sound_wt")
let { isHudPrimaryStyle } = require("%rGui/options/options/hudStyleOptions.nut")
let { hudGrayColorFade, hudTealColorFade, hudBrownRedFade } = require("%rGui/style/hudColors.nut")

local prevAirGroupHealth = {}

function mkPathNodeSmall(nodeType, nodeSize, isActive) {
  let { icon, color } = getNodeStyle(nodeType)
  let iconSize = (nodeSize * 0.75).tointeger()
  return @() {
    watch = btnBgStyle
    rendObj = ROBJ_BOX
    size = [nodeSize, nodeSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    borderColor = borderNoAmmoColor
    borderWidth = borderWidth
    fillColor = isActive ? btnBgStyle.get().broken : btnBgStyle.get().ready
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
  let airGroupData = Computed(@() strategyDataRest.get()?[airGroupIndex])
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
        children = airGroupData.get() ? mkStrategyCommandsUi(airGroupData.get()) : null
      }
    ]
  }
}

function mkPlaneDebugInfo(airGroupIndex) {
  let airGroupData = Computed(@() strategyDataRest.get()?[airGroupIndex] )
  return @() {
    size = const [hdpx(450), 0]
    watch = airGroupData
    halign = ALIGN_RIGHT
    flow = FLOW_VERTICAL
    padding = hdpx(10)
    children = [
      {
        rendObj = ROBJ_TEXT
        color = debugTextColor
        text = $"Beh={airGroupData.get()?.behaviour}"
      }
      {
        rendObj = ROBJ_TEXT
        color = debugTextColor
        text = $"ON_AIR={airGroupData.get()?.groupSizeAlive}/{airGroupData.get()?.groupSizeLaunched}, HP={airGroupData.get()?.groupHealth}, CD={airGroupData.get()?.cooldown}"
      }
      {
        rendObj = ROBJ_TEXT
        color = debugTextColor
        text = $"BOMBS={airGroupData.get()?.groupBombs}, TORPEDOS={airGroupData.get()?.groupTorpedos}"
      }
      {
        rendObj = ROBJ_TEXT
        color = debugTextColor
        text = $"BULLETS={airGroupData.get()?.groupBullets}, ROCKETS={airGroupData.get()?.groupRockets}"
      }
      {
        rendObj = ROBJ_TEXT
        color = debugTextColor
        text = $"DMG={airGroupData.get()?.appliedDamage}, KILLS={airGroupData.get()?.appliedKills}"
      }
    ]
  }
}

function mkShipDebugInfo() {
  return @() {
    size = const [hdpx(450), 0]
    watch = strategyDataShip
    halign = ALIGN_RIGHT
    flow = FLOW_VERTICAL
    padding = hdpx(10)
    children = [
      {
        rendObj = ROBJ_TEXT
        color = debugTextColor
        text = $"Speed={strategyDataShip.get()?.speed}"
      }
      {
        rendObj = ROBJ_TEXT
        color = debugTextColor
        text = $"Throttle={strategyDataShip.get()?.throttle}"
      }
      {
        rendObj = ROBJ_TEXT
        color = debugTextColor
        text = $"Steering={strategyDataShip.get()?.steering}"
      }
      {
        rendObj = ROBJ_TEXT
        color = debugTextColor
        text = $"IsDrivingBackward={strategyDataShip.get()?.isDrivingBackward}"
      }
    ]
  }
}

let shipUi = {
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  children = [
    mkShipDebuffs(1)
    mkCrewHealthCtor(defHealthSize)(1)
  ]
}

function selectGroup(selectableIndex) {
  onGroupSelected(selectableIndex)
  curGroupIndex.set(selectableIndex)
}

function mkUnitSelectable(selectableIndex, icon, border, unitUi, actionItem, trigger) {
  let stateFlags = Watched(0)
  let isSelected = Computed(@() curGroupIndex.get() == selectableIndex)
  let canClick = Computed(@() selectableIndex == -1 ? true : strategyDataRest.get()?[selectableIndex].groupNotDead)
  let buttonSize = airGroupButtonHeight
  let iconSize = (buttonSize * 0.65).tointeger()
  return @() {
    watch = [isSelected, canClick, stateFlags, actionItem, isHudPrimaryStyle, btnBgStyle]
    size = [airGroupButtonWidth, SIZE_TO_CONTENT]
    rendObj = ROBJ_BOX
    hplace = ALIGN_RIGHT
    borderColor = isSelected.get() ? borderColor : hudGrayColorFade
    borderWidth = border
    fillColor = isSelected.get() ? hudTealColorFade : btnBgStyle.get().empty
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick = @() canClick.get() ? selectGroup(selectableIndex) : null
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = OutQuad }]
    children = [
      {
        size = flex()
        rendObj = ROBJ_BOX
        fillColor = 0
        animations = [{ prop = AnimProp.fillColor, from = hudBrownRedFade, duration = 1.5, easing = OutCubic, trigger }]
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
              actionItem == null ? null : mkActionGlare(actionItem.get(), buttonSize)
              actionItem == null || actionItem.get()?.count == 0 ? null
                : mkSquareButtonBg(actionItem.get(), buttonSize, btnBgStyle.get(), isHudPrimaryStyle.get(), @() playSound("weapon_secondary_ready"))
              {
                size = flex()
                padding = hdpx(5)
                gap = hdpx(5)
                rendObj = ROBJ_BOX
                flow = FLOW_VERTICAL
                halign = ALIGN_CENTER
                valign = ALIGN_CENTER
                borderWidth = borderWidth
                borderColor = isSelected.get() ? borderColor : hudGrayColorFade
                fillColor = actionItem == null ? btnBgStyle.get().ready : btnBgStyle.get().empty
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
                    text = $"{actionItem.get()?.count}"
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
      !optDebugDraw.get() ? null
        : mkPlaneDebugInfo(airGroupIndex)
      mkUnitSelectable(airGroupIndex, icon, borderWidth, mkPlaneUi(actionItem, airGroupIndex),
        actionItem, $"airGroupHealthReduced{airGroupIndex}")
    ]
  }
}

function mkShipSelectable() {
  return @() {
    watch = optDebugDraw
    flow = FLOW_HORIZONTAL
    children = [
      !optDebugDraw.get() ? null
        : mkShipDebugInfo()
        mkUnitSelectable(-1, iconShip, borderWidth, shipUi, null, null)
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
    mkPlaneSelectable(0, Computed(@() actionBarItems.get()?[AB_SUPPORT_PLANE]))
    mkPlaneSelectable(1, Computed(@() actionBarItems.get()?[AB_SUPPORT_PLANE_2]))
    mkPlaneSelectable(2, Computed(@() actionBarItems.get()?[AB_SUPPORT_PLANE_3]))
    mkShipSelectable()
  ]
  function onAttach() {
    startActionBarUpdate("strategyModeHud")
  }
  function onDetach() {
    stopActionBarUpdate("strategyModeHud")
  }
}

return airGroupsUi
