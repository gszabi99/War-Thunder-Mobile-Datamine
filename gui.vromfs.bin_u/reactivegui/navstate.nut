from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isEqual } = require("%sqstd/underscore.nut")

let scenes = {} //id = { scene, onClearScenes, alwaysOnTop }
let scenesVersion = Watched(0)
let scenesOrderSaved = hardPersistWatched("navState.scenesOrder", [])
let sceneBgList = Watched({})
let scenesOrder = Computed(function(prev) {
  let ver = scenesVersion //warning disable: -declared-never-used
  let top = []
  let res = []
  foreach(s in scenesOrderSaved.value) {
    if (s not in scenes)
      continue
    else if (scenes[s].alwaysOnTop)
      top.append(s)
    else
      res.append(s)
  }
  res.extend(top)
  return isEqual(prev, res) ? prev : res
})

let curSceneBgRaw = keepref(Computed(@() sceneBgList.value?[scenesOrder.value?[scenesOrder.value.len() - 1]]))
let curSceneBg = Watched(curSceneBgRaw.get())
curSceneBgRaw.subscribe(@(_) deferOnce(@() curSceneBg.set(curSceneBgRaw.get())))

let getTopScene = @(order) order.len() == 0 ? null : scenes[order.top()]?.scene

let function addScene(id) {
  if (id not in scenes) {
    logerr($"Try to open not registerd navState scene {id}")
    return
  }

  scenesOrderSaved.mutate(function(v) {
    let idx = v.indexof(id)
    if (idx != null)
      v.remove(idx)
    v.append(id)
  })
}

let function removeScene(id) {
  let idx = scenesOrderSaved.value.indexof(id)
  if (idx != null)
    scenesOrderSaved.mutate(@(v) v.remove(idx))
}

let function registerScene(id, scene, onClearScenes = null, isOpenedWatch = null, alwaysOnTop = false, canClear = null) {
  if (id in scenes) {
    logerr($"Already registered navState scene {id}")
    return
  }
  scenes[id] <- { id, scene, onClearScenes, alwaysOnTop, canClear }
  scenesVersion(scenesVersion.value + 1)

  if (isOpenedWatch == null)
    return

  let show = @(v) v ? addScene(id) : removeScene(id)
  let isOpened = scenesOrderSaved.value.indexof(id) != null
  if (isOpenedWatch.value != isOpened)
    show(isOpenedWatch.value)
  isOpenedWatch.subscribe(show)
}

let function moveSceneToTop(id) {
  let idx = scenesOrderSaved.value.indexof(id)
  if (idx == null)
    return
  scenesOrderSaved.mutate(function(v) {
    v.remove(idx)
    v.append(id)
  })
}

let function clearScenes() {
  let prev = clone scenesOrder.value //in case of open new scene by onClearScenes
  scenesOrderSaved([])
  foreach (id in prev)
    scenes?[id].onClearScenes()
}

isInBattle.subscribe(@(_) clearScenes())
isAuthorized.subscribe(@(v) v ? null : clearScenes())

let function canResetToMainScene() {
  return scenesOrderSaved.value.reduce(@(val, id) val && (scenes?[id].canClear() ?? true), true)
}

let function tryResetToMainScene() {
  let res = canResetToMainScene()
  if (res)
    clearScenes()
  return res
}

let setSceneBg = @(id, bg) sceneBgList.mutate(@(v) v.rawset(id, bg))

return {
  scenesOrder
  registerScene
  getTopScene
  curSceneBg

  addScene
  removeScene
  moveSceneToTop
  tryResetToMainScene
  canResetToMainScene
  setSceneBg
}
