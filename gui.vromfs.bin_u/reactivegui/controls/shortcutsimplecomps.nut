from "%globalsDarg/darg_library.nut" import *
let { mkBtnImageComp } = require("%rGui/controlsMenu/gamepadImgByKey.nut")
let { gamepadShortcuts, allShortcutsUp } = require("shortcutsMap.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")

let defBtnHeight = hdpxi(50)

let mkGamepadShortcutImage = @(shortcutId, ovr = {}) @() {
  watch = isGamepad
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = !isGamepad.value || shortcutId not in gamepadShortcuts ? null
    : mkBtnImageComp(gamepadShortcuts?[shortcutId], ovr?.size[1] ?? defBtnHeight)
}.__update(ovr)

let mkGamepadHotkey = @(shortcutId, action = null) shortcutId not in allShortcutsUp ? null
  : action == null ? [allShortcutsUp[shortcutId]]
  : [[allShortcutsUp[shortcutId], action]]

let isActive = @(sf) (sf & S_ACTIVE) != 0

function mkContinuousButtonParams(onTouchBegin, onTouchEnd, shortcutId, stateFlags = null) {
  stateFlags = stateFlags ?? Watched(0)

  return {
    key = shortcutId
    behavior = Behaviors.Button
    function onElemState(sf) {
      let prevSf = stateFlags.value
      stateFlags(sf)
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