from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { abs } = require("math")
let { transformInProgress, applyTransformProgress, tuningPoints, tuningBgElems, selectedElem,
  ELEM_POINT, ELEM_BG, ELEM_LINE, ELEM_MIDPOINT, selectElem, getElemKey, presetLines,
  presetMapSize, isShiftPressed, selectedLineIdx, selectedLineMidpoints, scalableETypes
} = require("mapEditorState.nut")
let { INC_AREA, START_MOVE_TIME_MSEC, MOVE_MIN_THRESHOLD } = require("mapEditorConsts.nut")
let { shiftActions } = require("comboActions.nut")
let { getClosestSegment, mkLineSplinePoints } = require("%rGui/event/treeEvent/segmentMath.nut")


let M_DEFAULT = ""
let M_SCALE = "scale"

let pointer = Watched(null)
let emptyAABB = { l = 0, t = 0, r = 0, b = 0 }
let isMovable = [ELEM_POINT, ELEM_BG, ELEM_MIDPOINT].reduce(@(res, v) res.$rawset(v, true), {})

let isHit = @(aabb, x, y) aabb.l <= x && aabb.r >= x && aabb.t <= y && aabb.b >= y
let isHitInc = @(aabb, x, y) aabb.l - INC_AREA <= x && aabb.r + INC_AREA >= x
  && aabb.t - INC_AREA <= y && aabb.b + INC_AREA >= y

let moveAabb = @(aabb, offsetX, offsetY) {
  l = aabb.l + offsetX
  t = aabb.t + offsetY
  r = aabb.r + offsetX
  b = aabb.b + offsetY
}

let relHitInfo = {
  [ELEM_LINE] = function getHitInfoLine(id, x, y, incSize) {
    let line = presetLines.get()?[id]
    if (line == null)
      return null

    let all = mkLineSplinePoints(line, tuningPoints.get())
    let { dist, idx } = getClosestSegment(all, x, y)
    return idx < 0 || dist > 1.5 * incSize ? null
      : { aabb = emptyAABB, isDirect = dist < 0.5 * incSize }
  }
}

let getMapRelCoords = @(mapAabb, mapSize, x, y) [ //x, y, incSize
  (x - mapAabb.l).tofloat() / (mapAabb.r - mapAabb.l) * mapSize[0],
  (y - mapAabb.t).tofloat() / (mapAabb.b - mapAabb.t) * mapSize[1],
  INC_AREA.tofloat() / (mapAabb.r - mapAabb.l) * mapSize[0]
]

function findElemInScene(x, y, isNext, isFit = @(_) true) {
  let mapAabb = gui_scene.getCompAABBbyKey("mapEditorMap")
  if (mapAabb == null || mapAabb.r == mapAabb.l || mapAabb.t == mapAabb.b)
    return null

  let list = [].extend(
    selectedLineMidpoints.get().map(@(_, i) { id = i, eType = ELEM_MIDPOINT, subId = selectedLineIdx.get() })
    tuningPoints.get().reduce(@(acc, _, id) acc.append({ id, eType = ELEM_POINT }), []),
    tuningBgElems.get().map(@(_, i) { id = i, eType = ELEM_BG }),
    presetLines.get().map(@(_, i) { id = i, eType = ELEM_LINE }))

  let prevId = selectedElem.get()?.id
  let prevEType = selectedElem.get()?.eType
  let prevSubId = selectedElem.get()?.subId
  let prevIdx = prevId == null || !isNext ? -1
    : list.findindex(@(c) c.id == prevId && c.eType == prevEType && c?.subId == prevSubId) ?? -1
  let total = list.len()
  let [relX, relY, incSize] = getMapRelCoords(mapAabb, presetMapSize.get(), x, y)

  local resByInc = null
  for (local i = prevIdx + 1; i <= prevIdx + total; i++) {
    let cfg = list[i % total]
    if (!isFit(cfg))
      continue
    let { id, eType, subId = null } = cfg
    if (eType in relHitInfo) {
      let { aabb = null, isDirect = false } = relHitInfo[eType](id, relX, relY, incSize)
      if (aabb == null)
        continue
      if (isDirect)
        return { id, eType, aabb, subId }
      if (resByInc == null)
        resByInc = { id, eType, aabb, subId }
      continue
    }

    let aabb = gui_scene.getCompAABBbyKey(getElemKey(id, eType))
    if (aabb == null)
      continue

    if (subId != null) {
      if (isHitInc(aabb, x, y))
        return { id, eType, aabb, subId }
      continue
    }

    if (isHit(aabb, x, y))
      return { id, eType, aabb }
    if (resByInc == null && isHitInc(aabb, x, y))
      resByInc = { id, eType, aabb }
  }
  return resByInc
}

