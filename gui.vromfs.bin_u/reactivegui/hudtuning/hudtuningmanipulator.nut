from "%globalsDarg/darg_library.nut" import *
from "hudTuningConsts.nut" import *
let { get_time_msec } = require("dagor.time")
let { abs } = require("%sqstd/math.nut")
let cfgByUnitType = require("cfgByUnitType.nut")
let { tuningUnitType, transformInProgress, applyTransformProgress, selectedId
} = require("hudTuningState.nut")

let INC_AREA = sh(2)
let START_MOVE_TIME_MSEC = 300
let MOVE_MIN_THRESHOLD = sh(1) //ignore threshold after START_MOVE_TIME
let pointer = Watched(null)

function findElemInScene(x, y) {
  let list = cfgByUnitType?[tuningUnitType.value]
  if (list == null)
    return null

  local resByInc = null
  foreach(id, cfg in list) {
    let aabb = gui_scene.getCompAABBbyKey(cfg?.editView.key)
    if (aabb == null)
      continue
    if (aabb.l <= x && aabb.r >= x
        && aabb.t <= y && aabb.b >= y)
      return { id, aabb }
    if (resByInc == null
        && aabb.l - INC_AREA <= x && aabb.r + INC_AREA >= x
        && aabb.t - INC_AREA <= y && aabb.b + INC_AREA >= y)
      resByInc = { id, aabb }
  }
  return resByInc
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
  function onPointerPress(evt) {
    if (evt.accumRes == R_PROCESSED
        || (pointer.value != null && pointer.value.id != evt.pointerId))
      return 0
    let elem = findElemInScene(evt.x, evt.y)
    selectedId(elem?.id)
    if (elem != null)
      pointer({ id = evt.pointerId, time = get_time_msec(),
        start = [evt.x, evt.y], offset = [0, 0],
        aabb = elem.aabb, isInProgress = false
      })
    return 1
  }
  function onPointerRelease(evt) {
    if (pointer.value?.id != evt.pointerId)
      return 0
    applyTransformProgress()
    pointer(null)
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
  }
}

return manipulator