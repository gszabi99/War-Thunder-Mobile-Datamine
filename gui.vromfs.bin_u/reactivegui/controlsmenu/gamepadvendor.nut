from "%globalsDarg/darg_library.nut" import *
let { send, subscribe } = require("eventbus")
let { VendorId, getJoystickVendor } = require("controls")
let { UNKNOWN, MICROSOFT, SONY, NINTENDO } = VendorId
let { register_command } = require("console")
let { resetTimeout } = require("dagor.workcycle")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")

let defGamepadPresetId = "xone"
let vendorIdToGamepadPresetId = {
  [MICROSOFT] = "xone",
  [SONY] = "sony",
  [NINTENDO] = "nintendo",
}

let lastVendorId = mkHardWatched("lastGamepadVendorId", null)
let debugVendorId = mkHardWatched("debugGamepadVendorId", null)
let curVendorId = Computed(@() debugVendorId.value ?? lastVendorId.value)
let presetId = Computed(@() vendorIdToGamepadPresetId?[curVendorId.value] ?? defGamepadPresetId)

if (lastVendorId.value == null) {
  lastVendorId(getJoystickVendor())
  log("[GAMEPAD] presetId = ", presetId.value) //to not spam this log on each script reload
}
presetId.subscribe(@(v) log("[GAMEPAD] presetId = ", v))

let vendorIdToShow = lastVendorId.value //we will hot reload darg scripts on change gamepad vendor
let presetIdToShow = presetId.value //we will hot reload darg scripts on change gamepad vendor

let function updateVendor(_) {
  let id = getJoystickVendor()
  if (id != UNKNOWN)
    lastVendorId(id)
}
subscribe("controls.joystickConnected", updateVendor)
subscribe("controls.joystickDisconnected", updateVendor)

let function reloadVmIfNeed() {
  if (presetId.value != presetIdToShow)
    send("reloadDargVM", null)
}
presetId.subscribe(@(_) resetTimeout(0.1, reloadVmIfNeed))

let function setDbgVendor(id) {
  debugVendorId(id == UNKNOWN ? null : id)
  console_print("gamepad preset id = ", presetId.value) //warning disable: -forbidden-function
}

VendorId.each(@(id, name) register_command(
  @() setDbgVendor(id)
  $"ui.setGamepadVedor.{id == UNKNOWN ? "DEFAULT" : name}"
))

return {
  gamepadVendor = vendorIdToShow
  gamepadPreset = presetIdToShow
}