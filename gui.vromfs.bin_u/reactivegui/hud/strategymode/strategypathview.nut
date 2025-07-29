from "%globalsDarg/darg_library.nut" import *
let { Point2, Point3 } = require("dagor.math")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { fabs } = require("math")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { touchButtonSize, borderWidth, btnBgColor, borderColor, borderNoAmmoColor,
      imageDisabledColor, imageColor
    } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { textButtonBright, textButtonPrimary, textButtonSecondary
    } = require("%rGui/components/textButton.nut")
let { getSelectionPos2d, nodeAdd, nodeInsert, nodeClear, nodeEdit, launchPlane, launchShip
      setSelection, setSelectionRect, NODE_INVALID, NODE_SELF, NODE_ORDER_RETURN,
      NODE_ORDER_POINT, NODE_ORDER_ATTACK, NODE_ORDER_DEFEND, NODE_ORDER_HUNT
    } = require("guiStrategyMode")
let { showHint } = require("%rGui/tooltip.nut")
let { strategyDataCur, curGroupIndex, curAirGroupIsLaunched, curAirGroupPathLength,
      curAirGroupIsReturning, curAirGroupType, curAirGroupCanAttackAir, curAirGroupCanAttackGround,
      curAirGroupCanDefend, curAirGroupCanHunt, updateStrategyDataCur, optDebugDraw
    } = require("%rGui/hud/strategyMode/strategyState.nut")
let { getNodeStyle, edgeColorDefault, edgeColorPending, edgeButtonColor, airGroupAttackIcons,
      iconInsert, iconClear, debugIconWarning, airGroupIcons, debugTextColor
    } = require("%rGui/hud/strategyMode/style.nut")

const iconEdge = "ui/gameuiskin#blink_sharp.svg"
const iconSelectedUnit = "ui/gameuiskin#crew_gunner_indicator.svg"
const iconPointPending = "ui/gameuiskin#pin.svg"

local holdedNodeId = -1
local movingNodeId = Watched(-1)
local movingNodeOffset = Watched(Point2())
local movingNodeAlignOffset = Point2()

let selectedInfo = Watched({
  nodeType = NODE_INVALID
  nodeId = -1
  edgeId = -1
  unitId = -1
  unitIsEnemy = false
  unitIsFlyModel = false
  pos = Point2()
  posIsValid = false
})

let curAttackIcon = Computed(@() airGroupAttackIcons?[curAirGroupType.get()] ?? debugIconWarning)
let selectedNodeId = Computed(@() selectedInfo.value?.nodeId ?? -1)
let selectedEdgeId = Computed(@() selectedInfo.value?.edgeId ?? -1)
let selectedNodeType = Computed(@() selectedInfo.value?.nodeType ?? NODE_INVALID)
let selectedUnitId = Computed(@() selectedInfo.value?.unitId ?? -1)
let selectedUnitIsEnemy = Computed(@() selectedInfo.value?.unitIsEnemy ?? false)
let selectedUnitIsFlyModel = Computed(@() selectedInfo.value?.unitIsFlyModel ?? false)
let selectedPos = Computed(@() selectedInfo.value?.pos ?? Point3())
let selectedPosIsValid = Computed(@() selectedInfo.value?.posIsValid ?? false)

function midPoint(p1, p2) {
  return Point2(
    p1.x + (p2.x - p1.x) / 2,
    p1.y + (p2.y - p1.y) / 2
  )
}

function pathSelectionReset() {
  selectedInfo.set({
    nodeType = NODE_INVALID
    nodeId = -1
    edgeId = -1
    unitId = -1
    unitIsEnemy = false
    unitIsFlyModel = false
    pos = Point3()
    posIsValid = false
  })
}

function pathSelectPoint(x, y) {
  let selection = setSelection(x, y)
  selectedInfo.set({
    nodeType = NODE_INVALID
    nodeId = -1
    edgeId = -1
    unitId = selection.unitId
    unitIsEnemy = selection.unitIsEnemy
    unitIsFlyModel = selection.unitIsFlyModel
    pos = selection.pos
    posIsValid = true
  })
}

