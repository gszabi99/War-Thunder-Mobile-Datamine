from "%globalsDarg/darg_library.nut" import *
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")
let { isEqual } = require("%sqstd/underscore.nut")

let scenes = {} //id = { scene, onClearScenes }
let scenesVersion = Watched(0)
let scenesOrderSaved = mkHardWatched("navState.scenesOrder", [])
let scenesOrder = Computed(function(prev) {
  let ver = scenesVersion //warning disable: -declared-never-used
  let res = scenesOrderSaved.value.filter(@(v) v in scenes)
  return isEqual(prev, res) ? prev : res
})

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

let function registerScene(id, scene, onClearScenes = null, isOpenedWatch = null) {
  if (id in scenes) {
    logerr($"Already registered navState scene {id}")
    return
  }
  scenes[id] <- { scene, onClearScenes }
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

return {
  scenesOrder
  registerScene
  moveSceneToTop
  getTopScene
  addScene
  removeScene
}