function getAabbIfHit(elem, x, y) {
  let { id = null, eType = null } = elem
  if (id == null)
    return null
  if (eType not in relHitInfo) {
    let aabb = gui_scene.getCompAABBbyKey(getElemKey(id, eType))
    return aabb != null && isHitInc(aabb, x, y) ? aabb : null
  }

  let mapAabb = gui_scene.getCompAABBbyKey("mapEditorMap")
  if (mapAabb == null)
    return null
  let [relX, relY, incSize] = getMapRelCoords(mapAabb, presetMapSize.get(), x, y)
  let { aabb = null } = relHitInfo[eType](id, relX, relY, incSize)
  return aabb
}

function getCurMapRelCoords(x, y) {
  let mapAabb = gui_scene.getCompAABBbyKey("mapEditorMap")
  if (mapAabb == null)
    return [0, 0, 0]
  return getMapRelCoords(mapAabb, presetMapSize.get(), x, y)
}

let updateTransform = {
  [M_DEFAULT] = function(p) {
    if (!isMovable?[selectedElem.get()?.eType])
      return

    let { aabb, mapAabb, offset } = p
    let mapW = mapAabb.r - mapAabb.l
    let mapH = mapAabb.b - mapAabb.t
    let objW = aabb.r - aabb.l
    let objH = aabb.b - aabb.t

    local newLeft = aabb.l + offset[0]
    local newTop  = aabb.t + offset[1]
    newLeft = clamp(newLeft, -objW * 3 / 4, mapW - objW / 4)
    newTop  = clamp(newTop, -objH * 3 / 4, mapH - objH / 4)

    transformInProgress.set({ pos = [newLeft, newTop], mapSizePx = [mapW, mapH] })
  },

  [M_SCALE] = function(p) {
    if (!scalableETypes?[selectedElem.get()?.eType])
      return

    let { aabb, mapAabb, offset, start } = p

    let mid = [
      (aabb.r + aabb.l) / 2 + mapAabb.l,
      (aabb.b + aabb.t) / 2 + mapAabb.t,
    ]
    let o = offset.map(@(v, a) start[a] > mid[a] ? v : -v)

    let mapSizePx = [mapAabb.r - mapAabb.l, mapAabb.b - mapAabb.t]
    let sizeBase = [aabb.r - aabb.l, aabb.b - aabb.t]
    let size = sizeBase.map(@(v, a) v + o[a] * 2)
    let flip = [false, false]
    foreach (a, v in size)
      if (v < 0) {
        size[a] = -v
        flip[a] = true
        o[a] = - sizeBase[a] - o[a]
      }
    let pos = [aabb.l - o[0], aabb.t - o[1]]
      .map(@(v, a) clamp(v, -size[a] * 3 / 4, mapSizePx[a] - size[a] / 4))
    transformInProgress.set({ size, pos, mapSizePx, flip })
  }
}

pointer.subscribe(function(p) {
  if (p == null || !p.isInProgress || (transformInProgress.get() == null && p.offset[0] == 0 && p.offset[1] == 0))
    return
  updateTransform?[p?.mode ?? M_DEFAULT](p)
})

