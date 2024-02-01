from "%globalsDarg/darg_library.nut" import *
let { Point2, Point3 } = require("dagor.math")
let { fabs } = require("math")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { touchButtonSize, borderWidth, btnBgColor, borderColor, borderNoAmmoColor,
      imageDisabledColor, imageColor
    } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { textButtonBright, textButtonPrimary, textButtonSecondary
    } = require("%rGui/components/textButton.nut")
let { setSelection, getSelectionPos2d, nodeAdd, nodeInsert, nodeClear, nodeEdit, launchPlane,
      NODE_INVALID, NODE_SELF, NODE_ORDER_RETURN, NODE_ORDER_POINT, NODE_ORDER_ATTACK,
      NODE_ORDER_DEFEND, NODE_ORDER_HUNT
    } = require("guiStrategyMode")
let { strategyDataCur, curAirGroupIndex, curAirGroupIsLaunched, curAirGroupPathLength, curAirGroupType,
      curAirGroupCanAttack, curAirGroupCanDefend, curAirGroupCanHunt
    } = require("%rGui/hud/strategyMode/strategyState.nut")
let { getNodeStyle, edgeColorDefault, edgeColorPending, edgeButtonColor, airGroupAttackIcons,
      iconInsert, iconClear, iconDebugWarning, airGroupIcons
    } = require("%rGui/hud/strategyMode/style.nut")

const iconEdge = "ui/gameuiskin#blink_sharp.svg"
const iconSelectedUnit = "ui/gameuiskin#crew_gunner_indicator.svg"
const iconPointPending = "ui/gameuiskin#pin.svg"

local selectedInfo = Watched(null)
local movingNodeId = Watched(-1)
local movingNodeOffset = Watched(Point2())

let selectedNodeId = Computed(@() selectedInfo.value?.nodeId ?? -1)
let selectedEdgeId = Computed(@() selectedInfo.value?.edgeId ?? -1)
let selectedNodeType = Computed(@() selectedInfo.value?.nodeType ?? NODE_INVALID)
let selectedUnitId = Computed(@() selectedInfo.value?.unitId ?? -1)
let selectedUnitIsEnemy = Computed(@() selectedInfo.value?.unitIsEnemy ?? false)
let selectedPos = Computed(@() selectedInfo.value?.pos ?? Point3())
let selectedPosIsValid = Computed(@() selectedInfo.value?.posIsValid ?? false)
let curAttackIcon = Computed(@() airGroupAttackIcons?[curAirGroupType.value] ?? iconDebugWarning)

function onSelectionClick(x, y) {
  let selection = setSelection(x, y)
  selectedInfo({
    nodeType = NODE_INVALID
    nodeId = -1
    edgeId = -1
    unitId = selection.unitId
    unitIsEnemy = selection.unitIsEnemy
    pos = selection.pos
    posIsValid = true
  })
}

let pointerState = {
  evt = Point2()
}

function onPointerPress(evt) {
  if (evt.accumRes & R_PROCESSED)
    return 0
  if (!evt.hit)
    return 0

  pointerState.evt = evt
  return 0
}

function onPointerRelease(evt) {
  if (evt.accumRes & R_PROCESSED)
    return 0
  if (!evt.hit)
    return 0

  if(pointerState.evt != null
      && fabs(pointerState.evt.x - evt.x) < 10
      && fabs(pointerState.evt.y - evt.y) < 10) {
    onSelectionClick(evt.x, evt.y)
    return 1
  }

  return 0
}

function onNodeEditClick(newNodeType) {
  local nodeId = -1
  if (selectedEdgeId.value != -1) {
    nodeId = nodeInsert(curAirGroupIndex.value, selectedEdgeId.value, newNodeType, selectedUnitId.value, selectedPos.value)
  } else if(selectedNodeId.value != -1) {
    nodeId = nodeEdit(curAirGroupIndex.value, selectedNodeId.value, newNodeType, selectedUnitId.value, selectedPos.value)
  }
  else {
    nodeId = nodeAdd(curAirGroupIndex.value, newNodeType, selectedUnitId.value, selectedPos.value)
  }
  selectedInfo({
    nodeType = newNodeType
    nodeId = nodeId
    edgeId = -1
    unitId = -1
    unitIsEnemy = false
    pos = selectedPos.value
    posIsValid = false
  })
}

