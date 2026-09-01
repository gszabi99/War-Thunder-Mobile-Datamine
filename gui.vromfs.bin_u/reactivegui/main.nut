#default:forbid-root-table

from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.time" import get_time_msec
from "ecs" import clear_vm_entity_systems, start_es_loading, end_es_loading
from "platform" import get_platform_string_id
from "%darg/helpers/bitmap.nut" import markScriptsLoading
from "%darg/helpers/inspector.nut" import inspectorRoot
from "%appGlobals/clientState/clientState.nut" import isInLoadingScreen, isInBattle, isHudVisible
from "%appGlobals/clientState/hudState.nut" import isHudAttached
from "%appGlobals/loginState.nut" import isLoggedIn, isLoginRequired, isReadyToFullLoad, isLoginStarted
from "%appGlobals/openForeignMsgBox.nut" import closeFMsgBox
from "%appGlobals/pServer/bqClient.nut" import sendUiBqEvent
from "%rGui/components/debugOverlay.nut" import dbgOverlayComponent
from "%rGui/components/modalWindows.nut" import modalWindowsComponent, closeAllModalWindows
from "%rGui/components/spinner.nut" import spinnerOpacityAnim, spinner
from "%rGui/controlsMenu/gpActBtn.nut" import enableClickButtons
import "%rGui/controlsMenu/hotkeysPanel.nut" as hotkeysPanel
from "%rGui/cursor.nut" import needShowCursor, cursor
from "%rGui/debugTools/debugTouches.nut" import debugTouchesUi, debugTouchesHandlerComp, isDebugTouchesActive
import "%rGui/hud/deviceState.nut" as deviceStateArea
from "%rGui/hudState.nut" import isPlayingReplay
import "%rGui/isScriptsLoading.nut" as isScriptsLoading
from "%rGui/loading/loadingScreen.nut" import loadingScreen
import "%rGui/login/sceneBeforeLogin.nut" as sceneBeforeLogin
import "%rGui/mainMenu/fpsLineComp.nut" as fpsLineComp
from "%rGui/notifications/waitBox.nut" import waitboxes
from "%rGui/style/backgrounds.nut" import bgShadedDark
from "%rGui/tooltip.nut" import tooltipComp


function setIsScriptsLoading(v) {
  markScriptsLoading(v)
  isScriptsLoading.set(v)
}
isScriptsLoading.whiteListMutatorClosure(setIsScriptsLoading)

log("LOAD RGUI SCRIPTS CORE")
setIsScriptsLoading(true)
let startLoadTime = get_time_msec()
clear_vm_entity_systems()

require("%appGlobals/frpDebug.nut")
require("%appGlobals/sqevents.nut")
require("%rGui/initVM.nut")
require("%rGui/charClientOwners.nut") 
require("%rGui/pServer/profileServerClient.nut") 
require("%appGlobals/pServer/pServerApi.nut")
require("%rGui/consoleCmd.nut")
require("%sqstd/regScriptProfiler.nut")("darg", dlog) 
require("%rGui/notifications/foreignMsgBox.nut")
require("%rGui/notifications/logEvents.nut")
require("%rGui/loading/loadingStateRelay.nut")
require("%rGui/dargVmReload.nut")
require("%rGui/options/optionsExtNames.nut") 
require("%rGui/options/guiOptions.nut") 
require("%rGui/clientState/saveProfile.nut") 
require("%rGui/login/updateRights.nut")
require("%rGui/login/initLoginWTM.nut")
require("%rGui/matching/matchingOnline.nut") 
require("%rGui/matching/gameModesUpdate.nut")
require("%rGui/webRPC.nut")
require("%rGui/debugTools/dbgToString.nut")
require("%rGui/debugTools/dbgQuitAfterTime.nut")
require("%rGui/currencies.nut")
require("%rGui/urlType.nut")
require("%rGui/url.nut")
require("%rGui/language.nut")
require("%rGui/debugTools/dbgUtils.nut")
require("%rGui/debugTools/dbgWindowResolution.nut")
require("%rGui/debugTools/dbgDedicLogerrs.nut")
require("%rGui/bqQueue.nut")
require("%rGui/battlePerfstats.nut")
require("%rGui/mplayerCallbacks.nut")
require("%appGlobals/clientState/initWindowState.nut")
require("%rGui/account/legalAcceptWnd.nut")
require("%globalScripts/windowStateEs.nut")
require("%appGlobals/windowState.nut").allowDebug(true)
require("%rGui/contacts/contactsState.nut") 
require("%rGui/squad/squadManager.nut") 
require("%rGui/initHangar.nut")
require("%rGui/updater/connectionStatus/initConnectionStatus.nut")
require("%rGui/updater/initAddonsState.nut")
require("%rGui/activeControls.nut")
require("%rGui/login/consentGoogleState.nut")
require("%rGui/login/previewIDFAWnd.nut")
require("%rGui/login/reloginAuto.nut")



