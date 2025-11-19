from "%globalsDarg/darg_library.nut" import *
let { getScaledFont } = require("%globalsDarg/fontScale.nut")
let { mkBtnImageComp } = require("%rGui/controlsMenu/gamepadImgByKey.nut")
let { gamepadShortcuts, allShortcutsUp, getGamepadKeys } = require("%rGui/controls/shortcutsMap.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")

let defBtnHeight = hdpxi(50)

let combinationButton = "J:LB"
let combinationButtonState = Watched(0)
let isCombinationModActive = Computed(@() (combinationButtonState.get() & S_ACTIVE) != 0)

let mkGamepadShortcutImage = @(shortcutId, ovr = {}, scale = 1.0) function() {
  let gKeys = getGamepadKeys(shortcutId)
  let children = !isGamepad.get() || shortcutId not in gamepadShortcuts ? null
    : gKeys.map(@(k) mkBtnImageComp(
        k,
        min(1.0, scale) * (ovr?.size[1] ?? defBtnHeight)
        k == combinationButton && isCombinationModActive.get()
      ))
  return {
    watch = [isGamepad, isCombinationModActive]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = (children?.len() ?? 0) < 2 ? children : children?.insert(1,
      {
        rendObj = ROBJ_TEXT
        text = "+"
      }.__update(getScaledFont(fontTinyShaded, scale)))
  }.__update(ovr)
}
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
      let prevSf = stateFlags.get()
      stateFlags.set(sf)
      if(needToStop) {
        stateFlags.set(0)
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
      if (!isActive(stateFlags.get()))
        return
      stateFlags.set(0)
      onTouchEnd()
    }
    hotkeys = mkGamepadHotkey(shortcutId)
  }
}

let mkLtButtonListener = @() {
  watch = combinationButtonState
  size = 0
  behavior = Behaviors.Button
  onElemState = @(v) combinationButtonState.set(v)
  hotkeys = static [$"^{combinationButton}"]
}

return {
  mkGamepadShortcutImage
  mkGamepadHotkey
  mkContinuousButtonParams

  mkLtButtonListener
  isCombinationModActive
}