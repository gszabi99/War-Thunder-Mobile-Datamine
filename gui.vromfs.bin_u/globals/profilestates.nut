
let { INVALID_USER_ID } = require("matching.errors")
let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")

let myInfo = sharedWatched("myInfo", @() {
  name = isOfflineMenu ? "Offline mode" : ""
  realName = isOfflineMenu ? "Offline mode" : ""
  userId = INVALID_USER_ID
})

return {
  INVALID_USER_ID
  myInfo
  myUserName = Computed(@() myInfo.value.name)
  myUserRealName = Computed(@() myInfo.value.realName)
  myUserId = Computed(@() myInfo.value.userId)
  myUserIdStr = Computed(@() myInfo.value.userId.tostring())
}
