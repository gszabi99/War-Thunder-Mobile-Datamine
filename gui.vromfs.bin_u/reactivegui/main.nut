
from "%globalsDarg/darg_library.nut" import *
from "ecs" import clear_vm_entity_systems, start_es_loading, end_es_loading

log("LOAD RGUI SCRIPTS CORE")
clear_vm_entity_systems()

require("%appGlobals/sqevents.nut")
require("%globalScripts/sharedEnums.nut")
require("initVM.nut")
require("%appGlobals/pServer/pServerApi.nut")
require("consoleCmd.nut")
require("%rGui/notifications/foreignMsgBox.nut")
require("%rGui/notifications/appsFlyerEvents.nut")
require("%rGui/options/guiOptions.nut") //need to register options before load profile
require("debugTools/pServerConsoleCmd.nut")
require("%appGlobals/clientState/initWindowState.nut")
require("account/legalAcceptWnd.nut")
require("%globalScripts/windowStateEs.nut")
require("%globalScripts/windowState.nut").allowDebug(true)

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
let { needCursorForActiveInputDevice, isGamepad } = require("activeControls.nut")
let hotkeysPanel = require("controlsMenu/hotkeysPanel.nut")
let { debugTouchesUi, isDebugTouchesActive } = require("debugTools/debugTouches.nut")
let { getenv = @(...) null} = require_optional("system")
let deviceStateArea = require("%rGui/hud/deviceState.nut")
let watermark = require("%rGui/mainMenu/watermark.nut")
let { tooltipComp } = require("tooltip.nut")

local sceneAfterLogin = null
local isAllScriptsLoaded = Watched(false)

let forceHideCursor = Watched(false)
let needCursorInHud = Computed(@() !isGamepad.value || !isHudAttached.value || hasModalWindows.value)
let needShowCursor  = Computed(@() !forceHideCursor.value
                                  && needCursorForActiveInputDevice.value
                                  && (!isInBattle.value || (isHudVisible.value && needCursorInHud.value)))

register_command(@() forceHideCursor(!forceHideCursor.value), "ui.force_hide_mouse_pointer")


let function loadAfterLoginImpl() {
  log("LOAD RGUI SCRIPTS AFTER LOGIN")
  sceneAfterLogin = require("%rGui/sceneAfterLogin.nut")
  isAllScriptsLoaded(true)
}

if (isReadyToFullLoad.value || !isLoginRequired.value || getenv("QUIRREL_SCRIPTS_TESTS"))
  loadAfterLoginImpl() //when load from native code start_es_loading is already called
let function loadAfterLogin() {
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

return function() {
  let children = !isLoggedIn.value && isLoginRequired.value
      ? [sceneBeforeLogin, modalWindowsComponent]
    : isInLoadingScreen.value ? [loadingScreen]
    : [sceneAfterLogin]
  children.append(hotkeysPanel, tooltipComp, inspectorRoot, debugSafeArea, fpsLineComp, deviceStateArea, watermark)
  if (isDebugTouchesActive.value)
    children.append(debugTouchesUi)
  return {
    watch = [isInLoadingScreen, isLoggedIn, isAllScriptsLoaded, isDebugTouchesActive, needShowCursor]
    size = flex()
    children
    cursor = needShowCursor.value ? cursor : null
  }
}
