from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
import "%darg/helpers/mkTextRow.nut" as mkTextRow
from "%globalScripts/controls/shortcutActions.nut" import toggleShortcut
from "%appGlobals/activeControls.nut" import isGamepad
from "%rGui/controls/shortcutSimpleComps.nut" import mkGamepadShortcutImage, mkGamepadHotkey
from "%rGui/hud/hudEventManager.nut" import subscribeHudEvent
from "%rGui/hud/menuButton.nut" import mkMenuButton
from "%rGui/hudHints/killerInfo.nut" import killerInfo


let defShortcutOvr = { hplace = ALIGN_CENTER, vplace = ALIGN_CENTER, pos = const [0, ph(-20)] }

let showSkipHint = mkWatched(persist, "showSkipHint", false)
subscribeHudEvent("hint:xrayCamera:showSkipHint", @(_) showSkipHint.set(true))

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontTiny)

let hintForSkip = function() {
  if (!showSkipHint.get())
    return { watch = [showSkipHint, isGamepad] }
  else{
    let hintIcon = mkGamepadShortcutImage("ID_CONTINUE", defShortcutOvr)
    let hintText = isGamepad.get() ? loc("hints/skip") : loc("hints/skip_doubletap")
    return {
      watch = [showSkipHint, isGamepad]
      vplace = ALIGN_BOTTOM
      hplace = ALIGN_CENTER
      pos = const [0, -sh(10)]
      hintIcon
      flow = FLOW_HORIZONTAL
      children =  mkTextRow(hintText, mkText, { ["{shortcut}"] = hintIcon }) 
    }
  }
}

return {
  size = FLEX
  padding = [sh(10), saBordersRv[1]]
  behavior = Behaviors.Button
  function onDoubleClick() {
    toggleShortcut("ID_CONTINUE")
  }
  function onDetach() {
    showSkipHint.set(false)
  }
  hotkeys = mkGamepadHotkey("ID_CONTINUE", @() toggleShortcut("ID_CONTINUE"))
  children = [
    mkMenuButton()
    killerInfo
    hintForSkip
  ]
}
