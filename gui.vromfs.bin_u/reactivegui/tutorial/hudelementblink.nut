from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { eventbus_subscribe } = require("eventbus")
let { setInterval, clearTimer, resetTimeout } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { isEqual } = require("%sqstd/underscore.nut")

let { getBox, incBoxSize, findGoodArrowPos, sizePosToBox } = require("tutorialWnd/tutorialUtils.nut")
let { pointerArrow } = require("tutorialWnd/tutorialWndDefStyle.nut")
let hudElementsCfg = require("hudElementsCfg.nut")
let { sizeIncDef } = hudElementsCfg
let hudElements = hudElementsCfg.elements
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")


let arrowHlType = "arrow"
let highLightTypes = {
  [arrowHlType] = true
}

let staticUpdateInterval = 0.5

let isHudBlinkAttached = Watched(false)
let activeBlinkElems = mkWatched(persist, "activeBlinkElems", {})
let curBoxes = Watched({})
let arrowCurBoxes = Computed(@() curBoxes.get()?[arrowHlType] ?? {})

let highlights = Computed(function(prev) {
  let res = {}
  foreach(elem, cfg in activeBlinkElems.get()) {
    let { highLightType } = cfg
    if (!highLightTypes?[highLightType])
      continue
    let hudCfg = hudElements?[elem]
    if (hudCfg == null)
      continue
    if (highLightType not in res)
      res[highLightType] <- {}
    res[highLightType][elem] <- hudCfg
  }
  return isEqual(res, prev) ? prev : res
})

let elementBlinks = Computed(function(prev) {
  let res = {}
  foreach(elem, cfg in activeBlinkElems.get())
    if (cfg.blink)
      res[elem] <- true
  return isEqual(res, prev) ? prev : res
})

let isHudHighlightActive = Computed(@() isHudBlinkAttached.get() && highlights.get().len() > 0)
let updateInterval = keepref(Computed(@() !isHudHighlightActive.get() ? 0 : staticUpdateInterval))

let reset = @() activeBlinkElems.set({})
isInBattle.subscribe(@(_) reset())

function onHudElementBlink(evt) {
  let { time = 0, enabled = true, highLightType = "", elements = [], blink = false } = evt
  activeBlinkElems.mutate(function(v) {
    let shouldAdd = blink || (highLightType != "" && enabled)
    foreach(e in elements)
      if (!shouldAdd && e in v)
        v.$rawdelete(e)
      else if (shouldAdd)
        v[e] <- { blink, highLightType, endTimeMsec = time > 0 ? get_time_msec() + (1000 * time).tointeger() : 0 }
  })
}

eventbus_subscribe("hudElementBlink", onHudElementBlink)

function updateInactivityTimer() {
  let timeMsec = get_time_msec()
  let newElems = activeBlinkElems.get().filter(@(e) e.endTimeMsec <= 0 || e.endTimeMsec > timeMsec)
  if (newElems.len() != activeBlinkElems.get().len())
    activeBlinkElems.set(newElems)
  let nextTime = activeBlinkElems.get()
    .reduce(@(res, e) e.endTimeMsec <= 0 ? res
        : res == 0 ? e.endTimeMsec
        : min(res, e.endTimeMsec),
      0)
  if (nextTime > 0)
    resetTimeout(max(0.01, (nextTime - timeMsec) * 0.001), updateInactivityTimer)
}
updateInactivityTimer()
activeBlinkElems.subscribe(@(_) resetTimeout(0.01, updateInactivityTimer))

function updateCurBoxes() {
  let boxes = highlights.get().map(
    function(cfgList) {
      let list = []
      foreach(cfg in cfgList)
        foreach(elemCfg in cfg) {
          let { sizeInc = sizeIncDef, objs = null } = elemCfg
          local box = getBox(objs ?? elemCfg) //when not table, cfg is objs
          if (box == null || box.r - box.l <= 0 || box.b - box.t <= 0)
            continue
          box = incBoxSize(box, sizeInc)
          list.append(box)
        }
      return list
    })

  if (!isEqual(curBoxes.get(), boxes))
    curBoxes.set(boxes)
}

highlights.subscribe(@(_) updateCurBoxes())

updateInterval.subscribe(function(interval) {
  clearTimer(updateCurBoxes)
  updateCurBoxes()
  if (interval <= 0)
    return
  setInterval(interval, updateCurBoxes)
})

function arrows() {
  let boxes = arrowCurBoxes.get()
  if (boxes.len() == 0)
    return { watch = arrowCurBoxes }
  let size = calc_comp_size(pointerArrow)
  let obstacles = clone boxes
  let children = []
  foreach (box in boxes) {
    let { pos, rotate } = findGoodArrowPos(box, size, obstacles)
    obstacles.append(sizePosToBox(size, pos))
    children.append(pointerArrow.__merge({ pos, transform = { rotate } }))
  }
  return {
    watch = arrowCurBoxes
    size = flex()
    children
  }
}

let hudElementBlink = {
  key = highlights
  size = flex()
  onAttach = @() isHudBlinkAttached.set(true)
  onDetach = @() isHudBlinkAttached.set(false)
  children = arrows
}

function debugHudBlinkArrow(id, time) {
  if (id not in hudElements) {
    console_print($"{id} - unknown element") // warning disable: -forbidden-function
    return
  }
  let enabled = time > 0 || id not in activeBlinkElems.get()

  onHudElementBlink({ time, enabled, highLightType = arrowHlType, elements = [id] })
  console_print($"enabled = {enabled}") // warning disable: -forbidden-function
}

function debugHudBlink(id, time) {
  let blink = time > 0 || id not in activeBlinkElems.get()
  onHudElementBlink({ time, blink, elements = [id] })
  console_print($"blink = {blink}") // warning disable: -forbidden-function
}

register_command(debugHudBlinkArrow, "debug.hudBlinkArrow")
register_command(debugHudBlink, "debug.hudBlink")
register_command(reset, "debug.hudBlinkReset")

return {
  hudElementBlink
  elementBlinks
}