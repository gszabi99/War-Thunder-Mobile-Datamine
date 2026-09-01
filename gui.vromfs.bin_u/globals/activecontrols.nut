from "blkGetters" import get_settings_blk
from "frp" import Computed
from "lastInputMonitor" import DEV_MOUSE, DEV_KBD, DEV_GAMEPAD, DEV_TOUCH
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/platform.nut" import is_pc, is_mobile


let isEmuTouch = get_settings_blk()?.debug.emuTouchScreen ?? false
let NEED_CURSOR_MASK =
    DEV_MOUSE
  | (is_mobile ? 0 : DEV_KBD)
  | DEV_GAMEPAD
  | (is_pc && isEmuTouch ? DEV_TOUCH : 0)

let activeControlsType = hardPersistWatched("activeControlsType", 0)

let isGamepad = Computed(@() (activeControlsType.get() & DEV_GAMEPAD) != 0)
let isKeyboard = Computed(@() (activeControlsType.get() & DEV_KBD) != 0)
let needCursorForActiveInputDevice = Computed(@() (activeControlsType.get() & NEED_CURSOR_MASK) != 0)

return {
  activeControlsType
  isGamepad
  isKeyboard
  needCursorForActiveInputDevice
}
