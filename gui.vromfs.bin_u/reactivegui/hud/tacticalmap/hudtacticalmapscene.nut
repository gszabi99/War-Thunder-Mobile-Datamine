from "%globalScripts/gameRendObjs.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "guiTacticalMap" import setShowWholeTrack
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%rGui/components/backButton.nut" import backButton
from "%rGui/hud/hudEventManager.nut" import subscribeHudEvent
from "%rGui/hud/tacticalMap/tacticalMapMarkersLayer.nut" import tacticalMapMarkersLayer
from "%rGui/hudState.nut" import unitType
from "%rGui/missionState.nut" import isGtRace
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


let mapSizePx = min(saSize[1], saSize[0] * 0.5625)

let isTacticalMapSceneOpened = mkWatched(persist, "isTacticalMapSceneOpened", false)
let close = @() isTacticalMapSceneOpened.set(false)

isTacticalMapSceneOpened.subscribe(@(isOpened) setShowWholeTrack(isOpened && isGtRace.get()))

isInBattle.subscribe(@(_) close())
subscribeHudEvent("MissionResult", @(_) close())
subscribeHudEvent("LocalPlayerDead", @(_) close())
unitType.subscribe(@(_) @(_) close())

function reinit() {
}

isTacticalMapSceneOpened.subscribe(@(v) v ? reinit() : null)

let tacticalMap = {
  size = [ mapSizePx, mapSizePx ]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TACTICAL_MAP
  children = tacticalMapMarkersLayer
}

let tacticalMapScene = bgShaded.__merge({
  key = {}
  size = FLEX
  padding = saBordersRv
  children = [
    backButton(close)
    tacticalMap
  ]
  animations = wndSwitchAnim
})

return {
  isTacticalMapSceneOpened
  tacticalMapScene
}
