from "%globalsDarg/darg_library.nut" import *
from "dagor.math" import Point2
from "guiStrategyMode" import cameraGetZoom, cameraSetZoom, cameraAddOffset
from "math" import fabs
from "%rGui/hud/strategyMode/strategyPathView.nut" import pathSelectPoint, pathSelectZone, pathRefreshUi
from "%rGui/hud/strategyMode/strategyState.nut" import optMoveCameraByDrag
from "%rGui/style/hudColors.nut" import hudWhiteColor


const zoomMin = 0.1
const zoomMax = 1.0
const zoomDefault = 0.5
const zoomActiveMin = 0
const zoomActiveMax = 1.1
const zoomAnimateTime = 0.3

local cameraState = {
  zoom = zoomDefault
}

local pointerState = {
  active = false
  start = Point2()
  prev = Point2()
}

local zoneSelectionState = Watched({
  active = false
  pos0 = Point2()
  pos1 = Point2()
})

function isPosWithin(p0, p1) {
  return fabs(p0.x - p1.x) < hdpx(15) && fabs(p0.y - p1.y) < hdpx(15)
}

function onZoneSelectionMove(x0, y0, x1, y1) {
  zoneSelectionState.set({
    active = true
    pos0 = Point2(min(x0, x1), min(y0, y1))
    pos1 = Point2(max(x0, x1), max(y0, y1))
  })
}

function onZoneSelectionEnd() {
  if (!zoneSelectionState.get().active)
    return

  zoneSelectionState.mutate(function(v) { v.active = false })
  pathSelectZone(
    zoneSelectionState.get().pos0.x,
    zoneSelectionState.get().pos0.y,
    zoneSelectionState.get().pos1.x,
    zoneSelectionState.get().pos1.y)
}

function onPointerPress(evt) {
  if (evt.accumRes & R_PROCESSED)
    return 0
  if (!evt.hit)
    return 0

  pointerState.active = true
  pointerState.start = Point2(evt.x, evt.y)
  pointerState.prev = pointerState.start
  return 1
}

function onPointerMove(evt) {
  if (!pointerState.active)
    return 0

  if (optMoveCameraByDrag.get()) {
    let isPointerPosWithin = isPosWithin(pointerState.start, Point2(evt.x, evt.y))
    if (!isPointerPosWithin)
      onZoneSelectionMove(pointerState.start.x, pointerState.start.y, evt.x, evt.y)
  }
  else {
    let offsetX = evt.x - pointerState.prev.x
    let offsetY = evt.y - pointerState.prev.y
    cameraAddOffset(Point2(offsetX, offsetY))
    pathRefreshUi()
  }

  pointerState.prev = Point2(evt.x, evt.y)
  return 1
}

function onPointerRelease(evt) {
  if (!pointerState.active)
    return 0

  let isPointerPosWithin = isPosWithin(pointerState.start, Point2(evt.x, evt.y))
  if (isPointerPosWithin) {
    pathSelectPoint(evt.x, evt.y)
  }
  else if (optMoveCameraByDrag.get()) {
    onZoneSelectionMove(pointerState.start.x, pointerState.start.y, evt.x, evt.y)
  }

  pointerState.active = false
  onZoneSelectionEnd()

  return 1
}

function onGestureBegin(evt) {
  if (evt.type == GESTURE_DETECTOR_PINCH) {
    cameraState.zoom = cameraGetZoom()
  }
}

function onGestureActive(evt) {
  if (evt.type == GESTURE_DETECTOR_DRAG) {
    if (optMoveCameraByDrag.get()) {
      cameraAddOffset(Point2(evt.dx, evt.dy))
      pathRefreshUi()
    }
  }

  if (evt.type == GESTURE_DETECTOR_PINCH) {
    if (evt.scale > 0) {
      let newActiveZoom = clamp(cameraState.zoom / evt.scale, zoomActiveMin, zoomActiveMax)
      cameraSetZoom(newActiveZoom, 0.0)
      pathRefreshUi()
    }
  }
}

function onGestureEnd(evt) {
  if (evt.type == GESTURE_DETECTOR_PINCH) {
    let finalZoom = clamp(cameraState.zoom / evt.scale, zoomMin, zoomMax)
    cameraSetZoom(finalZoom, zoomAnimateTime)
  }
}

function mkSelectionZone(x0, y0, x1, y1) {
  return {
    rendObj = ROBJ_BOX
    pos = [x0, y0]
    size = [x1 - x0, y1 - y0]
    opacity = 0.5
    borderWidth = 1
    borderColor = hudWhiteColor
  }
}

let pathInputUi = {
  size = FLEX
  children = [
    {
      size = FLEX
      behavior = Behaviors.ProcessPointingInput
      onPointerPress
      onPointerMove
      onPointerRelease
    }
    {
      size = FLEX
      behavior = Behaviors.ProcessGesture
      onGestureBegin
      onGestureActive
      onGestureEnd
      gestureDragDistanceMax = 500
    }
    @() {
      size = FLEX
      watch = zoneSelectionState
      children = !zoneSelectionState.get().active ? null
      : mkSelectionZone(
        zoneSelectionState.get().pos0.x,
        zoneSelectionState.get().pos0.y,
        zoneSelectionState.get().pos1.x,
        zoneSelectionState.get().pos1.y
      )
    }
  ]
}

return {
  pathInputUi
}
