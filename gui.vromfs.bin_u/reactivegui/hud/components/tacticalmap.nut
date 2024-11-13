from "%globalsDarg/darg_library.nut" import *
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { allow_voice_messages } = require("%appGlobals/permissions.nut")
let { isInMpSession } = require("%appGlobals/clientState/clientState.nut")
let { isVoiceMsgEnabled } = require("%rGui/hud/voiceMsg/voiceMsgState.nut")
let { isVoiceMsgMapSceneOpened } = require("%rGui/hud/voiceMsg/hudVoiceMsgMapScene.nut")
let { tacticalMapMarkersLayer } = require("%rGui/hud/tacticalMap/tacticalMapMarkersLayer.nut")

let tacticalMapSize = [hdpx(325), hdpx(325)]

let commonMinimapLayers = [
  {
    size = flex()
    rendObj = ROBJ_SOLID
    color = 0x28000000
  }
  {
    key = "tactical_map"
    size = flex()
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
  let voiceMsgBtn = @() {
    watch = stateFlags
    size = flex()
    behavior = Behaviors.Button
    sound = { click  = "click" }
    onElemState = @(sf) stateFlags.set(sf)
    onClick = @() isVoiceMsgMapSceneOpened.set(true)

    rendObj = ROBJ_SOLID
    color = stateFlags.get() & S_ACTIVE ? 0x28000000 : 0
  }
  return mkTacticalMap(size,
    [
      @() {
        watch = [allow_voice_messages, isInMpSession, isVoiceMsgEnabled]
        size = flex()
        children = allow_voice_messages.get() && isInMpSession.get() && isVoiceMsgEnabled.get() ? voiceMsgBtn : null
      }
    ])
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
