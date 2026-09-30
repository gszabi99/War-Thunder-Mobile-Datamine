from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/loginState.nut" import isAuthorized
from "%globalsDarg/loading/loadingScreensCfg.nut" import screensList
from "%rGui/loading/mkAnimBgWithGyro.nut" import mkAnimBgWithGyro
from "%rGui/navState.nut" import curSceneBg, curSceneBgFallback
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "types" import String


let scenesList = []
let sceneListGeneration = mkWatched(persist, "sceneListGeneration", 0)

function mkSceneBgImage(sceneBg, fallback) {
  let { bg = null, bgColor = null } = sceneBg ?? {}

  return bg in screensList
    ? {
        key = bg
        size = FLEX
        children = mkAnimBgWithGyro(screensList[bg].mkLayers() ?? [])
        animations = wndSwitchAnim
      }
    : bg == "" ? null
    : {
        key = bg
        size = FLEX
        rendObj = ROBJ_IMAGE
        image = Picture(bg)
        fallbackImage = Picture(fallback)
        color = bgColor ?? 0xFFFFFFFF
        keepAspect = KEEP_ASPECT_FILL
        animations = wndSwitchAnim
      }
}

function mkSceneBgDim(sceneBg) {
  let dimColor = sceneBg?.dimColor ?? 0

  return dimColor == 0 ? null
    : {
        key = dimColor
        size = FLEX
        rendObj = ROBJ_SOLID
        color = dimColor
        animations = wndSwitchAnim
      }
}

let behindScene = {
  size = FLEX
  children = [
    @() {
      watch = [curSceneBg, curSceneBgFallback]
      size = FLEX
      children = [
        mkSceneBgImage(curSceneBg.get(), curSceneBgFallback.get())
        mkSceneBgDim(curSceneBg.get())
      ]
    }
    @() {
      watch = sceneListGeneration
      key = sceneListGeneration
      size = FLEX
      children = scenesList.map(@(v) v.scene)
    }
  ]
}

let getIdx = @(componentOrId) componentOrId instanceof String
  ? scenesList.findindex(@(v) v.id == componentOrId)
  : scenesList.findindex(@(v) v.scene == componentOrId)

function addBehindScene(component, onClearScenes = null, uid = null) {
  local id = uid instanceof String ? uid : null
  let idx = getIdx(id ?? component)
  if (idx != null)
    scenesList.remove(idx)
  id = id ?? $"_{sceneListGeneration.get()}"
  scenesList.append({ scene = component, id, onClearScenes })
  sceneListGeneration.set(sceneListGeneration.get() + 1)
  return id
}

function removeBehindScene(componentOrId) {
  let idx = getIdx(componentOrId)
  if (idx == null)
    return
  scenesList.remove(idx)
  sceneListGeneration.set(sceneListGeneration.get() + 1)
}

function clearScenes() {
  let prev = clone scenesList 
  scenesList.clear()
  sceneListGeneration.set(sceneListGeneration.get() + 1)
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
