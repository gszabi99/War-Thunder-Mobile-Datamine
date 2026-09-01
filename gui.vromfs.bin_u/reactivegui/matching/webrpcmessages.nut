from "%globalsDarg/darg_library.nut" import *
from "app" import exitGame
from "gameplayBinding" import isInFlight
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
import "%appGlobals/clientState/callbackWhenAppWillActive.nut" as callbackWhenAppWillActive
from "eventbus" import eventbus_send

from "%rGui/webRPC.nut" import webRpcRegister

let openUrl = @(baseUrl) eventbus_send("openUrl", { baseUrl })


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


webRpcRegister("show_message_box", showMessageBox)
webRpcRegister("open_url", showUrl)
