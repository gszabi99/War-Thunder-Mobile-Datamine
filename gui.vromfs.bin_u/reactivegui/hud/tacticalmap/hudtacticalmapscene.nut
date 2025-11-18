from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%rGui/hudState.nut" import unitType
from "%rGui/components/backButton.nut" import backButton, backButtonHeight
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/hudColors.nut" import hudWhiteColor, hudBlackColor
from "%rGui/hud/tacticalMap/tacticalMapMarkersLayer.nut" import tacticalMapMarkersLayer

let mapSizePx = min(saSize[1], saSize[0] * 0.5625)

let isTacticalMapSceneOpened = mkWatched(persist, "isTacticalMapSceneOpened", false)
let close = @() isTacticalMapSceneOpened.set(false)

isInBattle.subscribe(@(_) close())
eventbus_subscribe("MissionResult", @(_) close())
eventbus_subscribe("LocalPlayerDead", @(_) close())
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
  size = flex()
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
