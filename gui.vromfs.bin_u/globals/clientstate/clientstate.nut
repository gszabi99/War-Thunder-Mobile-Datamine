
let { Computed, Watched } = require("frp")
let { eventbus_subscribe } = require("eventbus")
let { get_mp_session_id_int, is_local_multiplayer } = require("multiplayer")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isDownloadedFromGooglePlay, getBuildMarket } = require("android.platform")
let { is_android, is_pc } = require("%sqstd/platform.nut")
let isHuaweiBuild = getBuildMarket() == "appgallery"

let isInBattle = sharedWatched("isInBattle", @() false)
let isOnline = sharedWatched("isOnline", @() false)
let isDisconnected = sharedWatched("isDisconnected", @() false)
let battleSessionId = sharedWatched("battleSessionId", @() -1) //resets to -1 only when start new battle. To allow to get sessionId after session destroy.
let battleUnitName = sharedWatched("battleUnitName", @() null) //To allow to get unit for single mission debriefing.
let localMPlayerId = sharedWatched("localMPlayerId", @() 0)
let localMPlayerTeam = sharedWatched("localMPlayerTeam", @() 0)
let isInLoadingScreen = sharedWatched("isInLoadingScreen", @() true)
let isMissionLoading = sharedWatched("isMissionLoading", @() false)
let isInDebriefing = sharedWatched("isInDebriefing", @() false)
let isInFlightMenu = sharedWatched("isInFlightMenu", @() false)
let canBailoutFromFlightMenu = sharedWatched("canBailoutFromFlightMenu", @() false)
let isMpStatisticsActive = sharedWatched("isMpStatisticsActive", @() false)
let isInMenu = Computed(@() isLoggedIn.value && !isInBattle.value && !isInLoadingScreen.value)
let isOutOfBattleAndResults = Computed(@() !isInBattle.value && !isInDebriefing.value && !isInLoadingScreen.value)
let isHudVisible = sharedWatched("isHudVisible", @() false)
let isInMpSession = Watched(get_mp_session_id_int() != -1)
let isLocalMultiplayer = Watched(is_local_multiplayer())
let isInMpBattle = Computed(@() isInBattle.value && isInMpSession.value)
let canBattleWithoutAddons = sharedWatched("canBattleWithoutAddons", @() false)
let isDownloadedFromSite = (is_android || is_pc) && !isDownloadedFromGooglePlay() && !isHuaweiBuild

eventbus_subscribe("onJoinMatch", function(_) {
  let sessionId = get_mp_session_id_int()
  battleSessionId(sessionId)
  isInMpSession(sessionId != -1)
})

isInBattle.subscribe(function(v) {
  if (v)
    isLocalMultiplayer(is_local_multiplayer())
})

eventbus_subscribe("destroyMultiplayer", @(_) isInMpSession(get_mp_session_id_int() != -1))

return {
  isInBattle
  isOnline
  isDisconnected
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
}
