from "%globalsDarg/darg_library.nut" import *
from "auth_wt" import getNickOrig
from "dagor.system" import get_arg_value_by_name
from "matching.errors" import INVALID_USER_ID
from "%appGlobals/clientState/initialState.nut" import shouldDisableMenu
from "%appGlobals/loginState.nut" import isAuthorized, isAuthAndUpdated
from "%appGlobals/profileStates.nut" import myInfo
from "%appGlobals/user/nickTools.nut" import removePlatformPostfix
from "guiScriptUtils" import get_cur_rank_info, get_player_user_id


isAuthorized.subscribe(@(v) myInfo.mutate(@(p) p.__update({
  userId = v ? get_player_user_id() : INVALID_USER_ID
})))

isAuthAndUpdated.subscribe(function(v) {
  let info = v ? get_cur_rank_info() : null 
  let realName = info?.name ?? ""
  let nickOrig = getNickOrig() 
  let name = removePlatformPostfix(nickOrig != "" ? nickOrig : realName)
  myInfo.mutate(@(p) p.__update({
    name 
    realName 
  }))
})

if (shouldDisableMenu) {
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
