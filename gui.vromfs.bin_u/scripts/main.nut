from "%scripts/dagui_natives.nut" import run_reactive_gui, get_cur_circuit_name
from "%scripts/dagui_library.nut" import *
from "ecs" import clear_vm_entity_systems, start_es_loading, end_es_loading

let { get_time_msec, ref_time_ticks } = require("dagor.time")
let startLoadTime = get_time_msec()
let { g_listener_priority } = require("%scripts/g_listener_priority.nut")
let { loadOnce, isInReloading } = require("%sqStdLibs/scriptReloader/scriptReloader.nut")
let { set_rnd_seed } = require("dagor.random")
let { eventbus_subscribe } = require("eventbus")
let { getSystemConfigOption, setSystemConfigOption } = require("%globalScripts/systemConfig.nut")
clear_vm_entity_systems()
start_es_loading()

require("%globalScripts/ui_globals.nut")
require("%appGlobals/sqevents.nut")
require("%globalScripts/debugTools/matchingErrorDebug.nut")

require("%globalScripts/version.nut")
require("%scripts/clientState/errorHandling.nut")

let { is_pc } = require("%sqstd/platform.nut")

//------- vvv enums vvv ----------

set_rnd_seed(ref_time_ticks())

//------- vvv files before login vvv ----------

let subscriptions = require("%sqStdLibs/helpers/subscriptions.nut")
subscriptions.setDefaultPriority(g_listener_priority.DEFAULT)

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
require("%scripts/matching/onlineInfo.nut")
require("%scripts/matching/rpcCall.nut")


foreach (fn in [
  "%sqstd/math.nut"

  "%scripts/urlType.nut"
  "%scripts/url.nut"

  "%scripts/clientState/localProfile.nut"

  "%scripts/language.nut"
  "%scripts/loadRootScreen.nut"

  "%scripts/clientState/keyboardState.nut"

  //used in loading screen
  "%scripts/loading.nut"

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
require("%sqstd/regScriptProfiler.nut")("dagui", dlog) // warning disable: -forbidden-function
require("bqQueue.nut")
  // end of Independent Modules

let { sendLoadingStageBqEvent } = require("%appGlobals/pServer/bqClient.nut")

end_es_loading()

if (!isInReloading()) {
  sendLoadingStageBqEvent("main_loaded")

  run_reactive_gui()
}

//------- ^^^ files before login ^^^ ----------


//------- vvv files after login vvv ----------

local isFullScriptsLoaded = false

function loadScriptsAfterLoginOnceImpl() {
  if (isFullScriptsLoaded)
    return
  isFullScriptsLoaded = true
  let t = get_time_msec()
  log("LOAD MAIN SCRIPTS AFTER LOGIN")
  require("%scripts/onScriptLoadAfterLogin.nut")
  log($"DaGui scripts load after login {get_time_msec() - t} msec")
}

function loadScriptsAfterLoginOnce() {
  if (isFullScriptsLoaded)
    return
  start_es_loading()
  loadScriptsAfterLoginOnceImpl()
  end_es_loading()
}

//------- ^^^ files after login ^^^ ----------


if (is_pc && get_cur_circuit_name().indexof("production") == null
  && getSystemConfigOption("debug/netLogerr") == null)
    setSystemConfigOption("debug/netLogerr", true)

let { isReadyToFullLoad, isLoginRequired } = require("%appGlobals/loginState.nut")

log($"DaGui scripts load before login {get_time_msec() - startLoadTime} msec")

if (isReadyToFullLoad.value || !isLoginRequired.value)
  loadScriptsAfterLoginOnce()
isReadyToFullLoad.subscribe(@(v) v ? loadScriptsAfterLoginOnce() : null)
isLoginRequired.subscribe(@(v) v ? null : loadScriptsAfterLoginOnce())


let { defer } = require("dagor.workcycle")
let { reloadDargUiScript } = require("reactiveGuiCommand")
eventbus_subscribe("reloadDargVM", @(_) defer(@() reloadDargUiScript(false)))

let { registerMplayerCallbacks } = require("mplayer_callbacks")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { myUserName, myUserRealName } = require("%appGlobals/profileStates.nut")
eventbus_subscribe("register_mplayer_callbacks",
  @(_) registerMplayerCallbacks({
    frameNick = @(nick, frameId) frameNick(getPlayerName(nick, myUserRealName.get(), myUserName.get()), frameId)
  }))

let { squadMembers } = require("%appGlobals/squadState.nut")
let { registerRespondent } = require("scriptRespondent")
registerRespondent("is_in_my_squad", @(userId, _checkAutosquad = true) userId in squadMembers.value)
