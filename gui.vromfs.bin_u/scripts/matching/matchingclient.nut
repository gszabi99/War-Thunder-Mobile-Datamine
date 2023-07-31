from "%scripts/dagui_library.nut" import *

let eventbus = require("eventbus")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")

::matching.subscribe("mrpc.generic_notify", @(p) eventbus.send("mrpc.generic_notify", p))

::punish_show_tips <- function punish_show_tips(params) {
  log("punish_show_tips")
  if ("reason" in params)
    openFMsgBox({ text = params.reason })
}

::punish_close_client <- function punish_close_client(params) {
  log("punish_close_client")
  let message = params?.reason ?? loc("matching/hacker_kicked_notice")

  let needFlightMenu = ::is_in_flight() && !::get_is_in_flight_menu() && !::is_flight_menu_disabled()
  if (needFlightMenu)
    eventbus.send("gui_start_flight_menu", null)

  openFMsgBox({
    uid = "info_msg_box"
    text = message
    buttons = [{ id = "exit", eventId = "matchingExitGame", isDefault = true }]
    isPersist = true
  })
}
