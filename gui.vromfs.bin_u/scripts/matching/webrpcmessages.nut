from "%scripts/dagui_library.nut" import *
from "app" import exitGame
let callbackWhenAppWillActive = require("%scripts/clientState/callbackWhenAppWillActive.nut")
let { openUrl } = require("%scripts/url.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { web_rpc } = require("%scripts/webRPC.nut")
let { isInFlight } = require("gameplayBinding")

function showMessageBox(params) {
  if (isInFlight())
    return { error = { message = "Can not be shown in battle" } }

  let title = params?.title ?? ""
  let message = params?.message ?? ""
  if (title == "" && message == "")
    return { error = { message = "Title and message is empty" } }

  openFMsgBox({
    uid = "show_message_from_matching"
    text = "\n".concat(colorize("@activeTextColor", title), message)
    buttons = [{ id = "ok", eventId = (params?.logout_on_close ?? false) ? "matchingExitGame" : null, isDefault = true }]
    isPersist = true
  })

  return { result = "ok" }
}

function showUrl(params) {
  if (isInFlight())
    return { error = { message = "Can not be shown in battle" } }

  let url = params?.url ?? ""
  if (url == "")
    return { error = { message = "url is empty" } }

  if (params?.logout_on_close ?? false)
    callbackWhenAppWillActive(exitGame)

  openUrl(url)

  return { result = "ok" }
}


web_rpc.register_handler("show_message_box", showMessageBox)
web_rpc.register_handler("open_url", showUrl)
