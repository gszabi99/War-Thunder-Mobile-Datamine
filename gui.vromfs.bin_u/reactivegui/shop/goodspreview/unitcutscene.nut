from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "dagor.workcycle" import deferOnce
from "blkGetters" import get_settings_blk
from "dagor.random" import rnd_int
from "hangar" import start_prem_cutscene, stop_prem_cutscene, get_prem_cutscene_preset_ids,
  SHIP_PRESET_TYPE, SUBMARINE_PRESET_TYPE, TANK_PRESET_TYPE, AIR_FIGHTER_PRESET_TYPE,
  AIR_BOMBER_PRESET_TYPE
from "%appGlobals/unitConst.nut" import SHIP, AIR
from "%appGlobals/unitTags.nut" import getUnitTags
from "%rGui/unit/hangarUnit.nut" import loadedHangarUnitName, loadedHangarUnitSkin,
  needReloadHangarBattleData
from "%rGui/shop/blackOverlay.nut" import showBlackOverlay, closeBlackOverlay


let cutSceneWaitForVisualsLoaded = get_settings_blk()?.unitOffer.cutSceneWaitForVisualsLoaded ?? false
let transitionThroughBlackScreen = get_settings_blk()?.unitOffer.transitionThroughBlackScreen ?? false

let unitForCutscene = Watched(null)
let readyToShowCutScene = mkWatched(persist, "readyToShowCutScene", false)
eventbus_subscribe("onHangarModelStartLoad", @(_) readyToShowCutScene.set(false))
eventbus_subscribe(cutSceneWaitForVisualsLoaded ? "onHangarModelVisualsLoaded" : "onHangarModelLoaded", @(_) readyToShowCutScene.set(true))

let needShowCutscene = keepref(Computed(@() unitForCutscene.get() != null
  && loadedHangarUnitName.get() == (unitForCutscene.get()?.name ?? "")
  && loadedHangarUnitSkin.get()
    == (unitForCutscene.get()?.skin ?? unitForCutscene.get()?.currentSkins[unitForCutscene.get()?.name ?? ""] ?? "")
  && readyToShowCutScene.get()
  && !needReloadHangarBattleData.get()))

function showCutscene() {
  if (!needShowCutscene.get()) {
    stop_prem_cutscene()
    return
  }

  let unitType = unitForCutscene.get()?.unitType ?? ""
  local presetType = TANK_PRESET_TYPE
  let tags = getUnitTags(unitForCutscene.get().name)
  if (unitType == SHIP) {
    if  (tags?.submarine == true)
      presetType = SUBMARINE_PRESET_TYPE
    else
      presetType = SHIP_PRESET_TYPE
  }
  else if (unitType == AIR) {
    if (tags?.type_fighter == true || tags?.type_strike_aircraft == true)
      presetType = AIR_FIGHTER_PRESET_TYPE
    else
      presetType = AIR_BOMBER_PRESET_TYPE
  }
  let presetIds = get_prem_cutscene_preset_ids(presetType)
  if(presetIds.len() > 0)
    start_prem_cutscene(presetIds[rnd_int(0, presetIds.len()-1)])
}
showCutscene()
needShowCutscene.subscribe(@(_) deferOnce(showCutscene))

function closeBlackOverlayOnceOnVisualsLoaded(loaded) {
  if (loaded) {
    closeBlackOverlay()
    readyToShowCutScene.unsubscribe(closeBlackOverlayOnceOnVisualsLoaded)
  }
}

unitForCutscene.subscribe(function(v) {
  if (v == null || !transitionThroughBlackScreen || readyToShowCutScene.get()) {
    closeBlackOverlay()
    return
  }
  showBlackOverlay()
  readyToShowCutScene.subscribe(closeBlackOverlayOnceOnVisualsLoaded)
})

return {
  unitForCutscene
}