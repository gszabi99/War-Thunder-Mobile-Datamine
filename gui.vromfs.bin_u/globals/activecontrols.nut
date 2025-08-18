let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let { DEV_MOUSE, DEV_KBD, DEV_GAMEPAD, DEV_TOUCH
} = require("lastInputMonitor")
let { is_pc, is_mobile } = require("%sqstd/platform.nut")
let { get_settings_blk } = require("blkGetters")

let isEmuTouch = get_settings_blk()?.debug.emuTouchScreen ?? false
let NEED_CURSOR_MASK =
    DEV_MOUSE
  | (is_mobile ? 0 : DEV_KBD)
  | DEV_GAMEPAD
  | (is_pc && isEmuTouch ? DEV_TOUCH : 0)

let activeControlsType = sharedWatched("activeControlsType", @() 0)

let isGamepad = Computed(@() (activeControlsType.get() & DEV_GAMEPAD) != 0)
let isKeyboard = Computed(@() (activeControlsType.get() & DEV_KBD) != 0)
let needCursorForActiveInputDevice = Computed(@() (activeControlsType.get() & NEED_CURSOR_MASK) != 0)

return {
  activeControlsType
  isGamepad
  isKeyboard
  needCursorForActiveInputDevice
}
