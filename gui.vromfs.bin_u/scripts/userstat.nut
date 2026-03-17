from "%scripts/dagui_library.nut" import *
import "userstat" as userstat
import "%scripts/charClientEvent.nut" as charClientEvent

let { request, registerHandler } = charClientEvent("userStats", userstat)


return {
  userstatRequest = request
  userstatRegisterHandler = registerHandler
}
