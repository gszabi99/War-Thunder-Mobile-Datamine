from "%scripts/dagui_natives.nut" import get_cur_rank_info, get_player_user_id
from "%scripts/dagui_library.nut" import *

let { isAuthorized, isAuthAndUpdated } = require("%appGlobals/loginState.nut")
let { myInfo } = require("%appGlobals/profileStates.nut")
let { removePlatformPostfix } = require("%appGlobals/user/nickTools.nut")
let { shouldDisableMenu } = require("%appGlobals/clientState/initialState.nut")
let { getNickOrig, getNickSfx } = require("auth_wt")
let { INVALID_USER_ID } = require("matching.errors")

isAuthorized.subscribe(@(v) myInfo.mutate(@(p) p.__update({
  userId = v ? get_player_user_id() : INVALID_USER_ID
})))

isAuthAndUpdated.subscribe(function(v) {
  let info = v ? get_cur_rank_info() : null //why so hard way to get userId?
  let realName = info?.name ?? ""
  let nickOrig = getNickOrig() // User's custom nickname (currently only Gaijin accounts have it)
  let nickSfx = getNickSfx() // Suffix like "#123" which makes the custom nickname unique
  myInfo.mutate(@(p) p.__update({
    name = nickOrig != "" ? "".concat(nickOrig, nickSfx) : removePlatformPostfix(realName) // Name for displaying in UI
    realName // Unique name as ID. For non-Gaijin accounts it contains a platform suffix like "name@googleplay"
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