function onNodeInsertClick(newNodeType) {
  let nodeId = nodeInsert(curAirGroupIndex.value, selectedEdgeId.value, newNodeType, selectedUnitId.value, selectedPos.value)
  selectedInfo({
    nodeType = newNodeType
    nodeId = nodeId
    edgeId = -1
    unitId = -1
    unitIsEnemy = false
    pos = Point3()
    posIsValid = false
  })
}

function onNodeClearClick() {
  nodeClear(curAirGroupIndex.value, selectedNodeId.value, false)
  selectedInfo({
    nodeType = NODE_INVALID
    nodeId = -1
    edgeId = -1
    unitId = -1
    unitIsEnemy = false
    pos = Point3()
    posIsValid = false
  })
}

function onNodeClick(nodeType, nodeId, edgeId, pos) {
  onSelectionClick(pos.x, pos.y)
  selectedInfo({
    nodeType = nodeType
    nodeId = nodeId
    edgeId = edgeId
    unitId = -1
    unitIsEnemy = false
    pos = selectedPos.value
    posIsValid = false
  })
}

function onNodeMove(nodeType, nodeId, newPos) {
  let newNodeType = (nodeType == NODE_ORDER_HUNT) ? NODE_ORDER_HUNT : NODE_ORDER_POINT
  onSelectionClick(newPos.x, newPos.y)
  nodeId = nodeEdit(curAirGroupIndex.value, nodeId, newNodeType, selectedUnitId.value, selectedPos.value)
  selectedInfo({
    nodeType = newNodeType
    nodeId = nodeId
    edgeId = -1
    unitId = selectedUnitId.value
    unitIsEnemy = selectedUnitIsEnemy.value
    pos = selectedPos.value
    posIsValid = false
  })
}

function onPathLaunch() {
  if (curAirGroupIndex.value != -1) {
    launchPlane(curAirGroupIndex.value, curAirGroupIsLaunched.value)
  }
  //else {
  //  onButtonClose()
  //}
}

function onPathAbort() {
  nodeClear(curAirGroupIndex.value, -1, true)
  selectedInfo({
    nodeType = NODE_INVALID
    nodeId = -1
    edgeId = -1
    unitId = -1
    unitIsEnemy = false
    pos = Point3()
    posIsValid = false
  })
}

function mkSelfNode(nodePos) {
  local { size, color, valign, border, rotate } = getNodeStyle(NODE_SELF)
  let icon = airGroupIcons?[curAirGroupIndex.value]
  let iconSize = (size * 0.85).tointeger()
  return {
    size = [0, 0]
    pos = [nodePos.x, nodePos.y]
    halign = ALIGN_CENTER
    valign = valign
    opacity = 0.75
    children = [
      {
        rendObj = ROBJ_BOX
        size = [size, size]
        borderWidth = border ? borderWidth : 0
        borderColor = borderColor
        transform = { rotate }
      }
      {
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        size = [iconSize, iconSize]
        image = Picture($"!{icon}:{iconSize}:{iconSize}")
        color = color
        keepAspect = KEEP_ASPECT_FIT
      }
    ]
  }
}

