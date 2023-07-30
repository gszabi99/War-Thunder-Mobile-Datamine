//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let { isAuthorized, isAuthAndUpdated } = require("%appGlobals/loginState.nut")
let { myInfo } = require("%appGlobals/profileStates.nut")
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { shouldDisableMenu } = require("%appGlobals/clientState/initialState.nut")
let { getNickOrig } = require("auth_wt")

isAuthorized.subscribe(@(v) myInfo.mutate(@(p) p.__update({
  userId = v ? ::get_player_user_id() : ::INVALID_USER_ID
})))

isAuthAndUpdated.subscribe(function(v) {
  let info = v ? ::get_cur_rank_info() : null //why so hard way to get userId?
  let realName = info?.name ?? ""
  let nickOrig = getNickOrig()
  myInfo.mutate(@(p) p.__update({
    name = nickOrig != "" ? nickOrig : getPlayerName(realName)
    realName
  }))
})

if (shouldDisableMenu) {
  let { get_arg_value_by_name } = require("dagor.system")
  let userId = get_arg_value_by_name("userId")
  if (userId != null) {
    let realName = get_arg_value_by_name("userName") ?? userId
    myInfo.mutate(@(p) p.__update({
      userId = userId.tointeger()
      name = realName
      realName
    }))
  }
}
