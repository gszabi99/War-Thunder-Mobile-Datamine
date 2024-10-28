from "%globalsDarg/darg_library.nut" import *
from "hudTuningConsts.nut" import *
let { get_time_msec } = require("dagor.time")
let { abs } = require("%sqstd/math.nut")
let { cfgByUnitTypeOrdered } = require("cfgByUnitType.nut")
let { tuningUnitType, transformInProgress, isElemHold, applyTransformProgress, selectedId
} = require("hudTuningState.nut")

let INC_AREA = sh(2)
let START_MOVE_TIME_MSEC = 300
let MOVE_MIN_THRESHOLD = sh(1) //ignore threshold after START_MOVE_TIME
let pointer = Watched(null)

let isHit = @(aabb, x, y) aabb.l <= x && aabb.r >= x && aabb.t <= y && aabb.b >= y
let isHitInc = @(aabb, x, y) aabb.l - INC_AREA <= x && aabb.r + INC_AREA >= x
  && aabb.t - INC_AREA <= y && aabb.b + INC_AREA >= y

function findElemInScene(x, y) {
  let list = cfgByUnitTypeOrdered?[tuningUnitType.value]
  if (list == null)
    return null

  let prevId = selectedId.get()
  let prevIdx = prevId == null ? -1 : list.findindex(@(c) c.id == prevId) ?? -1
  let total = list.len()

  local resByInc = null
  for (local i = prevIdx + 1; i <= prevIdx + total; i++) {
    let cfg = list[i % total]
    let { id } = cfg
    let aabb = gui_scene.getCompAABBbyKey(cfg?.editView.key)
    if (aabb == null)
      continue
    if (isHit(aabb, x, y))
      return { id, aabb }
    if (resByInc == null && isHitInc(aabb, x, y))
      resByInc = { id, aabb }
  }
  return resByInc
}

function getAabbIfHit(id, x, y) {
  if (id == null)
    return null
  let cfg = cfgByUnitTypeOrdered?[tuningUnitType.get()].findvalue(@(c) c.id == id)
  if (cfg == null)
    return null
  let aabb = gui_scene.getCompAABBbyKey(cfg?.editView.key)
  return aabb != null && isHitInc(aabb, x, y) ? aabb : null
}

pointer.subscribe(function(p) {
  if (p == null)
    return
  let { isInProgress, offset, aabb } = p
  if (!isInProgress || (transformInProgress.value == null && offset[0] == 0 && offset[1] == 0))
    return

  let halfX = (aabb.r - aabb.l) / 2
  let halfY = (aabb.b - aabb.t) / 2
  let cx = clamp((aabb.l + aabb.r) / 2 + offset[0], halfX, sw(100) - halfX) - saBorders[0]
  let cy = clamp((aabb.t + aabb.b) / 2 + offset[1], halfY, sh(100) - halfY) - saBorders[1]
  let alignH = cx < 0.4 * saSize[0] ? ALIGN_L
    : cx > 0.6 * saSize[0] ? ALIGN_R
    : 0
  let alignV = cy < 0.3 * saSize[1] ? ALIGN_T
    : ALIGN_B

  let x = alignH & ALIGN_R ? cx + halfX - saSize[0]
    : alignH & ALIGN_L ? cx - halfX
    : cx - saSize[0] / 2
  let y = alignV & ALIGN_B ? cy + halfY - saSize[1]
    : cy - halfY
  transformInProgress({ align = alignH | alignV, pos = [x, y] })
})

let manipulator = {
  key = {}
  size = flex()
  behavior = Behaviors.ProcessPointingInput
  touchMarginPriority = TOUCH_BACKGROUND
  function onPointerPress(evt) {
    if ((evt.accumRes & R_PROCESSED) != 0
        || (pointer.value != null && pointer.value.id != evt.pointerId))
      return 0
    local aabb = getAabbIfHit(selectedId.get(), evt.x, evt.y)
    local isChangedOnPress = false
    if (aabb == null) {
      let elem = findElemInScene(evt.x, evt.y)
      isChangedOnPress = selectedId.get() != elem?.id
      selectedId.set(elem?.id)
      aabb = elem?.aabb
    }
    if (aabb != null) {
      pointer.set({ id = evt.pointerId, time = get_time_msec(),
        start = [evt.x, evt.y], offset = [0, 0],
        aabb, isChangedOnPress, isInProgress = false
      })
      isElemHold(true)
    }
    return 1
  }
  function onPointerRelease(evt) {
    if (pointer.value?.id != evt.pointerId)
      return 0

    if (pointer.get() != null) {
      let { isChangedOnPress, time } = pointer.get()
      if (!isChangedOnPress && get_time_msec() < time + START_MOVE_TIME_MSEC) {
        let elem = findElemInScene(evt.x, evt.y)
        if (elem != null)
          selectedId.set(elem.id == selectedId.get() ? null : elem.id)
      }
    }

    applyTransformProgress()
    pointer(null)
    isElemHold(false)
    return 1
  }
  function onPointerMove(evt) {
    if (pointer.value?.id != evt.pointerId)
      return 0
    let { x, y } = evt
    if (!pointer.value.isInProgress
        && pointer.value.time + START_MOVE_TIME_MSEC > get_time_msec()
        && abs(pointer.value.start[0] - x) < MOVE_MIN_THRESHOLD
        && abs(pointer.value.start[1] - y) < MOVE_MIN_THRESHOLD)
      return 1
    pointer.mutate(@(v) v.__update({
      isInProgress = true
      offset = [x - v.start[0], y - v.start[1]]
    }))
    return 0
  }
  function onDetach() {
    transformInProgress(null)
    pointer(null)
    isElemHold(false)
  }
}

return manipulator