let isElemSame = @(e1, e2) (e1?.id == e2?.id) && (e1?.eType == e2?.eType) && (e1?.subId == e2?.subId)

let wasMoved = @(pointerV, x, y) pointerV.time + START_MOVE_TIME_MSEC > get_time_msec()
  && abs(pointerV.start[0] - x) < MOVE_MIN_THRESHOLD
  && abs(pointerV.start[1] - y) < MOVE_MIN_THRESHOLD

let manipulator = {
  key = {}
  size = flex()
  behavior = Behaviors.ProcessPointingInput
  touchMarginPriority = TOUCH_BACKGROUND
  function onPointerPress(evt) {
    if ((evt.accumRes & R_PROCESSED) != 0
        || (pointer.get() != null && pointer.get().id != evt.pointerId))
      return 0

    if (evt.ctrlKey && scalableETypes?[selectedElem.get()?.eType]) {
      let mapAabb = gui_scene.getCompAABBbyKey("mapEditorMap")
      let aabb = gui_scene.getCompAABBbyKey(getElemKey(selectedElem.get()?.id, selectedElem.get().eType))
      if (mapAabb != null && aabb != null)
        pointer.set({
          id = evt.pointerId
          mode = M_SCALE
          time = get_time_msec()
          start = [evt.x, evt.y]
          offset = [0, 0]
          aabb = moveAabb(aabb, -mapAabb.l, -mapAabb.t)
          isChangedOnPress = false
          mapAabb
          isInProgress = false
        })
      return 1
    }

    if (isShiftPressed.get() && selectedElem.get() != null) {
      let { process = null } = shiftActions?[selectedElem.get().eType]
      if (process != null)
        if (process(selectedElem.get().id,
            @(isFit) findElemInScene(evt.x, evt.y, true, isFit),
            @() getCurMapRelCoords(evt.x, evt.y)))
          return 1
    }

    local aabb = getAabbIfHit(selectedElem.get(), evt.x, evt.y)
    local isChangedOnPress = false
    if (aabb == null) {
      let elem = findElemInScene(evt.x, evt.y, false)
      let isSame = isElemSame(selectedElem.get(), elem)
      isChangedOnPress = !isSame
      if (!isSame)
        selectElem(elem?.id, elem?.eType, elem?.subId)
      aabb = elem?.aabb
    }

    if (aabb != null) {
      let mapAabb = gui_scene.getCompAABBbyKey("mapEditorMap") ?? emptyAABB
      pointer.set({
        id = evt.pointerId
        time = get_time_msec()
        start = [evt.x, evt.y]
        offset = [0, 0]
        aabb = moveAabb(aabb, -mapAabb.l, -mapAabb.t)
        mapAabb
        isChangedOnPress
        isInProgress = false
      })
    }

    return 1
  }
  function onPointerRelease(evt) {
    if (pointer.get()?.id != evt.pointerId)
      return 0

    if (pointer.get() != null && pointer.get()?.mode != M_SCALE) {
      let { isChangedOnPress } = pointer.get()
      if (!isChangedOnPress && wasMoved(pointer.get(), evt.x, evt.y)) {
        let elem = findElemInScene(evt.x, evt.y, true)
        if (elem != null)
          selectElem(isElemSame(selectedElem.get(), elem) ? null : elem.id, elem.eType, elem?.subId)
      }
    }

    applyTransformProgress()
    pointer.set(null)
    return 1
  }

  function onPointerMove(evt) {
    if (pointer.get()?.id != evt.pointerId)
      return 0
    let { x, y } = evt
    if (!pointer.get().isInProgress && wasMoved(pointer.get(), x, y))
      return 1
    pointer.mutate(@(v) v.__update({
      isInProgress = true
      offset = [x - v.start[0], y - v.start[1]]
    }))
    return 1
  }
  function onDetach() {
    transformInProgress.set(null)
    pointer.set(null)
  }
}

return manipulator