function mkPathNode(nodeType, nodeId, nodePos) {
  local { icon, size, color, valign, border, rotate } = getNodeStyle(nodeType)
  let iconSize = (size * 0.85).tointeger()
  let isMoving = Computed(@() nodeId != -1 && nodeId == movingNodeId.value)
  let isSelected = Computed(@() nodeId != -1 && nodeId == selectedNodeId.value && !isMoving.value)

  return @() {
    watch = [isSelected, isMoving]
    size = [0, 0]
    pos = [nodePos.x, nodePos.y]
    halign = ALIGN_CENTER
    valign = valign
    children = [
      {
        size = [size, size]
        behavior = Behaviors.MoveResize
        moveResizeModes = MR_AREA

        function onMoveResizeStarted(x, y, bbox) {
          movingNodeOffset(Point2(x - bbox.x - size / 2, y - bbox.y - size))
        }

        function onMoveResize(dx, dy, _, _) {
          if(fabs(dx) > 0 || fabs(dy) > 0) {
            movingNodeId(nodeId)
            movingNodeOffset(movingNodeOffset.value + Point2(dx, dy))
          }
          return null
        }

        function onMoveResizeFinished() {
          onNodeClick(nodeType, nodeId, -1, nodePos)
          if(movingNodeId.value == nodeId) {
            let newPos = nodePos + movingNodeOffset.value
            onNodeMove(nodeType, nodeId, newPos)
          }
          movingNodeId(-1)
        }

        children = [
          {
            rendObj = ROBJ_BOX
            size = flex()
            fillColor = isSelected.value ? btnBgColor.ready : 0
            borderWidth = (isSelected.value || border) ? borderWidth : 0
            borderColor = borderColor
            transform = { rotate }
          }
          {
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            rendObj = ROBJ_IMAGE
            size = [iconSize, iconSize]
            image = Picture($"!{icon}:{iconSize}:{iconSize}")
            color = color
            opacity = isMoving.value ? 0.35 : 1
            keepAspect = KEEP_ASPECT_FIT
          }
        ]
      }
      !isMoving.value ? null : @() {
        watch = movingNodeOffset
        pos = [movingNodeOffset.value.x, movingNodeOffset.value.y]
        size = [0, 0]
        children = [
          {
            rendObj = ROBJ_IMAGE
            hplace = ALIGN_CENTER
            vplace = ALIGN_BOTTOM
            size = [iconSize, iconSize]
            keepAspect = KEEP_ASPECT_FIT
            image = Picture($"{icon}:{iconSize}:{iconSize}:P")
            color = imageColor
            opacity = 0.75
            transform = { translate = [0, hdpx(-25)], scale = [1.5, 1.5] }
            animations = [
              { prop = AnimProp.scale, from = [0.5, 0.5], to = [1.5, 1.5], duration = 0.3, easing = OutQuad, play = true }
              { prop = AnimProp.translate, from = [0, 0], to = [0, hdpx(-25)], duration = 0.3, easing = OutQuad, play = true }
            ]
          }
          {
            size = [100, 100]
            rendObj = ROBJ_VECTOR_CANVAS
            lineWidth = hdpx(15)
            color = edgeColorPending
            commands = [
              [VECTOR_LINE_DASHED, 0, 0, -movingNodeOffset.value.x, -movingNodeOffset.value.y, hdpx(10), hdpx(20)]
            ]
          }
        ]
      }
    ]
  }
}

function mkPathEdgeButton(edgePos, edgeId, edgeColor) {
  let btnSize = hdpx(50)
  let imgSizeOuter = (btnSize * 0.95).tointeger()
  let imgSizeInner = (btnSize * 0.65).tointeger()
  let isSelected = Computed(@() edgeId != -1 && selectedEdgeId.value == edgeId)
  return @() {
    watch = isSelected
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = [0, 0]
    pos = [edgePos.x, edgePos.y]
    children = [
      {
        rendObj = ROBJ_BOX
        size = [btnSize, btnSize]
        fillColor = isSelected.value ? btnBgColor.ready : 0
        borderWidth = isSelected.value ? borderWidth : 0
        borderColor = borderColor
        behavior = Behaviors.Button
        onClick = @() onNodeClick(NODE_INVALID, -1, edgeId, edgePos)
      }
      {
        rendObj = ROBJ_IMAGE
        size = [imgSizeOuter, imgSizeOuter]
        image = Picture($"{iconEdge}:{imgSizeOuter}:{imgSizeOuter}:P")
        color = edgeColor
        keepAspect = KEEP_ASPECT_FIT
      }
      {
        rendObj = ROBJ_IMAGE
        size = [imgSizeInner, imgSizeInner]
        image = Picture($"{iconEdge}:{imgSizeInner}:{imgSizeInner}:P")
        color = edgeButtonColor
        keepAspect = KEEP_ASPECT_FIT
      }
    ]
  }
}

