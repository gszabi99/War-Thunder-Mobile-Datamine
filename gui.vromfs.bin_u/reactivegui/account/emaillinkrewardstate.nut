from "%globalsDarg/darg_library.nut" import *
let { userstatRequest, userstatRegisterHandler, isStatsActual } = require("%rGui/unlocks/userstat.nut")
let { authTags, isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { eventbus_send } = require("eventbus")

let storeId = "UpdateAuthStatsCalled"
let needCall = Watched(false)
let needCheck = Computed(@() needCall.get()
  && isStatsActual.get()
  && authTags.value.contains("email_verified")
  && authTags.value.contains("fblogin"))

let updateNeedCall = @() needCall(!get_local_custom_settings_blk()?[storeId])
updateNeedCall()
isOnlineSettingsAvailable.subscribe(@(_) updateNeedCall())

function updateAuthStats() {
  userstatRequest("UpdateAuthStats")
  needCall.set(false)
}

userstatRegisterHandler("UpdateAuthStats", function(result) {
  if ("error" in result)
    log("UpdateAuthStats result: ", result)
  else {
    log("UpdateAuthStats result success")
    get_local_custom_settings_blk()[storeId] = true
    eventbus_send("saveProfile", {})
  }
})

if (needCheck.value)
  updateAuthStats()
needCheck.subscribe(@(v) v ? updateAuthStats() : null)



