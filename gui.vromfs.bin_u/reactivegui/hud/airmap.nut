from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/clientState/clientState.nut" import isInMpSession
from "%rGui/hud/voiceMsg/voiceMsgState.nut" import isVoiceMsgEnabled
from "%rGui/hud/voiceMsg/hudVoiceMsgMapScene.nut" import isVoiceMsgMapSceneOpened
from "%rGui/hud/tacticalMap/hudTacticalMapScene.nut" import isTacticalMapSceneOpened
from "%rGui/hud/hudTouchButtonStyle.nut" import borderColor
from "%rGui/controls/shortcutSimpleComps.nut" import mkGamepadShortcutImage, mkGamepadHotkey

let mapSize = hdpx(300)
let shortcutId = "ID_TACTICAL_MAP"

let airMap = @(scale) {
  size = array(2, scaleEven(mapSize, scale))
  rendObj = ROBJ_RADAR
  behavior = Behaviors.Button
  onClick = @() isInMpSession.get() && isVoiceMsgEnabled.get()
    ? isVoiceMsgMapSceneOpened.set(true)
    : isTacticalMapSceneOpened.set(true)
  hotkeys = mkGamepadHotkey(shortcutId)
  children = mkGamepadShortcutImage(shortcutId,
    { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [0, ph(-52)] },
    scale)
}

let airMapEditView = {
  size = [mapSize, mapSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#hud_bg_round_border.svg:{mapSize}:{mapSize}:P")
  color = borderColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("hotkeys/ID_TACTICAL_MAP")
  }.__update(fontSmall)
}

return {
  airMapEditView
  airMap
}