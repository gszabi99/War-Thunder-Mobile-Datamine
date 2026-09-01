from "frp" import Computed
from "matching.errors" import INVALID_USER_ID
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/clientState/initialState.nut" import isOfflineMenu


let myInfo = hardPersistWatched("myInfo", {
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
