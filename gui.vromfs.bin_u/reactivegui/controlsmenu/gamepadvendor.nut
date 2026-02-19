from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { VendorId, getJoystickVendor, hasXInputDevice } = require("controls")
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
let hasGamepadConnected = hardPersistWatched("hasGamepadConnected", hasXInputDevice())
let curVendorId = Computed(@() debugVendorId.get() ?? lastVendorId.get())
let presetId = Computed(@() vendorIdToGamepadPresetId?[curVendorId.get()] ?? defGamepadPresetId)

if (lastVendorId.get() == null) {
  lastVendorId.set(getJoystickVendor())
  log("[GAMEPAD] presetId = ", presetId.get()) 
}
presetId.subscribe(@(v) log("[GAMEPAD] presetId = ", v))

let vendorIdToShow = lastVendorId.get() 
let presetIdToShow = presetId.get() 

function updateVendor(isConnected) {
  let id = getJoystickVendor()
  let hasInputDevice = hasXInputDevice()
  hasGamepadConnected.set(hasInputDevice)
  log($"[GAMEPAD] joystickConnected = {isConnected}; hasXInputDevice() = {hasInputDevice}")
  if (id != UNKNOWN)
    lastVendorId.set(id)
}
eventbus_subscribe("controls.joystickConnected", @(_) updateVendor(true))
eventbus_subscribe("controls.joystickDisconnected", @(_) updateVendor(false))

function reloadVmIfNeed() {
  if (presetId.get() != presetIdToShow)
    eventbus_send("reloadDargVM", { msg = "gamepad vendor changed" })
}
presetId.subscribe(@(_) resetTimeout(0.1, reloadVmIfNeed))

function setDbgVendor(id) {
  debugVendorId.set(id == UNKNOWN ? null : id)
  console_print("gamepad preset id = ", presetId.get()) 
}

VendorId.each(@(id, name) register_command(
  @() setDbgVendor(id)
  $"ui.setGamepadVendor.{id == UNKNOWN ? "DEFAULT" : name}"
))

return {
  gamepadVendor = vendorIdToShow
  gamepadPreset = presetIdToShow
  hasGamepadConnected
}