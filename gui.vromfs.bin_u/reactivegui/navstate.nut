from "%globalsDarg/darg_library.nut" import *
let logNS = log_with_prefix("[NAV_STATE] ")
let { deferOnce } = require("dagor.workcycle")
let { ComputedImmediate } = require("%sqstd/frp.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isEqual } = require("%sqstd/underscore.nut")

let scenes = {} 
let scenesVersion = Watched(0)
let scenesOrderSaved = hardPersistWatched("navState.scenesOrder", [])
let sceneBgList = Watched({})
let sceneBgListFallback = Watched({})
let scenesOrder = ComputedImmediate(function(prev) {
  let ver = scenesVersion 
  let top = []
  let res = []
  foreach(s in scenesOrderSaved.get()) {
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

let curSceneBgRaw = keepref(Computed(@() sceneBgList.get()?[scenesOrder.get()?[scenesOrder.get().len() - 1]]))
let curSceneBg = Watched(curSceneBgRaw.get())
curSceneBgRaw.subscribe(@(_) deferOnce(@() curSceneBg.set(curSceneBgRaw.get())))
let curSceneBgFallbackRaw = keepref(Computed(@() sceneBgListFallback.get()?[scenesOrder.get()?[scenesOrder.get().len() - 1]]))
let curSceneBgFallback = Watched(curSceneBgFallbackRaw.get())
curSceneBgFallbackRaw.subscribe(@(_) deferOnce(@() curSceneBgFallback.set(curSceneBgFallbackRaw.get())))

let getTopScene = @(order) order.len() == 0 ? null : scenes[order.top()]?.scene

function addScene(id) {
  if (id not in scenes) {
    logerr($"Try to open not registerd navState scene {id}")
    return
  }

  scenesOrderSaved.mutate(function(v) {
    let idx = v.indexof(id)
    if (idx != null) {
      logNS($"Refresh scene {id}")
      v.remove(idx)
    }
    else
      logNS($"Add scene {id}")
    v.append(id)
  })
}

function removeScene(id) {
  let idx = scenesOrderSaved.get().indexof(id)
  if (idx == null)
    return
  logNS($"Remove scene {id}")
  scenesOrderSaved.mutate(@(v) v.remove(idx))
}

function moveSceneToTop(id) {
  let idx = scenesOrderSaved.get().indexof(id)
  if (idx == null)
    return false
  logNS($"Move scene to top {id}")
  scenesOrderSaved.mutate(function(v) {
    v.remove(idx)
    v.append(id)
  })
  return true
}

function registerScene(id, scene, onClearScenes = null, openedCounterWatch = null, alwaysOnTop = false, canClear = null) {
  if (id in scenes) {
    logerr($"Already registered navState scene {id}")
    return
  }
  scenes[id] <- { id, scene, onClearScenes, alwaysOnTop, canClear }
  scenesVersion.set(scenesVersion.get() + 1)

  if (openedCounterWatch == null)
    return

  let isOpenedWatch = ComputedImmediate(@() type(openedCounterWatch.get()) == "bool" ? openedCounterWatch.get()
    : openedCounterWatch.get() > 0)
  let isOpened = scenesOrderSaved.get().indexof(id) != null

  function show(_) {
    if (!isOpenedWatch.get())
      removeScene(id)
    else if (!moveSceneToTop(id))
      addScene(id)
  }
  openedCounterWatch.subscribe(show)
  if (isOpenedWatch.get() != isOpened)
    show(null)
}

function clearScenes() {
  let prev = clone scenesOrder.get() 
  scenesOrderSaved.set([])
  foreach (id in prev)
    scenes?[id].onClearScenes()
}

isInBattle.subscribe(@(_) clearScenes())
isAuthorized.subscribe(@(v) v ? null : clearScenes())

function canResetToMainScene() {
  return scenesOrderSaved.get().reduce(@(val, id) val && (scenes?[id].canClear() ?? true), true)
}

function tryResetToMainScene() {
  let res = canResetToMainScene()
  if (res)
    clearScenes()
  return res
}

let setSceneBg = @(id, bg) sceneBgList.mutate(@(v) v.rawset(id, bg))
let setSceneBgFallback = @(id, bg) sceneBgListFallback.mutate(@(v) v.rawset(id, bg))

return {
  scenesOrder
  registerScene
  getTopScene
  curSceneBg
  curSceneBgFallback

  addScene
  removeScene
  moveSceneToTop
  tryResetToMainScene
  canResetToMainScene
  setSceneBg
  setSceneBgFallback
}
