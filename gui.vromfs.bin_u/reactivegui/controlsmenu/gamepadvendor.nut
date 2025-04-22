from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { VendorId, getJoystickVendor } = require("controls")
let { UNKNOWN, MICROSOFT, SONY, NINTENDO } = VendorId
let { register_command } = require("console")
let { resetTimeout } = require("dagor.workcycle")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let defGamepadPresetId = "xone"
let vendorIdToGamepadPresetId = {
  [MICROSOFT] = "xone",
  [SONY] = "sony",
  [NINTENDO] = "nintendo",
}

let lastVendorId = hardPersistWatched("lastGamepadVendorId", null)
let debugVendorId = hardPersistWatched("debugGamepadVendorId", null)
let curVendorId = Computed(@() debugVendorId.value ?? lastVendorId.value)
let presetId = Computed(@() vendorIdToGamepadPresetId?[curVendorId.value] ?? defGamepadPresetId)

if (lastVendorId.value == null) {
  lastVendorId(getJoystickVendor())
  log("[GAMEPAD] presetId = ", presetId.value) 
}
presetId.subscribe(@(v) log("[GAMEPAD] presetId = ", v))

let vendorIdToShow = lastVendorId.value 
let presetIdToShow = presetId.value 

function updateVendor(_) {
  let id = getJoystickVendor()
  if (id != UNKNOWN)
    lastVendorId(id)
}
eventbus_subscribe("controls.joystickConnected", updateVendor)
eventbus_subscribe("controls.joystickDisconnected", updateVendor)

function reloadVmIfNeed() {
  if (presetId.value != presetIdToShow)
    eventbus_send("reloadDargVM", { msg = "gamepad vendor changed" })
}
presetId.subscribe(@(_) resetTimeout(0.1, reloadVmIfNeed))

function setDbgVendor(id) {
  debugVendorId(id == UNKNOWN ? null : id)
  console_print("gamepad preset id = ", presetId.value) 
}

VendorId.each(@(id, name) register_command(
  @() setDbgVendor(id)
  $"ui.setGamepadVendor.{id == UNKNOWN ? "DEFAULT" : name}"
))

return {
  gamepadVendor = vendorIdToShow
  gamepadPreset = presetIdToShow
}