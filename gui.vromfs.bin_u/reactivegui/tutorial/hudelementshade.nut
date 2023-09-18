from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { getBox, incBoxSize, createHighlight, findGoodArrowPos, sizePosToBox
} = require("tutorialWnd/tutorialUtils.nut")
let { lightCtor, darkCtor, pointerArrow, mkPointerArrow } = require("tutorialWnd/tutorialWndDefStyle.nut")
let { register_command } = require("console")
let { getNativeElementBoxes } = require("hudSelectionShade")
let { elements, sizeIncDef, pushedArrowColor } = require("hudElementsCfg.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let isHudShadeAtached = Watched(false)
let lastShadeEvent = mkWatched(persist, "lastShadeEvent", null)
let isHudShadeActive = Computed(@() isHudShadeAtached.value && (lastShadeEvent.value?.enabled ?? false))

subscribe("hudElementSelectionShade", @(ev) lastShadeEvent(ev))
isInBattle.subscribe(@(_) lastShadeEvent(null))

let staticUpdateInterval = 0.5
let dynamicUpdateInterval = 0.02

let updateInterval = keepref(Computed(@() !isHudShadeActive.value ? 0
  : (lastShadeEvent.value?.hasNativeElements ?? false) ? dynamicUpdateInterval
  : staticUpdateInterval))

let curElements = Computed(function() {
  let res = []
  foreach (e in (lastShadeEvent.value?.elements ?? []))
    if (e in elements)
      res.extend(elements[e])
  return res
})

let curBoxes = Watched([])
let pushedBoxes = Watched({})
isHudShadeAtached.subscribe(@(_) pushedBoxes({}))

let function updateCurBoxes() {
  let boxes = []
  foreach (idx, cfg in curElements.value ?? []) {
    local { sizeInc = sizeIncDef, objs = null } = cfg
    local box = getBox(objs ?? cfg) //when not table, cfg is objs
    if (box == null)
      continue
    let isValid = box.r - box.l > 0 && box.b - box.t > 0
    if (isValid)
      box = incBoxSize(box, sizeInc)
    box.id <- idx
    boxes.append(box)
  }
  boxes.extend(getNativeElementBoxes())

  if (!isEqual(curBoxes.value, boxes))
    curBoxes(boxes)
}

updateInterval.subscribe(function(interval) {
  clearTimer(updateCurBoxes)
  if (interval <= 0)
    return
  updateCurBoxes()
  setInterval(interval, updateCurBoxes)
})

local function mkArrows(boxes, obstaclesVar) {
  boxes = boxes.filter(@(b) b.r - b.l > 0 && b.b - b.t > 0)
  if (boxes.len() == 0)
    return null
  let size = calc_comp_size(pointerArrow)
  let children = []
  foreach (box in boxes) {
    let { pos, rotate } = findGoodArrowPos(box, size, obstaclesVar)
    obstaclesVar.append(sizePosToBox(size, pos))
    let { id } = box
    if (id < 0)
      continue;
    let ovr = Computed(@() (pushedBoxes.value?[id] ?? false) ? { color = pushedArrowColor } : {})
    children.append(mkPointerArrow(ovr).__merge({ pos, transform = { rotate } }))
  }
  return {
    size = flex()
    children
  }
}

let lightCtorExt = @(box) lightCtor(box, {
  onElemState = @(s) pushedBoxes.mutate(@(list) list[box.id] <- (s & S_ACTIVE) != 0)
  eventPassThrough = true
})

let shadeKey = {}
let hudElementShade = @() {
  watch = [curBoxes, isHudShadeActive]
  key = shadeKey
  size = flex()
  onAttach = @() isHudShadeAtached(true)
  onDetach = @() isHudShadeAtached(false)
  children = !isHudShadeActive.value ? null
    : createHighlight(curBoxes.value, lightCtorExt, darkCtor)
        .append(mkArrows(curBoxes.value, []))
}

register_command(function(ids) {
  if (type(ids) == "string")
    ids = [ids]
  let elems = []
  foreach (id in ids) {
    if (id in elements)
      elems.append(id)
    else if (id != "")
      log($"{id} - unknown element")
  }
  lastShadeEvent({ enabled = (elems.len() != 0), elements = elems })
  },
  "debug.hudShade")

return {
  hudElementShade
  isHudShadeActive
}