function pathSelectZone(x0, y0, x1, y1) {
  let selection = setSelectionRect(x0, y0, x1, y1)
  if (selection.unitId != -1) {
    selectedInfo.set({
      nodeType = NODE_INVALID
      nodeId = -1
      edgeId = -1
      unitId = selection.unitId
      unitIsEnemy = selection.unitIsEnemy
      unitIsFlyModel = selection.unitIsFlyModel
      pos = Point3()
      posIsValid = false
    })
  } else {
    pathSelectionReset()
  }
}

function pathSelectNode(nodeType, nodeId, edgeId, keepUnitSelection) {
  selectedInfo.mutate(function(v) {
    v.nodeType = nodeType
    v.nodeId = nodeId
    v.edgeId = edgeId
    if (!keepUnitSelection) {
      v.unitId = -1
      v.unitIsEnemy = -1
      v.unitIsFlyModel = false
    }
    v.posIsValid = false
  })
}

function pathRefreshUi() {
  updateStrategyDataCur()
}

function onNodeEditClick(newNodeType) {
  local nodeId = -1
  if (selectedEdgeId.value != -1) {
    nodeId = nodeInsert(curGroupIndex.get(), selectedEdgeId.value, newNodeType, selectedUnitId.value, selectedPos.value)
  } else if(selectedNodeId.value != -1) {
    nodeId = nodeEdit(curGroupIndex.get(), selectedNodeId.value, newNodeType, selectedUnitId.value, selectedPos.value)
  }
  else {
    nodeId = nodeAdd(curGroupIndex.get(), newNodeType, selectedUnitId.value, selectedPos.value)
  }
  pathSelectNode(newNodeType, nodeId, -1, false)
}

function onNodeInsertClick(newNodeType) {
  local insertPos = selectedPos.value
  for (local i = 1; i < strategyDataCur.get().nodes.len(); i++) {
    let node = strategyDataCur.get().nodes[i]
    if (strategyDataCur.get().nodes[i].id == selectedEdgeId.value) {
      let prevNode = strategyDataCur.get().nodes[i - 1]
      let edgeMidPos = midPoint(prevNode.pos2, node.pos2)
      insertPos = setSelection(edgeMidPos.x, edgeMidPos.y).pos
      break
    }
  }
  let nodeId = nodeInsert(curGroupIndex.get(), selectedEdgeId.value, newNodeType, selectedUnitId.value, insertPos)
  pathSelectNode(newNodeType, nodeId, -1, false)
}

function onNodeClearClick() {
  nodeClear(curGroupIndex.get(), selectedNodeId.value, false)
  pathSelectionReset()
}

function onNodeClick(nodeType, nodeId, edgeId, pos) {
  if (edgeId != -1)
    pathSelectPoint(pos.x, pos.y)
  pathSelectNode(nodeType, nodeId, edgeId, false)
}

function onNodeMove(nodeType, nodeId, newPos) {
  let newNodeType = (nodeType == NODE_ORDER_HUNT) ? NODE_ORDER_HUNT : NODE_ORDER_POINT
  pathSelectPoint(newPos.x, newPos.y)
  nodeId = nodeEdit(curGroupIndex.get(), nodeId, newNodeType, selectedUnitId.value, selectedPos.value)
  pathSelectNode(newNodeType, nodeId, -1, true)
}

function onPathLaunch() {
  if (curGroupIndex.get() >= 0)
    launchPlane(curGroupIndex.get(), curAirGroupIsLaunched.get())
  else
    launchShip()
}

function onPathAbort() {
  nodeClear(curGroupIndex.get(), -1, true)
  pathSelectionReset()
}

