from "%scripts/dagui_library.nut" import *
from "ecs" import clear_vm_entity_systems, start_es_loading, end_es_loading
let { get_time_msec, get_local_unixtime } = require("dagor.time")
let startLoadTime = get_time_msec()

let { loadOnce, registerPersistentData, isInReloading } = require("%sqStdLibs/scriptReloader/scriptReloader.nut")
let { set_rnd_seed } = require("dagor.random")
let { subscribe } = require("eventbus")
clear_vm_entity_systems()
start_es_loading()

require("%globalScripts/ui_globals.nut")
require("%appGlobals/sqevents.nut")
require("%globalScripts/debugTools/matchingErrorDebug.nut")

require("%globalScripts/version.nut")
require("%scripts/compatibility.nut")
require("%scripts/clientState/errorHandling.nut")

let { is_pc } = require("%sqstd/platform.nut")

::is_dev_version <- false // WARNING : this is unsecure

::INVALID_USER_ID <- ::make_invalid_user_id()
::RESPAWNS_UNLIMITED <- -1

::is_debug_mode_enabled <- false

::cross_call_api <- {}

registerPersistentData("MainGlobals", getroottable(),
  [ "is_debug_mode_enabled", "is_dev_version" ])

//------- vvv enums vvv ----------

set_rnd_seed(get_local_unixtime())

//------- vvv files before login vvv ----------

let subscriptions = require("%sqStdLibs/helpers/subscriptions.nut")
::g_listener_priority <- {
  DEFAULT = 0
  DEFAULT_HANDLER = 1
  UNIT_CREW_CACHE_UPDATE = 2
  USER_PRESENCE_UPDATE = 2
  CONFIG_VALIDATION = 2
  LOGIN_PROCESS = 3
  MEMOIZE_VALIDATION = 4
}
subscriptions.setDefaultPriority(::g_listener_priority.DEFAULT)

let guiOptions = require("guiOptions")
foreach (name in [
  "get_gui_option", "set_gui_option", "get_unit_option", "set_unit_option",
  "get_cd_preset", "set_cd_preset"
])
  if (name not in getroottable())
    getroottable()[name] <- guiOptions[name]

foreach (fn in [
  "%scripts/debugTools/dbgToString.nut"
  "%scripts/util.nut"
])
  require(fn)

require("%scripts/options/optionsExtNames.nut")
require("login/initLoginWTM.nut")
require("%scripts/pServer/profileServerClient.nut")
require("%scripts/pServer/writeProfileToNdb.nut")
require("%scripts/currencies.nut")
require("%scripts/matching/matchingClient.nut")
require("%scripts/matching/onlineInfo.nut")
require("%scripts/matching/rpcCall.nut")


foreach (fn in [
  "%globalScripts/sharedEnums.nut"

  "%sqstd/math.nut"

  "%scripts/urlType.nut"
  "%scripts/url.nut"

  "%sqStdLibs/helpers/datablockUtils.nut"

  "%scripts/clientState/localProfile.nut"

  "%scripts/language.nut"
  "%scripts/loadRootScreen.nut"

  "%scripts/clientState/keyboardState.nut"

  //used in loading screen
  "%scripts/loading.nut"

  "%scripts/hangarLights.nut"

  "%scripts/webRPC.nut"

  "%scripts/debugTools/dbgUtils.nut"
]) {
  loadOnce(fn)
}

  // Independent Modules (before login)
require("%scripts/login/updateRights.nut")
require("%scripts/debugTools/dbgDedicLogerrs.nut")
require("%scripts/matching/gameModesUpdate.nut")
require("utils/restartGame.nut")
require("%sqstd/regScriptProfiler.nut")("dagui")
require("bqQueue.nut")
  // end of Independent Modules

let { sendLoadingStageBqEvent } = require("%appGlobals/pServer/bqClient.nut")

end_es_loading()

if (!isInReloading()) {
  sendLoadingStageBqEvent("main_loaded")

  ::run_reactive_gui()
}

//------- ^^^ files before login ^^^ ----------


//------- vvv files after login vvv ----------

local isFullScriptsLoaded = false

let function loadScriptsAfterLoginOnceImpl() {
  if (isFullScriptsLoaded)
    return
  isFullScriptsLoaded = true
  let t = get_time_msec()
  log("LOAD MAIN SCRIPTS AFTER LOGIN")
  require("%scripts/onScriptLoadAfterLogin.nut")
  log($"DaGui scripts load after login {get_time_msec() - t} msec")
}

let function loadScriptsAfterLoginOnce() {
  if (isFullScriptsLoaded)
    return
  start_es_loading()
  loadScriptsAfterLoginOnceImpl()
  end_es_loading()
}

//------- ^^^ files after login ^^^ ----------


if (is_pc && !::isProductionCircuit() && ::getSystemConfigOption("debug/netLogerr") == null)
  ::setSystemConfigOption("debug/netLogerr", true)

let { isReadyToFullLoad, isLoginRequired } = require("%appGlobals/loginState.nut")

log($"DaGui scripts load before login {get_time_msec() - startLoadTime} msec")

if (isReadyToFullLoad.value || !isLoginRequired.value)
  loadScriptsAfterLoginOnce()
isReadyToFullLoad.subscribe(@(v) v ? loadScriptsAfterLoginOnce() : null)
isLoginRequired.subscribe(@(v) v ? null : loadScriptsAfterLoginOnce())


let { defer } = require("dagor.workcycle")
let { reloadDargUiScript } = require("reactiveGuiCommand")
subscribe("reloadDargVM", @(_) defer(@() reloadDargUiScript(false)))

let { registerMplayerCallbacks } = require("mplayer_callbacks")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
subscribe("register_mplayer_callbacks",
  @(_) registerMplayerCallbacks({ frameNick = @(nick, frameId) frameNick(getPlayerName(nick), frameId) }))

/*use by client .cpp code*/
let { squadMembers } = require("%appGlobals/squadState.nut")
::is_in_my_squad <- @(userId, _checkAutosquad = true) userId in squadMembers.value
