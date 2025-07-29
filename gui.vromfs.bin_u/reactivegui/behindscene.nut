from "%globalsDarg/darg_library.nut" import *
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let { curSceneBg, curSceneBgFallback } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")

let scenesList = []
let sceneListGeneration = mkWatched(persist, "sceneListGeneration", 0)

let behindScene = {
  size = flex()
  children = [
    @() {
      watch = [curSceneBg, curSceneBgFallback]
      size = flex()
      children = {
        key = curSceneBg.get()
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture(curSceneBg.get())
        fallbackImage = Picture(curSceneBgFallback.get())
        keepAspect = KEEP_ASPECT_FILL
        animations = wndSwitchAnim
      }
    }
    @() {
      watch = sceneListGeneration
      key = sceneListGeneration
      size = flex()
      children = scenesList.map(@(v) v.scene)
    }
  ]
}

let getIdx = @(componentOrId) type(componentOrId) == "string"
  ? scenesList.findindex(@(v) v.id == componentOrId)
  : scenesList.findindex(@(v) v.scene == componentOrId)

function addBehindScene(component, onClearScenes = null, uid = null) {
  local id = type(uid) == "string" ? uid : null
  let idx = getIdx(id ?? component)
  if (idx != null)
    scenesList.remove(idx)
  id = id ?? $"_{sceneListGeneration.value}"
  scenesList.append({ scene = component, id, onClearScenes })
  sceneListGeneration(sceneListGeneration.value + 1)
  return id
}

function removeBehindScene(componentOrId) {
  let idx = getIdx(componentOrId)
  if (idx == null)
    return
  scenesList.remove(idx)
  sceneListGeneration(sceneListGeneration.value + 1)
}

function clearScenes() {
  let prev = clone scenesList 
  scenesList.clear()
  sceneListGeneration(sceneListGeneration.value + 1)
  foreach (scene in prev)
    scene.onClearScenes?()
}

isInBattle.subscribe(@(_) clearScenes())
isAuthorized.subscribe(@(v) v ? null : clearScenes())

return {
  behindScene
  addBehindScene
  removeBehindScene
}