function mkSelfNode(nodePos) {
  local { size, color, valign, border, rotate, padding, opacity } = getNodeStyle(NODE_SELF)
  let icon = airGroupIcons?[curGroupIndex.get()]
  let iconSize = (size * 0.85).tointeger()
  return {
    size = 0
    pos = [nodePos.x, nodePos.y]
    halign = ALIGN_CENTER
    valign = valign
    padding = padding
    opacity = opacity
    children = [
      {
        size = [size, size]
        children = [
          {
            size = [size, size]
            rendObj = ROBJ_BOX
            borderWidth = border ? borderWidth : 0
            borderColor = color
            transform = { rotate }
          }
          {
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            rendObj = ROBJ_IMAGE
            size = [iconSize, iconSize]
            image = Picture($"{icon}:{iconSize}:{iconSize}:P")
            color = color
            keepAspect = KEEP_ASPECT_FIT
          }
        ]
      }
    ]
  }
}

function onPathNodeHold() {
  movingNodeId(holdedNodeId)
  movingNodeOffset(movingNodeOffset.value)
}

function mkWarningNode(nodeId, nodePos, nodeSize, hintStr) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    behavior = Behaviors.Button
    rendObj = ROBJ_IMAGE
    size = [nodeSize, nodeSize]
    image = Picture($"{debugIconWarning}:{nodeSize}:{nodeSize}:P")
    onClick = @(evt) showHint(evt.targetRect, hintStr, 3)
    onAttach = @() (nodeId == selectedNodeId.value) ? showHint([nodePos.x, nodePos.y], hintStr, 3) : null
  }
}

