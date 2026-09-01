from "multiplayer" import is_mplayer_host, is_mplayer_peer, is_local_multiplayer


let is_multiplayer = @() (is_mplayer_host() || is_mplayer_peer()) && !is_local_multiplayer()

return {
  is_multiplayer
}