function mkNodesUi(data) {
  let edgesUi = []
  let nodesUi = []
  local edgePrevPos = Point2()
  local i = 0

  foreach(node in data.nodes) {
    local ui = (node.type == NODE_SELF)
      ? mkSelfNode(node.pos2)
      : mkPathNode(node.type, node.id, node.pos2)
    nodesUi.append(ui)
    if (i > 0) {
      let edgePos = Point2()
      let edgeId = node.id
      let edgeColor = (edgeId == selectedNodeId.value)
        ? getNodeStyle(node.type).edgeColorSelected
        : getNodeStyle(node.type).edgeColor

      edgePos.x = edgePrevPos.x + (node.pos2.x - edgePrevPos.x) / 2
      edgePos.y = edgePrevPos.y + (node.pos2.y - edgePrevPos.y) / 2

      edgesUi.append([VECTOR_COLOR, edgeColor])
      edgesUi.append([VECTOR_FILL_COLOR, edgeColor])
      edgesUi.append([VECTOR_LINE, edgePrevPos.x, edgePrevPos.y, node.pos2.x, node.pos2.y])
      edgesUi.append([VECTOR_ELLIPSE, node.pos2.x, node.pos2.y, hdpx(7), hdpx(7)])

      if(node.type != NODE_ORDER_RETURN)
        nodesUi.append(mkPathEdgeButton(edgePos, edgeId, edgeColor))
    }

    if(node.type != NODE_ORDER_RETURN)
      edgePrevPos = node.pos2

    i++
  }

  if (selectedPosIsValid.value || selectedUnitId.value != -1) {
    let pendingDstPos = getSelectionPos2d(selectedPos.value, selectedUnitId.value)
    let pendingSrcPos = (selectedPosIsValid.value) ? edgePrevPos : getSelectionPos2d(selectedPos.value, -1)
    let pendingIcon = (selectedUnitId.value != -1) ? iconSelectedUnit : iconPointPending
    let pendingIconVAlign = (selectedUnitId.value != -1) ? ALIGN_CENTER : ALIGN_BOTTOM
    let pendingIconSize = hdpxi(100)

    edgesUi.append([VECTOR_COLOR, edgeColorPending])
    edgesUi.append([VECTOR_LINE_DASHED, pendingSrcPos.x, pendingSrcPos.y, pendingDstPos.x, pendingDstPos.y, hdpx(10), hdpx(20)])

    nodesUi.append({
      size = [0, 0]
      halign = ALIGN_CENTER
      valign = pendingIconVAlign
      pos = [pendingDstPos.x, pendingDstPos.y]
      children = {
        rendObj = ROBJ_IMAGE
        size = [pendingIconSize, pendingIconSize]
        image = Picture($"{pendingIcon}:{pendingIconSize}:{pendingIconSize}:P")
        color = imageColor
        keepAspect = KEEP_ASPECT_FIT
      }
    })
  }

  nodesUi.insert(0, {
    size = [100, 100]
    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth = hdpx(15)
    color = edgeColorDefault
    commands = edgesUi
  })

  return nodesUi
}

function mkCommandButton(text, img, isEnabled, isAllowed, onClick) {
  let stateFlags = Watched(0)
  let isActive = Computed(@() isAllowed.value && (stateFlags.value & S_ACTIVE))
  let iconSize = (touchButtonSize * 0.55).tointeger()
  return @() {
    watch = [stateFlags, isActive, isAllowed, isEnabled]
    rendObj = ROBJ_BOX
    size = [touchButtonSize, touchButtonSize]
    flow = FLOW_VERTICAL
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    padding = hdpx(10)
    gap = hdpx(5)
    borderWidth = borderWidth
    borderColor = (isEnabled.value && isAllowed.value) ? borderColor : borderNoAmmoColor
    fillColor = (isEnabled.value && isAllowed.value) ? btnBgColor.ready : btnBgColor.empty
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags(v)
    onClick = (isEnabled.value && isAllowed.value) ? onClick : null
    transform = { scale = isActive.value ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = OutQuad }]
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [iconSize, iconSize]
        image = Picture($"{img}:{iconSize}:{iconSize}:P")
        keepAspect = KEEP_ASPECT_FIT
        color = isEnabled.value ? imageColor : imageDisabledColor
      }
      {
        rendObj = ROBJ_TEXT
        size = flex()
        halign = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        color = isEnabled.value ? imageColor : imageDisabledColor
        text = text
      }
    ]
  }
}