function mkPathNode(nodeType, nodeId, nodePos, warningStr) {
  local { icon, size, padding, color, valign, border, rotate, opacity } = getNodeStyle(nodeType)
  let iconSize = (size * 0.85).tointeger()
  let warningSize = (size * 0.45).tointeger()
  let isMoving = Computed(@() nodeId != -1 && nodeId == movingNodeId.value)
  let isSelected = Computed(@() nodeId != -1 && nodeId == selectedNodeId.value && !isMoving.value)

  return @() {
    watch = [isSelected, isMoving]
    size = 0
    padding = padding
    pos = [nodePos.x, nodePos.y]
    halign = ALIGN_CENTER
    valign = valign
    opacity = isSelected.value ? 1 : opacity
    children = [
      {
        size = [size, size]
        behavior = Behaviors.MoveResize
        moveResizeModes = MR_AREA

        function onMoveResizeStarted(x, y, bbox) {
          local clickOffsetX = x - bbox.x;
          local clickOffsetY = y - bbox.y;

          movingNodeAlignOffset.x = -size/2

          if (valign == ALIGN_CENTER)
            movingNodeAlignOffset.y = -size/2
          else if (valign == ALIGN_BOTTOM)
            movingNodeAlignOffset.y = -size - padding;
          else if (valign == ALIGN_TOP)
            movingNodeAlignOffset.y = padding;
          else
            movingNodeAlignOffset.y = 0

          movingNodeOffset(Point2(clickOffsetX, clickOffsetY) + movingNodeAlignOffset)

          holdedNodeId = nodeId
          resetTimeout(0.5, onPathNodeHold)
        }

        function onMoveResize(dx, dy, _, _) {
          if(fabs(dx) > 0 || fabs(dy) > 0) {
            clearTimer(onPathNodeHold)
            if (nodeId == holdedNodeId) {
              movingNodeOffset(movingNodeOffset.value + Point2(dx, dy))
              movingNodeId(nodeId)
            }
          }
          return null
        }

        function onMoveResizeFinished() {
          onNodeClick(nodeType, nodeId, -1, nodePos)
          if(movingNodeId.value == nodeId) {
            onNodeMove(nodeType, nodeId, nodePos)
            pathRefreshUi()
          }
          movingNodeId(-1)
          clearTimer(onPathNodeHold)
          holdedNodeId = -1
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
          !isMoving.value
            ? {
              hplace = ALIGN_CENTER
              vplace = ALIGN_CENTER
              rendObj = ROBJ_IMAGE
              size = [iconSize, iconSize]
              image = Picture($"{icon}:{iconSize}:{iconSize}:P")
              color = color
              keepAspect = true
            }
            : {
              rendObj = ROBJ_IMAGE
              hplace = ALIGN_CENTER
              vplace = valign
              size = [iconSize, iconSize]
              image = Picture($"{icon}:{iconSize}:{iconSize}:P")
              color = imageColor
              keepAspect = true
              opacity = 0.75
              transform = { translate = [0, hdpx(-25)], scale = [1.5, 1.5] }
              animations = [
                { prop = AnimProp.scale, from = [0.5, 0.5], to = [1.5, 1.5], duration = 0.3, easing = OutQuad, play = true }
                { prop = AnimProp.translate, from = [0, 0], to = [0, hdpx(-25)], duration = 0.3, easing = OutQuad, play = true }
              ]
            }
        ]
      }
      warningStr ? mkWarningNode(nodeId, nodePos, warningSize, warningStr) : null
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
    size = 0
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
  local attackNodesCount = 0

  foreach(node in data.nodes) {
    local nodePos = (movingNodeId.value != -1 && node.id == movingNodeId.value)
      ? node.pos2 + movingNodeOffset.value
      : node.pos2

    local ui = null
    if (node.type == NODE_SELF) {
      ui = mkSelfNode(node.pos2)
    }
    else {
      local warningStr = null
      if (node.type == NODE_ORDER_ATTACK) {
        if (attackNodesCount > 0 || (data.isLaunched && data.groupBombs == 0 && data.groupTorpedos == 0)) {
          warningStr = loc("strategyMode/attack_can_be_failed")
        }
        attackNodesCount++
      }
      ui = mkPathNode(node.type, node.id, nodePos, warningStr)
    }

    if (ui)
      nodesUi.append(ui)

    if (optDebugDraw.get()) {
      nodesUi.append({
        rendObj = ROBJ_TEXT
        color = debugTextColor
        pos = [nodePos.x, nodePos.y]
        text = $"ID={node.id}, {node.pos3}"
      })
    }

    let edgeId = node.id
    let edgeColor = (edgeId == selectedNodeId.value)
      ? getNodeStyle(node.type).edgeColorSelected
      : getNodeStyle(node.type).edgeColor

    edgesUi.append([VECTOR_COLOR, edgeColor])
    edgesUi.append([VECTOR_FILL_COLOR, getNodeStyle(node.type).color])
    edgesUi.append([VECTOR_ELLIPSE, nodePos.x, nodePos.y, hdpx(7), hdpx(7)])

    if (i > 0) {
      let edgePos = midPoint(edgePrevPos, nodePos)
      edgesUi.append([VECTOR_COLOR, edgeColor])
      edgesUi.append([VECTOR_FILL_COLOR, edgeColor])
      edgesUi.append([VECTOR_LINE, edgePrevPos.x, edgePrevPos.y, nodePos.x, nodePos.y])
      edgesUi.append([VECTOR_FILL_COLOR, getNodeStyle(node.type).color])
      edgesUi.append([VECTOR_ELLIPSE, nodePos.x, nodePos.y, hdpx(7), hdpx(7)])

      if(node.type != NODE_ORDER_RETURN)
        nodesUi.append(mkPathEdgeButton(edgePos, edgeId, edgeColor))
    }

    if(node.type != NODE_ORDER_RETURN)
      edgePrevPos = nodePos

    i++
  }

  if (movingNodeId.value == -1 && (selectedPosIsValid.value || selectedUnitId.value != -1)) {
    let pendingDstPos = getSelectionPos2d(selectedPos.value, selectedUnitId.value)
    let pendingSrcPos = (selectedPosIsValid.value) ? edgePrevPos : getSelectionPos2d(selectedPos.value, -1)
    let pendingIcon = (selectedUnitId.value != -1) ? iconSelectedUnit : iconPointPending
    let pendingIconVAlign = (selectedUnitId.value != -1) ? ALIGN_CENTER : ALIGN_BOTTOM
    let pendingIconSize = hdpxi(100)

    edgesUi.append([VECTOR_COLOR, edgeColorPending])
    edgesUi.append([VECTOR_LINE_DASHED, pendingSrcPos.x, pendingSrcPos.y, pendingDstPos.x, pendingDstPos.y, hdpx(10), hdpx(20)])

    nodesUi.append({
      size = 0
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
    size = 100
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

function mkCommandsUi(groupIndex) {
  let isWorldPointSelected = Computed(@() selectedEdgeId.value == -1 && selectedPosIsValid.value)
  let isAttackAllowed = Computed(@() selectedUnitId.value != -1 && selectedUnitIsEnemy.value)
  let isDeffendAllowed = Computed(@() selectedUnitId.value != -1 && !selectedUnitIsEnemy.value)
  let isHuntAllowed = Computed(@() selectedUnitId.value == -1 && (isWorldPointSelected.value || selectedNodeType.value == NODE_ORDER_POINT))
  let isPointAllowed = Computed(@() selectedUnitId.value == -1 && (isWorldPointSelected.value || selectedNodeType.value == NODE_ORDER_HUNT))
  let isPointClearAllowed = Computed(@() selectedEdgeId.value == -1 && (selectedNodeId.value != -1 || (curAirGroupPathLength.get() > 1 && !curAirGroupIsReturning.get())))
  let isPointInsertAllowed = Computed(@() selectedNodeId.value == -1 && selectedEdgeId.value != -1)
  let isAllwaysEnabled = Watched(true)
  return {
    hplace = ALIGN_LEFT
    vplace = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = [
      groupIndex == -1 ? null : {
        hplace = ALIGN_LEFT
        vplace = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(10)
        children = [
          @() {
            watch = [selectedUnitIsFlyModel, curAttackIcon]
            children = mkCommandButton(
              "ATTACK",
              curAttackIcon.value,
              selectedUnitIsFlyModel.value ? curAirGroupCanAttackAir : curAirGroupCanAttackGround,
              isAttackAllowed,
              @() onNodeEditClick(NODE_ORDER_ATTACK)
            )
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

let pathNodesUi = @() {
  size = flex()
  watch = strategyDataCur
  children = strategyDataCur.get() ? mkNodesUi(strategyDataCur.get()) : null
}

function textButtonDisabled(label, hintStr) {
  let styleOvr = {
    ovr = {
      fillColor = 0xFF323232
    }
    gradientOvr = {
      color = 0xFF323232
    }
    childOvr = {
      color = 0xFF505050
    }
  }
  return textButtonPrimary(label, @(evt) showHint(evt.targetRect, hintStr, 3), styleOvr)
}

let pathCommandsUi = @() {
  watch = [curGroupIndex, curAirGroupIsLaunched, curAirGroupPathLength]
  hplace = ALIGN_LEFT
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = hdpx(40)
  children = [
    mkCommandsUi(curGroupIndex.get()),
    {
      hplace = ALIGN_LEFT
      vplace = ALIGN_BOTTOM
      flow = FLOW_HORIZONTAL
      gap = hdpx(40)
      children = [
        curAirGroupIsLaunched.get()
          ? textButtonSecondary(utf8ToUpper(loc("strategyMode/take_control")), onPathLaunch)
        : curAirGroupPathLength.get() > 1
          ? textButtonPrimary(utf8ToUpper(loc("strategyMode/launch")), onPathLaunch)
        : textButtonDisabled(utf8ToUpper(loc("strategyMode/launch")), loc("strategyMode/empty_path"))
        textButtonBright(utf8ToUpper(loc("strategyMode/abort_mission")), onPathAbort)
      ]
    }
  ]
}

return {
  pathSelectPoint
  pathSelectZone
  pathSelectionReset

  pathNodesUi
  pathCommandsUi

  pathRefreshUi
}