log($"DaRg scripts load before login {get_time_msec() - startLoadTime} msec")
setIsScriptsLoading(false)

local sceneAfterLogin = null
local isAllScriptsLoaded = Watched(false)

isHudAttached.subscribe(@(v) enableClickButtons(!v))
enableClickButtons(!isHudAttached.get())


function loadAfterLoginImpl() {
  if (sceneAfterLogin != null)
    return
  
  
  setIsScriptsLoading(true)
  let t = get_time_msec()
  log("LOAD RGUI SCRIPTS AFTER LOGIN")
  require("%rGui/backendAfterLogin.nut")
  sceneAfterLogin = require("%rGui/sceneAfterLogin.nut")
  isAllScriptsLoaded.set(true)
  log($"DaRg scripts load after login {get_time_msec() - t} msec")
  setIsScriptsLoading(false)
  
  sendUiBqEvent("load_darg_main_scripts", {
    params = get_platform_string_id()
    paramInt1 = get_time_msec() - t
    status = isLoggedIn.get() ? "after login"
      : isLoginStarted.get() ? "on login"
      : "before login"
  })
}

if (isReadyToFullLoad.get() || !isLoginRequired.get())
  loadAfterLoginImpl() 
function loadAfterLogin() {
  if (sceneAfterLogin != null)
    return
  this_subscriber_call_may_take_up_to_usec(1000 * get_slow_subscriber_threshold_usec())
  start_es_loading()
  loadAfterLoginImpl()
  end_es_loading()
}
isReadyToFullLoad.subscribe(@(v) v ? loadAfterLogin() : null)
isLoginRequired.subscribe(@(v) v ? null : loadAfterLogin())

isLoggedIn.subscribe(@(v) v ? closeFMsgBox("errorMessageBox") : closeAllModalWindows())
isInBattle.subscribe(@(_) closeAllModalWindows())

let debugSa = mkWatched(persist, "debugSa", false)
register_command(function() {
  debugSa.set(!debugSa.get())
  log("Debug show safearea: ", debugSa.get())
}, "debug.safeAreaShow")

let debugSafeArea = @() !debugSa.get() ? { watch = debugSa }
  : {
      watch = debugSa
      size = saSize
      margin = saBordersRv
      rendObj = ROBJ_BOX
      fillColor = 0
      borderColor = 0x800000FF
      borderWidth = 1
    }

let waitbox = @() {
  watch = waitboxes
  size = FLEX
  children = waitboxes.get().len() == 0 ? null
    : bgShadedDark.__merge({
        key = waitboxes.get()[0]
        size = FLEX
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        flow = FLOW_VERTICAL
        gap = hdpx(50)
        children = [
          {
            size = const [hdpx(1200), SIZE_TO_CONTENT]
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            halign = ALIGN_CENTER
            text = waitboxes.get()[0].text
          }.__update(fontSmall)
          spinner
        ]
        animations = [spinnerOpacityAnim]
      })
}

return function() {
  let children = !isLoggedIn.get() && isLoginRequired.get()
      ? [sceneBeforeLogin, modalWindowsComponent]
    : isInLoadingScreen.get() ? [loadingScreen]
    : [sceneAfterLogin]
  children.append(hotkeysPanel, tooltipComp, inspectorRoot, debugSafeArea, waitbox, dbgOverlayComponent)
  if (isDebugTouchesActive.get()) {
    children.insert(0, debugTouchesHandlerComp)
    children.append(debugTouchesUi)
  }
  if (!isPlayingReplay.get() || isHudVisible.get())
    children.append(deviceStateArea, fpsLineComp)
  return {
    watch = [isInLoadingScreen, isLoggedIn, isLoginRequired, isAllScriptsLoaded, isDebugTouchesActive,
      needShowCursor, isPlayingReplay, isHudVisible]
    key = "sceneRoot"
    size = FLEX
    children
    cursor = needShowCursor.get() ? cursor : null
  }
}
