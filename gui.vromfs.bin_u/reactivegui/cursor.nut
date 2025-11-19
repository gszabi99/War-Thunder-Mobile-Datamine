from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "%appGlobals/activeControls.nut" import needCursorForActiveInputDevice, isGamepad
from "%appGlobals/clientState/clientState.nut" import isInBattle, isHudVisible
from "%appGlobals/clientState/hudState.nut" import isHudAttached
from "%rGui/components/modalWindows.nut" import hasModalWindows

let forceHideCursor = Watched(false)
let needCursorInHud = Computed(@() !isGamepad.get() || !isHudAttached.get() || hasModalWindows.get())
let needShowCursor  = Computed(@() !forceHideCursor.get()
  && needCursorForActiveInputDevice.get()
  && (!isInBattle.get() || (isHudVisible.get() && needCursorInHud.get())))

register_command(@() forceHideCursor.set(!forceHideCursor.get()), "ui.force_hide_mouse_pointer")

let cursorSize = hdpxi(32)

let cursor = Cursor({
  size = [cursorSize, cursorSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#cursor.svg:{cursorSize}:{cursorSize}")
})

return {
  needShowCursor
  cursor
}
