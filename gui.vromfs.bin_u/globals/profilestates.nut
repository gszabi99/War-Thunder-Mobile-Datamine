
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
  myUserName = Computed(@() myInfo.get().name)
  myUserRealName = Computed(@() myInfo.get().realName)
  myUserId = Computed(@() myInfo.get().userId)
  myUserIdStr = Computed(@() myInfo.get().userId.tostring())
}
