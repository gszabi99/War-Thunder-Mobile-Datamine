from "%scripts/dagui_library.nut" import *


let { eventbus_subscribe } = require("eventbus")
let { is_mplayer_host, is_mplayer_peer, is_local_multiplayer } = require("multiplayer")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")

eventbus_subscribe("on_cannot_create_session", @(...) openFMsgBox({ text = loc("NET_CANNOT_CREATE_SESSION") }))

let is_multiplayer = @() (is_mplayer_host() || is_mplayer_peer()) && !is_local_multiplayer()

function is_user_mission(missionBlk) {
  return missionBlk?.userMission == true 
}


return {
  is_multiplayer
  is_user_mission
}