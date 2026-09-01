from "%globalScripts/gameRendObjs.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/clientState/clientState.nut" import isInMpSession
from "%globalsDarg/screenMath.nut" import scaleArr
from "%rGui/controls/shortcutSimpleComps.nut" import mkGamepadShortcutImage, mkGamepadHotkey
from "%rGui/hud/hudTouchButtonStyle.nut" import borderColor
from "%rGui/hud/tacticalMap/hudTacticalMapScene.nut" import isTacticalMapSceneOpened
from "%rGui/hud/tacticalMap/tacticalMapMarkersLayer.nut" import tacticalMapMarkersLayer
from "%rGui/hud/voiceMsg/hudVoiceMsgMapScene.nut" import isVoiceMsgMapSceneOpened
from "%rGui/hud/voiceMsg/voiceMsgState.nut" import isVoiceMsgEnabled


let tacticalMapSize = [hdpx(325), hdpx(325)]

let commonMinimapLayers = [
  {
    size = FLEX
    rendObj = ROBJ_SOLID
    color = 0x28000000
  }
  {
    key = "tactical_map"
    size = FLEX
    rendObj = ROBJ_TACTICAL_MAP
  }
  tacticalMapMarkersLayer
]

let mkTacticalMap = @(size, extraLayers = []) {
  size
  children = [].extend(commonMinimapLayers, extraLayers)
}

let tacticalMap = mkTacticalMap(tacticalMapSize)

function mkTacticalMapForHud(scale) {
  let stateFlags = Watched(0)
  let size = scaleArr(tacticalMapSize, scale)
  const shortcutId = "ID_TACTICAL_MAP"
  let openMapBtn = @() {
    watch = stateFlags
    size = FLEX
    behavior = Behaviors.Button
    cameraControl = true
    sound = { click  = "click" }
    onElemState = @(sf) stateFlags.set(sf)
    onClick = @() isInMpSession.get() && isVoiceMsgEnabled.get()
      ? isVoiceMsgMapSceneOpened.set(true)
      : isTacticalMapSceneOpened.set(true)
    rendObj = ROBJ_SOLID
    color = stateFlags.get() & S_ACTIVE ? 0x28000000 : 0
    hotkeys = mkGamepadHotkey(shortcutId)
  }
  return mkTacticalMap(size, [ openMapBtn, mkGamepadShortcutImage(shortcutId,
    { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = const [0, ph(-52)] },
    scale) ])
}

let tacticalMapEditView = {
  size = tacticalMapSize
  rendObj = ROBJ_BOX
  borderWidth = hdpx(3)
  borderColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("hotkeys/ID_TACTICAL_MAP")
  }.__update(fontSmall)
}

return {
  tacticalMap
  mkTacticalMapForHud

  tacticalMapSize
  tacticalMapEditView
}