function mkCommandsUi() {
  let isWorldPointSelected = Computed(@() selectedEdgeId.value == -1 && selectedPosIsValid.value)
  let isAttackAllowed = Computed(@() selectedUnitId.value != -1 && selectedUnitIsEnemy.value)
  let isDeffendAllowed = Computed(@() selectedUnitId.value != -1 && !selectedUnitIsEnemy.value)
  let isHuntAllowed = Computed(@() selectedUnitId.value == -1 && (isWorldPointSelected.value || selectedNodeType.value == NODE_ORDER_POINT))
  let isPointAllowed = Computed(@() selectedUnitId.value == -1 && (isWorldPointSelected.value || selectedNodeType.value == NODE_ORDER_HUNT))
  let isPointClearAllowed = Computed(@() selectedEdgeId.value == -1 && (selectedNodeId.value != -1 || curAirGroupPathLength.value > 1))
  let isPointInsertAllowed = Computed(@() selectedNodeId.value == -1 && selectedEdgeId.value != -1)
  let isAllwaysEnabled = Computed(@() true)
  return {
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = [
      {
        hplace = ALIGN_RIGHT
        vplace = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(10)
        children = [
          @() {
            watch = curAttackIcon
            children = mkCommandButton("ATTACK", curAttackIcon.value, curAirGroupCanAttack, isAttackAllowed, @() onNodeEditClick(NODE_ORDER_ATTACK))
          }
          mkCommandButton("DEFEND", getNodeStyle(NODE_ORDER_DEFEND).icon, curAirGroupCanDefend, isDeffendAllowed, @() onNodeEditClick(NODE_ORDER_DEFEND))
          mkCommandButton("HUNT", getNodeStyle(NODE_ORDER_HUNT).icon, curAirGroupCanHunt, isHuntAllowed, @() onNodeEditClick(NODE_ORDER_HUNT))
        ]
      }
      {
        hplace = ALIGN_RIGHT
        vplace = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(10)
        children = [
          mkCommandButton("POINT", getNodeStyle(NODE_ORDER_POINT).icon, isAllwaysEnabled, isPointAllowed, @() onNodeEditClick(NODE_ORDER_POINT))
          mkCommandButton("INSERT", iconInsert, isAllwaysEnabled, isPointInsertAllowed, @() onNodeInsertClick(NODE_ORDER_POINT))
          mkCommandButton("CLEAR", iconClear, isAllwaysEnabled, isPointClearAllowed, @() onNodeClearClick())
        ]
      }
    ]
  }
}

let pathNodesUi = {
  size = flex()
  children = [
    {
      size = flex()
      behavior = Behaviors.ProcessPointingInput
      onPointerPress
      onPointerRelease
    }
    @() {
      size = flex()
      watch = strategyDataCur
      children = strategyDataCur.value ? mkNodesUi(strategyDataCur.value) : null
    }
  ]
}

let pathCommandsUi = @() {
  watch = [curAirGroupIsLaunched, curAirGroupIndex]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = hdpx(40)
  children = [
    mkCommandsUi,
    {
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      flow = FLOW_HORIZONTAL
      gap = hdpx(40)
      children = [
        curAirGroupIndex.value != -1
          ? textButtonBright(utf8ToUpper(loc("strategyMode/abort_mission")), onPathAbort)
          : null
          curAirGroupIsLaunched.value
          ? textButtonSecondary(utf8ToUpper(loc("strategyMode/take_control")), onPathLaunch)
          : textButtonPrimary(utf8ToUpper(loc("strategyMode/launch")), onPathLaunch)
      ]
    }
  ]
}

return {
  pathNodesUi
  pathCommandsUi
}
