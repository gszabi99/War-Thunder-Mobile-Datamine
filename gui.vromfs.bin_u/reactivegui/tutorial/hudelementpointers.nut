from "%globalsDarg/darg_library.nut" import *
let { setInterval, clearTimer, resetTimeout } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { isEqual } = require("%sqstd/underscore.nut")
let { getBox, incBoxSize, findGoodArrowPos, sizePosToBox, leftArrowPos, rightArrowPos
} = require("%rGui/tutorial/tutorialWnd/tutorialUtils.nut")
let { pointerArrow } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")
let { register_command } = require("console")
let { elements, sizeIncDef } = require("%rGui/tutorial/hudElementsCfg.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let isHudPointersAtached = Watched(false)
let activeIds = mkWatched(persist, "activeIds", {})
let nextExpire = keepref(Computed(@() activeIds.get().reduce(@(res, v) res == 0 ? v : min(res, v), 0)))

let curElements = Computed(@() activeIds.get().map(@(_, id) elements?[id])
  .filter(@(v) v != null))

let isActive = Computed(@() isHudPointersAtached.get() && curElements.get().len() > 0)
let updateInterval = keepref(Computed(@() isActive.get() ? 0.5 : 0))
let curBoxes = Watched([])

isInBattle.subscribe(@(_) activeIds.set({}))

function updateExpires() {
  if (activeIds.get().len() == 0)
    return
  let time = get_time_msec()
  let newActive = activeIds.get().filter(@(t) t - time > 100)
  if (newActive.len() != activeIds.get().len())
    activeIds.set(newActive)
}
updateExpires()

function startExpireTimer(next) {
  if (next > 0)
    resetTimeout(0.001 * (next - get_time_msec()), updateExpires)
}
nextExpire.subscribe(startExpireTimer)
startExpireTimer(nextExpire.value)

function updateCurBoxes() {
  let boxes = []
  foreach (key, configs in curElements.get())
    foreach (cfg in configs) {
      let { sizeInc = sizeIncDef, objs = null } = cfg
      local box = getBox(objs ?? cfg) 
      if (box == null)
        continue
      let isValid = box.r - box.l > 0 && box.b - box.t > 0
      if (!isValid)
        continue
      box = incBoxSize(box, sizeInc)
      box.id <- key
      boxes.append(type(cfg) == "table" ? cfg.__merge(box) : box)
    }

  if (!isEqual(curBoxes.get(), boxes))
    curBoxes.set(boxes)
}
curElements.subscribe(@(_) updateCurBoxes())

function updateBoxesTimers(interval) {
  clearTimer(updateCurBoxes)
  if (interval <= 0)
    return
  updateCurBoxes()
  setInterval(interval, updateCurBoxes)
}
updateInterval.subscribe(updateBoxesTimers)
updateBoxesTimers(updateInterval.value)

let arrowAnimations = [
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.2, easing = OutQuad, play = true }
  { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, easing = OutQuad, playFadeOut = true }
]

function addArrow(orient, box, size, obstacles, res) {
  local { pos, rotate } = orient
  pos[0] += box?.arrowOffset[0] ?? 0.
  pos[1] += box?.arrowOffset[1] ?? 0.
  obstacles.append(sizePosToBox(size, pos))
  res.append(pointerArrow.__merge({
    key = box.id
    pos
    transform = { rotate }
    animations = arrowAnimations
  }))
}

function mkArrows(boxes) {
  if (boxes.len() == 0)
    return []
  let obstacles = clone boxes

  let size = calc_comp_size(pointerArrow)
  let res = []
  foreach (box in boxes) {
      if (box?.isDouble) {
        addArrow(leftArrowPos(box, size), box, size, obstacles, res)
        addArrow(rightArrowPos(box, size), box, size, obstacles, res)
      }
      else
        addArrow(findGoodArrowPos(box, size, obstacles), box, size, obstacles, res)
  }
  return res
}

let pointersKey = {}
let hudElementPointers = @() {
  watch = curBoxes
  key = pointersKey
  size = flex()
  onAttach = @() isHudPointersAtached.set(true)
  onDetach = @() isHudPointersAtached.set(false)
  children = mkArrows(curBoxes.get())
}

function addHudElementPointer(id, time) {
  if (type(id) == "array") {
    activeIds.mutate(function(v) {
      foreach(localId in id){
        v[localId] <- get_time_msec() + (1000 * time).tointeger()
      }
    })
  }
  else
    activeIds.mutate(@(v) v[id] <- get_time_msec() + (1000 * time).tointeger())
}

function removeHudElementPointer(id) {
  if (id in activeIds.get() ) {
    activeIds.mutate(@(v) v.$rawdelete(id))
    return
  }
  else if (type(id) == "array") {
    activeIds.mutate(function(v) {
      foreach(localId in id){
        v?.$rawdelete(localId)
      }
    })
  }
}
register_command(addHudElementPointer,
  "debug.hudPointer")

return {
  hudElementPointers
  addHudElementPointer
  removeHudElementPointer
}