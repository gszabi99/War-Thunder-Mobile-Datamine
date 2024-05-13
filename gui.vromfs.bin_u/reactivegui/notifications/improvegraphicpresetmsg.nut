from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { eventbus_send } = require("eventbus")
let { get_platform_window_resolution, get_default_graphics_preset } = require("graphicsOptions")
let { get_common_local_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { graphicsQuality, setGraphicsQuality } = require("%rGui/options/options/graphicOptions.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let optionsScene = require("%rGui/options/optionsScene.nut")


let MSG_UID = "improveGraphicPresetMsg"
let CUR_VERSION = 1
let improvedVersion = Watched(get_common_local_settings_blk()?.graphicImproveVersion ?? 0)
let needUpdateGraphics = keepref(Computed(@() isLoggedIn.get() && improvedVersion.get() < CUR_VERSION))

function saveVersion(version = CUR_VERSION) {
  improvedVersion(version)
  get_common_local_settings_blk().graphicImproveVersion = version
  eventbus_send("saveProfile", {})
}

let openMsg = @() openMsgBox({
  uid = MSG_UID
  text = loc("msg/graphicPresetChangeByResolution")
  buttons = [
    { id = "ok", isCancel = true, cb = @() saveVersion() }
    { id = "goToSettings", isDefault = true,
      function cb() {
        saveVersion()
        optionsScene("graphic")
      }
    }
  ]
})

function updateGraphics() {
  if (!needUpdateGraphics.get())
    return
  if (get_platform_window_resolution().height > 720
      || get_default_graphics_preset() != "low"
      || graphicsQuality.get() == "low") {
    log("[GRAPHICS_PRESET] No need changes to improve graphics settings")
    saveVersion()
    return
  }
  log("[GRAPHICS_PRESET] Set graphics quality to low")
  setGraphicsQuality("low")
  openMsg()
}

if (needUpdateGraphics.get())
  deferOnce(updateGraphics)
needUpdateGraphics.subscribe(@(_) deferOnce(updateGraphics))

register_command(@() saveVersion(0), "debug.reset_update_graphics_message")
register_command(openMsg, "debug.show_update_graphics_message")
