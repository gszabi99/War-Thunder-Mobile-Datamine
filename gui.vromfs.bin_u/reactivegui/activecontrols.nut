from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { eventbus_subscribe } = require("eventbus")
let { DEV_MOUSE, DEV_KBD, DEV_GAMEPAD, DEV_TOUCH, get_last_used_device_mask
} = require("lastInputMonitor")
let { get_settings_blk } = require("blkGetters")
let { is_pc, is_mobile, is_nswitch } = require("%sqstd/platform.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let defControlsType = is_nswitch ? DEV_GAMEPAD
  : is_pc ? DEV_MOUSE
  : DEV_TOUCH
let isEmuTouch = get_settings_blk()?.debug.emuTouchScreen ?? false
let NEED_CURSOR_MASK =
    DEV_MOUSE
  | (is_mobile ? 0 : DEV_KBD)
  | DEV_GAMEPAD
  | (is_pc && isEmuTouch ? DEV_TOUCH : 0)
let ALLOWED_MASK = is_nswitch ? DEV_GAMEPAD
  : is_pc ? DEV_GAMEPAD | DEV_TOUCH | DEV_MOUSE | DEV_KBD
  : DEV_GAMEPAD | DEV_TOUCH

let forcedControlsType = hardPersistWatched("forcedControlsType")
let lastActiveControlsTypeRaw = Watched(get_last_used_device_mask())
let lastActiveControlsType = Computed(@(prev) (lastActiveControlsTypeRaw.value & ALLOWED_MASK)
  || (prev == FRP_INITIAL ? 0 : prev))

let activeControlsType = Computed(@() forcedControlsType.value || lastActiveControlsType.value || defControlsType)

eventbus_subscribe("input_dev_used", @(ev) lastActiveControlsTypeRaw(ev.mask))

let dbgNames = {
  DEV_MOUSE = DEV_MOUSE
  DEV_KBD = DEV_KBD
  DEV_GAMEPAD = DEV_GAMEPAD
  DEV_TOUCH = DEV_TOUCH
}
function maskToText(mask) {
  let list = []
  foreach (name, bit in dbgNames)
    if (bit & mask)
      list.append(name)
  return " | ".join(list)
}
activeControlsType.subscribe(@(v) log($"[CTRL_MASK] active changed to {maskToText(v)}"))

let toggleForce = @(mask) forcedControlsType(forcedControlsType.value == mask ? 0 : mask)
register_command(@() toggleForce(DEV_TOUCH), "ui.forceControlTypeTouch")
register_command(@() toggleForce(DEV_GAMEPAD), "ui.forceControlTypeGamepad")
register_command(@() forcedControlsType(0), "ui.forceControlTypeAuto")

let isGamepad = Computed(@() (activeControlsType.value & DEV_GAMEPAD) != 0)
let isKeyboard = Computed(@() (activeControlsType.value & DEV_KBD) != 0)
let needCursorForActiveInputDevice = Computed(@() (activeControlsType.value & NEED_CURSOR_MASK) != 0)

return {
  isGamepad
  isKeyboard
  needCursorForActiveInputDevice
}
