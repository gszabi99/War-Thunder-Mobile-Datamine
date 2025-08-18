from "%globalsDarg/darg_library.nut" import *
let { activeControlsType } = require("%appGlobals/activeControls.nut")
let { register_command } = require("console")
let { eventbus_subscribe } = require("eventbus")
let { DEV_MOUSE, DEV_KBD, DEV_GAMEPAD, DEV_TOUCH, get_last_used_device_mask
} = require("lastInputMonitor")
let { is_pc, is_nswitch } = require("%sqstd/platform.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let defControlsType = is_nswitch ? DEV_GAMEPAD
  : is_pc ? DEV_MOUSE
  : DEV_TOUCH

let ALLOWED_MASK = is_nswitch ? DEV_GAMEPAD
  : is_pc ? DEV_GAMEPAD | DEV_TOUCH | DEV_MOUSE | DEV_KBD
  : DEV_GAMEPAD | DEV_TOUCH

let forcedControlsType = hardPersistWatched("forcedControlsType")
let lastActiveControlsTypeRaw = Watched(get_last_used_device_mask())
let lastActiveControlsType = Computed(@(prev) (lastActiveControlsTypeRaw.get() & ALLOWED_MASK)
  || (prev == FRP_INITIAL ? 0 : prev))

let activeControlsTypeComputed = keepref(Computed(@() forcedControlsType.get() || lastActiveControlsType.get() || defControlsType))

eventbus_subscribe("input_dev_used", @(ev) lastActiveControlsTypeRaw.set(ev.mask))

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

activeControlsType.set(activeControlsTypeComputed.get())
activeControlsTypeComputed.subscribe(function(v) {
  log($"[CTRL_MASK] active changed to {maskToText(v)}")
  activeControlsType.set(v)
})

let toggleForce = @(mask) forcedControlsType.modify(@(v) v == mask ? 0 : mask)
register_command(@() toggleForce(DEV_TOUCH), "ui.forceControlTypeTouch")
register_command(@() toggleForce(DEV_GAMEPAD), "ui.forceControlTypeGamepad")
register_command(@() forcedControlsType(0), "ui.forceControlTypeAuto")
