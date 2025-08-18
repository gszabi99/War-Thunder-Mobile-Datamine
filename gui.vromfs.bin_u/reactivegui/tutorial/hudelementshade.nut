from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { getBox, incBoxSize, createHighlight, findGoodArrowPos, sizePosToBox
} = require("%rGui/tutorial/tutorialWnd/tutorialUtils.nut")
let { lightCtor, darkCtor, pointerArrow, mkPointerArrow } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")
let { register_command } = require("console")
let { getNativeElementBoxes } = require("hudSelectionShade")
let { elements, sizeIncDef, pushedArrowColor } = require("%rGui/tutorial/hudElementsCfg.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let isHudShadeAtached = Watched(false)
let lastShadeEvent = mkWatched(persist, "lastShadeEvent", null)
let isHudShadeActive = Computed(@() isHudShadeAtached.get() && (lastShadeEvent.get()?.enabled ?? false))

eventbus_subscribe("hudElementSelectionShade", @(ev) lastShadeEvent.set(ev))
isInBattle.subscribe(@(_) lastShadeEvent.set(null))

let staticUpdateInterval = 0.5
let dynamicUpdateInterval = 0.02

let updateInterval = keepref(Computed(@() !isHudShadeActive.get() ? 0
  : (lastShadeEvent.get()?.hasNativeElements ?? false) ? dynamicUpdateInterval
  : staticUpdateInterval))

let curElements = Computed(function() {
  let res = []
  foreach (e in (lastShadeEvent.get()?.elements ?? []))
    if (e in elements)
      res.extend(elements[e])
  return res
})

let curBoxes = Watched([])
let pushedBoxes = Watched({})
isHudShadeAtached.subscribe(@(_) pushedBoxes.set({}))

function updateCurBoxes() {
  let boxes = []
  foreach (idx, cfg in curElements.get() ?? []) {
    local { sizeInc = sizeIncDef, objs = null } = cfg
    local box = getBox(objs ?? cfg) 
    if (box == null)
      continue
    let isValid = box.r - box.l > 0 && box.b - box.t > 0
    if (isValid)
      box = incBoxSize(box, sizeInc)
    box.id <- idx
    boxes.append(box)
  }
  boxes.extend(getNativeElementBoxes())

  if (!isEqual(curBoxes.get(), boxes))
    curBoxes.set(boxes)
}

updateInterval.subscribe(function(interval) {
  clearTimer(updateCurBoxes)
  if (interval <= 0)
    return
  updateCurBoxes()
  setInterval(interval, updateCurBoxes)
})

function mkArrows(boxes, obstaclesVar) {
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
    let ovr = Computed(@() (pushedBoxes.get()?[id] ?? false) ? { color = pushedArrowColor } : {})
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
  onAttach = @() isHudShadeAtached.set(true)
  onDetach = @() isHudShadeAtached.set(false)
  children = !isHudShadeActive.get() ? null
    : createHighlight(curBoxes.get(), lightCtorExt, darkCtor)
        .append(mkArrows(curBoxes.get(), []))
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
  lastShadeEvent.set({ enabled = (elems.len() != 0), elements = elems })
  },
  "debug.hudShade")

return {
  hudElementShade
  isHudShadeActive
}