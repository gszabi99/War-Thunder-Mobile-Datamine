from "%globalsDarg/darg_library.nut" import *
from "ecs" import clear_vm_entity_systems, start_es_loading, end_es_loading
let { get_time_msec } = require("dagor.time")
let isScriptsLoading = require("isScriptsLoading.nut")
let setIsScriptsLoading = @(v) isScriptsLoading.set(v)
isScriptsLoading.whiteListMutatorClosure(setIsScriptsLoading)

log("LOAD RGUI SCRIPTS CORE")
setIsScriptsLoading(true)
let startLoadTime = get_time_msec()
clear_vm_entity_systems()

require("%appGlobals/sqevents.nut")
require("initVM.nut")
require("%appGlobals/pServer/pServerApi.nut")
require("consoleCmd.nut")
require("%sqstd/regScriptProfiler.nut")("darg")
require("%rGui/notifications/foreignMsgBox.nut")
require("%rGui/notifications/logEvents.nut")
require("%rGui/options/guiOptions.nut") //need to register options before load profile
require("debugTools/pServerConsoleCmd.nut")
require("%appGlobals/clientState/initWindowState.nut")
require("account/legalAcceptWnd.nut")
require("levelUp/levelUpRewards.nut")
require("%globalScripts/windowStateEs.nut")
require("%globalScripts/windowState.nut").allowDebug(true)
require("contacts/contactsState.nut") //need to catch notifications before login finish
require("squad/squadManager.nut") //need to catch notifications before login finish
require("initHangar.nut")
require("updater/connectionStatus/initConnectionStatus.nut")
require("activeControls.nut")

let { inspectorRoot } = require("%darg/helpers/inspector.nut")
let { modalWindowsComponent, hideAllModalWindows, hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { isInLoadingScreen, isInBattle, isHudVisible } = require("%appGlobals/clientState/clientState.nut")
let { isHudAttached } = require("%appGlobals/clientState/hudState.nut")
let { isLoggedIn, isLoginRequired, isReadyToFullLoad } = require("%appGlobals/loginState.nut")
let { loadingScreen } = require("%rGui/loading/loadingScreen.nut")
let sceneBeforeLogin = require("%rGui/login/sceneBeforeLogin.nut")
let { register_command } = require("console")
let fpsLineComp = require("%rGui/mainMenu/fpsLineComp.nut")
let { closeFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { needCursorForActiveInputDevice, isGamepad } = require("%appGlobals/activeControls.nut")
let hotkeysPanel = require("controlsMenu/hotkeysPanel.nut")
let { debugTouchesUi, isDebugTouchesActive } = require("debugTools/debugTouches.nut")
let deviceStateArea = require("%rGui/hud/deviceState.nut")
let { tooltipComp } = require("tooltip.nut")
let { waitboxes } = require("notifications/waitBox.nut")
let { bgShadedDark } = require("style/backgrounds.nut")
let { spinnerOpacityAnim, spinner } = require("components/spinner.nut")

log($"DaRg scripts load before login {get_time_msec() - startLoadTime} msec")
setIsScriptsLoading(false)

local sceneAfterLogin = null
local isAllScriptsLoaded = Watched(false)

let forceHideCursor = Watched(false)
let needCursorInHud = Computed(@() !isGamepad.value || !isHudAttached.value || hasModalWindows.value)
let needShowCursor  = Computed(@() !forceHideCursor.value
                                  && needCursorForActiveInputDevice.value
                                  && (!isInBattle.value || (isHudVisible.value && needCursorInHud.value)))

register_command(@() forceHideCursor(!forceHideCursor.value), "ui.force_hide_mouse_pointer")


function loadAfterLoginImpl() {
  if (sceneAfterLogin != null)
    return
  //let profiler = require("dagor.profiler")
  //profiler.start()
  setIsScriptsLoading(true)
  let t = get_time_msec()
  log("LOAD RGUI SCRIPTS AFTER LOGIN")
  sceneAfterLogin = require("%rGui/sceneAfterLogin.nut")
  isAllScriptsLoaded(true)
  log($"DaRg scripts load after login {get_time_msec() - t} msec")
  setIsScriptsLoading(false)
  //profiler.stop_and_save_to_file("../../profiler.csv")
}

if (isReadyToFullLoad.value || !isLoginRequired.value)
  loadAfterLoginImpl() //when load from native code start_es_loading is already called
function loadAfterLogin() {
  if (sceneAfterLogin != null)
    return
  start_es_loading()
  loadAfterLoginImpl()
  end_es_loading()
}
isReadyToFullLoad.subscribe(@(v) v ? loadAfterLogin() : null)
isLoginRequired.subscribe(@(v) v ? null : loadAfterLogin())

isLoggedIn.subscribe(@(v) v ? closeFMsgBox("errorMessageBox") : hideAllModalWindows())
isInBattle.subscribe(@(_) hideAllModalWindows())

let debugSa = mkWatched(persist, "debugSa", false)
register_command(function() {
  debugSa(!debugSa.value)
  log("Debug show safearea: ", debugSa.value)
}, "debug.safeAreaShow")

let debugSafeArea = @() !debugSa.value ? { watch = debugSa }
  : {
      watch = debugSa
      size = saSize
      margin = saBordersRv
      rendObj = ROBJ_BOX
      fillColor = 0
      borderColor = 0x800000FF
      borderWidth = 1
    }

let cursorSize = hdpxi(32)
let cursor = Cursor({
  size = [cursorSize, cursorSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#cursor.svg:{cursorSize}:{cursorSize}")
})

let waitbox = @() {
  watch = waitboxes
  size = flex()
  children = waitboxes.value.len() == 0 ? null
    : bgShadedDark.__merge({
        key = waitboxes.value[0]
        size = flex()
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        flow = FLOW_VERTICAL
        gap = hdpx(50)
        children = [
          {
            size = [hdpx(1200), SIZE_TO_CONTENT]
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            halign = ALIGN_CENTER
            text = waitboxes.value[0].text
          }.__update(fontSmall)
          spinner
        ]
        animations = [spinnerOpacityAnim]
      })
}

return function() {
  let children = !isLoggedIn.value && isLoginRequired.value
      ? [sceneBeforeLogin, modalWindowsComponent]
    : isInLoadingScreen.value ? [loadingScreen]
    : [sceneAfterLogin]
  children.append(hotkeysPanel, tooltipComp, inspectorRoot, debugSafeArea, fpsLineComp, deviceStateArea, waitbox)
  if (isDebugTouchesActive.value)
    children.append(debugTouchesUi)
  return {
    watch = [isInLoadingScreen, isLoggedIn, isLoginRequired, isAllScriptsLoaded, isDebugTouchesActive, needShowCursor]
    key = "sceneRoot"
    size = flex()
    children
    cursor = needShowCursor.value ? cursor : null
  }
}
