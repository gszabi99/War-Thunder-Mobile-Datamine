
let { INVALID_USER_ID } = require("matching.errors")
let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")

let myAvatar = sharedWatched("myAvatar", @() "cardicon_default")
let updateAvatar = @(campaign) myAvatar(campaign == "tanks" ? "cardicon_tanker" : "cardicon_default")
curCampaign.subscribe(updateAvatar)
updateAvatar(curCampaign.value)

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
  myAvatar
}
