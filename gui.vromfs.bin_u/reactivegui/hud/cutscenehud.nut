from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *

let menuButton = require("%rGui/hud/mkMenuButton.nut")()
let killerInfo = require("%rGui/hudHints/killerInfo.nut")
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { eventbus_subscribe } = require("eventbus")
let { isGamepad } = require("%rGui/activeControls.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")

let defShortcutOvr = { hplace = ALIGN_CENTER, vplace = ALIGN_CENTER, pos = [0, ph(-20)] }

let showSkipHint = mkWatched(persist, "showSkipHint", false)
eventbus_subscribe("hint:xrayCamera:showSkipHint", @(_) showSkipHint(true))

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontTiny)

let hintForSkip = function() {
  if (!showSkipHint.value)
    return { watch = [showSkipHint, isGamepad] }
  else{
    let hintIcon = mkGamepadShortcutImage("ID_CONTINUE", defShortcutOvr)
    let hintText = isGamepad.value ? loc("hints/skip") : loc("hints/skip_doubletap")
    return {
      watch = [showSkipHint, isGamepad]
      vplace = ALIGN_BOTTOM
      hplace = ALIGN_CENTER
      pos = [0, -sh(10)]
      hintIcon
      flow = FLOW_HORIZONTAL
      children =  mkTextRow(hintText, mkText, { ["{shortcut}"] = hintIcon }) //warning disable: -forgot-subst
    }
  }
}

return {
  size = flex()
  padding = [sh(10), saBordersRv[1]]
  behavior = Behaviors.Button
  function onDoubleClick() {
    toggleShortcut("ID_CONTINUE")
  }
  function onDetach() {
    showSkipHint(false)
  }
  hotkeys = mkGamepadHotkey("ID_CONTINUE", @() toggleShortcut("ID_CONTINUE"))
  children = [
    menuButton
    killerInfo
    hintForSkip
  ]
}

