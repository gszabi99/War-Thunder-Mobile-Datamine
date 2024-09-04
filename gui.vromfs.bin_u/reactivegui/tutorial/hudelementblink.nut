from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { eventbus_subscribe } = require("eventbus")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")

let { getBox, incBoxSize, findGoodArrowPos, sizePosToBox } = require("tutorialWnd/tutorialUtils.nut")
let { pointerArrow } = require("tutorialWnd/tutorialWndDefStyle.nut")
let { elements, sizeIncDef } = require("hudElementsCfg.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let arrowHlType = "arrow"
let highLightTypes = {
  [arrowHlType] = true
}

let staticUpdateInterval = 0.5

let isHudBlinkAttached = Watched(false)
let blinkState = Watched({})
let lastBlinkEvent = mkWatched(persist, "lastBlinkEvent", {})
let isHudBlinkActive = Computed(@() isHudBlinkAttached.get() && blinkState.get().findvalue(@(v) v.len() > 0) != null)

function resetState() {
  blinkState.set({})
  lastBlinkEvent.set({})
}

eventbus_subscribe("hudElementBlink", @(ev) lastBlinkEvent.set(ev))
isInBattle.subscribe(@(_) resetState())

let updateInterval = keepref(Computed(@() !isHudBlinkActive.get() ? 0 : staticUpdateInterval))

let curElements = Computed(function() {
  let res = {}
  foreach (hlType, blinkStateElements in blinkState.get()) {
    res[hlType] <- []
    foreach (e, _ in blinkStateElements)
      if (e in elements)
        res[hlType].extend(elements[e])
  }
  return res
})

let curBoxes = Watched({})
let arrowCurBoxes = Computed(@() curBoxes.get()?[arrowHlType] ?? [])

function updateCurBoxes() {
  let boxes = highLightTypes.map(@(_) [])
  foreach (hlType, elems in curElements.get()) {
    if (!highLightTypes?[hlType])
      continue
    foreach (idx, cfg in elems) {
      let { sizeInc = sizeIncDef, objs = null } = cfg
      local box = getBox(objs ?? cfg) //when not table, cfg is objs
      if (box == null)
        continue
      let isValid = box.r - box.l > 0 && box.b - box.t > 0
      if (isValid)
        box = incBoxSize(box, sizeInc)
      box.id <- idx
      boxes[hlType].append(box)
    }
  }

  if (!isEqual(curBoxes.get(), boxes))
    curBoxes.set(boxes)
}

lastBlinkEvent.subscribe(function(evt) {
  let { highLightType = null } = evt
  if (!highLightTypes?[highLightType])
    return
  let res = clone blinkState.get()
  if (res?[highLightType] == null)
    res[highLightType] <- {}
  foreach (evtElem in evt?.elements ?? []) {
    if (evt.enabled)
      res[highLightType][evtElem] <- true
    else
      res[highLightType].$rawdelete(evtElem)
  }
  if (res[highLightType].len() == 0)
    res.$rawdelete(highLightType)
  blinkState.set(res)
  updateCurBoxes()
})

updateInterval.subscribe(function(interval) {
  clearTimer(updateCurBoxes)
  updateCurBoxes()
  if (interval <= 0)
    return
  setInterval(interval, updateCurBoxes)
})

function mkArrows() {
  let boxes = arrowCurBoxes.get().filter(@(b) b.r - b.l > 0 && b.b - b.t > 0)
  if (boxes.len() == 0)
    return { watch = arrowCurBoxes }
  let size = calc_comp_size(pointerArrow)
  let obstaclesVar = []
  let children = []
  foreach (box in boxes) {
    let { pos, rotate } = findGoodArrowPos(box, size, obstaclesVar)
    obstaclesVar.append(sizePosToBox(size, pos))
    if (box.id < 0)
      continue
    children.append(pointerArrow.__merge({ pos, transform = { rotate } }))
  }
  return {
    watch = arrowCurBoxes
    size = flex()
    children
  }
}

let shadeKey = {}
let hudElementBlink = {
  key = shadeKey
  size = flex()
  onAttach = @() isHudBlinkAttached.set(true)
  onDetach = @() isHudBlinkAttached.set(false)
  children = mkArrows
}

function debugHudBlink(ids, highLightType, enabled) {
  let res = {}
  if (highLightTypes?[highLightType])
    res.highLightType <- highLightType
  else
    console_print($"{highLightType} - unknown type") // warning disable: -forbidden-function
  if (type(ids) == "string")
    ids = [ids]
  let elems = []
  foreach (id in ids) {
    if (id in elements)
      elems.append(id)
    else if (id != "")
      console_print($"{id} - unknown element") // warning disable: -forbidden-function
  }
  lastBlinkEvent.set(res.__update({ enabled, elements = elems }))
  console_print(blinkState.get()) // warning disable: -forbidden-function
}

register_command(@(ids, highLightType) debugHudBlink(ids, highLightType, true), "debug.hudBlinkEnable")
register_command(@(ids, highLightType) debugHudBlink(ids, highLightType, false), "debug.hudBlinkDisable")

return {
  hudElementBlink
}