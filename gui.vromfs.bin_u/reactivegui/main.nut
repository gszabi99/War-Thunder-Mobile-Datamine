from "%globalsDarg/darg_library.nut" import *
from "ecs" import clear_vm_entity_systems, start_es_loading, end_es_loading
from "dagor.system" import DBGLEVEL
from "%rGui/cursor.nut" import needShowCursor, cursor

let { get_time_msec } = require("dagor.time")
let isScriptsLoading = require("%rGui/isScriptsLoading.nut")
let { markScriptsLoading } = require("%darg/helpers/bitmap.nut")
function setIsScriptsLoading(v) {
  markScriptsLoading(v)
  isScriptsLoading.set(v)
}
isScriptsLoading.whiteListMutatorClosure(setIsScriptsLoading)

log("LOAD RGUI SCRIPTS CORE")
setIsScriptsLoading(true)
let startLoadTime = get_time_msec()
clear_vm_entity_systems()

require("%appGlobals/sqevents.nut")
require("%rGui/initVM.nut")
require("%appGlobals/pServer/pServerApi.nut")
require("%rGui/consoleCmd.nut")
require("%sqstd/regScriptProfiler.nut")("darg", dlog) 
require("%rGui/notifications/foreignMsgBox.nut")
require("%rGui/notifications/logEvents.nut")
require("%rGui/options/guiOptions.nut") 
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
require("%rGui/debugTools/debugSafeArea.nut")

let { get_platform_string_id } = require("platform")
let { inspectorRoot } = require("%darg/helpers/inspector.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { modalWindowsComponent, closeAllModalWindows } = require("%rGui/components/modalWindows.nut")
let { dbgOverlayComponent } = require("%rGui/components/debugOverlay.nut")
let { isInLoadingScreen, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isHudAttached } = require("%appGlobals/clientState/hudState.nut")
let { isLoggedIn, isLoginRequired, isReadyToFullLoad, isLoginStarted
} = require("%appGlobals/loginState.nut")
let { loadingScreen } = require("%rGui/loading/loadingScreen.nut")
let sceneBeforeLogin = require("%rGui/login/sceneBeforeLogin.nut")
let { register_command } = require("console")
let fpsLineComp = require("%rGui/mainMenu/fpsLineComp.nut")
let { closeFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { enableClickButtons }  = require("%rGui/controlsMenu/gpActBtn.nut")
let hotkeysPanel = require("%rGui/controlsMenu/hotkeysPanel.nut")
let { debugTouchesUi, debugTouchesHandlerComp, isDebugTouchesActive } = require("%rGui/debugTools/debugTouches.nut")
let deviceStateArea = require("%rGui/hud/deviceState.nut")
let { tooltipComp } = require("%rGui/tooltip.nut")
let { waitboxes } = require("%rGui/notifications/waitBox.nut")
let { bgShadedDark } = require("%rGui/style/backgrounds.nut")
let { spinnerOpacityAnim, spinner } = require("%rGui/components/spinner.nut")

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
  size = flex()
  children = waitboxes.get().len() == 0 ? null
    : bgShadedDark.__merge({
        key = waitboxes.get()[0]
        size = flex()
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
  children.append(hotkeysPanel, tooltipComp, inspectorRoot, debugSafeArea, fpsLineComp,
    deviceStateArea, waitbox, dbgOverlayComponent)
  if (isDebugTouchesActive.get()) {
    children.insert(0, debugTouchesHandlerComp)
    children.append(debugTouchesUi)
  }
  return {
    watch = [isInLoadingScreen, isLoggedIn, isLoginRequired, isAllScriptsLoaded, isDebugTouchesActive, needShowCursor]
    key = "sceneRoot"
    size = flex()
    children
    cursor = needShowCursor.get() ? cursor : null
  }
}
