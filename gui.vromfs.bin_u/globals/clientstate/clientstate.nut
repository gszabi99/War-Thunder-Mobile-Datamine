from "android.platform" import isDownloadedFromGooglePlay, getBuildMarket
from "eventbus" import eventbus_subscribe
from "frp" import Computed, Watched
from "multiplayer" import get_mp_session_id_int, is_local_multiplayer
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/platform.nut" import is_android, is_pc
from "%appGlobals/loginState.nut" import isLoggedIn


let isHuaweiBuild = getBuildMarket() == "appgallery"

let isInBattle = hardPersistWatched("isInBattle", false)
let battleSessionId = hardPersistWatched("battleSessionId", -1) 
let battleUnitName = hardPersistWatched("battleUnitName", null) 
let localMPlayerId = hardPersistWatched("localMPlayerId", 0)
let localMPlayerTeam = hardPersistWatched("localMPlayerTeam", 0)
let isInLoadingScreen = hardPersistWatched("isInLoadingScreen", true)
let isMissionLoading = hardPersistWatched("isMissionLoading", false)
let isInDebriefing = hardPersistWatched("isInDebriefing", false)
let isInFlightMenu = hardPersistWatched("isInFlightMenu", false)
let canBailoutFromFlightMenu = hardPersistWatched("canBailoutFromFlightMenu", false)
let isMpStatisticsActive = hardPersistWatched("isMpStatisticsActive", false)
let isInMenu = Computed(@() isLoggedIn.get() && !isInBattle.get() && !isInLoadingScreen.get())
let isOutOfBattleAndResults = Computed(@() !isInBattle.get() && !isInDebriefing.get() && !isInLoadingScreen.get())
let isHudVisible = hardPersistWatched("isHudVisible", false)
let isInMpSession = Watched(get_mp_session_id_int() != -1)
let isLocalMultiplayer = Watched(is_local_multiplayer())
let isInMpBattle = Computed(@() isInBattle.get() && isInMpSession.get())
let canBattleWithoutAddons = hardPersistWatched("canBattleWithoutAddons", false)
let isDownloadedFromSite = (is_android || is_pc) && !isDownloadedFromGooglePlay() && !isHuaweiBuild
let isSingleMissionOverrided = hardPersistWatched("isSingleMissionOverrided", false)

eventbus_subscribe("onJoinMatch", function(_) {
  let sessionId = get_mp_session_id_int()
  battleSessionId.set(sessionId)
  isInMpSession.set(sessionId != -1)
})

isInBattle.subscribe(function(v) {
  if (v)
    isLocalMultiplayer.set(is_local_multiplayer())
})

eventbus_subscribe("destroyMultiplayer", @(_) isInMpSession.set(get_mp_session_id_int() != -1))

return {
  isInBattle
  battleSessionId
  isInMpSession
  isInMpBattle
  isLocalMultiplayer
  battleUnitName
  isInLoadingScreen
  isMissionLoading
  isInMenu
  isInDebriefing
  localMPlayerId
  localMPlayerTeam
  isOutOfBattleAndResults
  isInFlightMenu
  canBailoutFromFlightMenu
  isMpStatisticsActive
  isHudVisible
  canBattleWithoutAddons
  isDownloadedFromSite
  isSingleMissionOverrided
}
