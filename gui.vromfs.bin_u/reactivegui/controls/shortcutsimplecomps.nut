from "%globalsDarg/darg_library.nut" import *
let { mkBtnImageComp } = require("%rGui/controlsMenu/gamepadImgByKey.nut")
let { gamepadShortcuts, allShortcutsUp } = require("%rGui/controls/shortcutsMap.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")

let defBtnHeight = hdpxi(50)

let mkGamepadShortcutImage = @(shortcutId, ovr = {}, scale = 1.0) @() {
  watch = isGamepad
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = !isGamepad.get() || shortcutId not in gamepadShortcuts ? null
    : mkBtnImageComp(gamepadShortcuts?[shortcutId], min(1.0, scale) * (ovr?.size[1] ?? defBtnHeight))
}.__update(ovr)

let mkGamepadHotkey = @(shortcutId, action = null) shortcutId not in allShortcutsUp ? null
  : action == null ? [allShortcutsUp[shortcutId]]
  : [[allShortcutsUp[shortcutId], action]]

let isActive = @(sf) (sf & S_ACTIVE) != 0

function mkContinuousButtonParams(onTouchBegin, onTouchEnd, shortcutId, stateFlags = null, needToStop = false, onStop = null) {
  stateFlags = stateFlags ?? Watched(0)

  return {
    key = shortcutId
    behavior = Behaviors.Button
    cameraControl = true
    function onElemState(sf) {
      let prevSf = stateFlags.value
      stateFlags(sf)
      if(needToStop) {
        stateFlags(0)
        if(onStop) onStop()
        return
      }
      let active = isActive(sf)
      if (active != isActive(prevSf))
        if (active)
          onTouchBegin()
        else
          onTouchEnd()
    }
    function onDetach() {
      if (!isActive(stateFlags.value))
        return
      stateFlags(0)
      onTouchEnd()
    }
    hotkeys = shortcutId not in allShortcutsUp ? null : [allShortcutsUp[shortcutId]]
  }
}

return {
  mkGamepadShortcutImage
  mkGamepadHotkey
  mkContinuousButtonParams
}