from "%globalsDarg/darg_library.nut" import *
from "frp" import warn_on_deprecated_methods
from "dagor.system" import DBGLEVEL
from "controlsOptions" import enable_gyroscope
import "%globalScripts/isAppLoaded.nut" as isAppLoaded
from "%sqstd/platform.nut" import is_pc
from "%appGlobals/loginState.nut" import isOnlineSettingsAvailable

gui_scene.setConfigProps({
  clickRumbleEnabled = false
  reportNestedWatchedUpdate = DBGLEVEL > 0
  kbCursorControl = true
  actionClickByBehavior = true
  defTextColor = 0xFFFFFFFF

  gamepadCursorSpeed = 1.85
  gamepadCursorNonLin = 0.5
  gamepadCursorHoverMinMul = 0.07
  gamepadCursorHoverMaxMul = 0.8
  gamepadCursorHoverMaxTime = 1.0
})

set_nested_observable_debug(DBGLEVEL > 0)

warn_on_deprecated_methods(DBGLEVEL > 0)
if (is_pc)
  set_slow_update_threshold_usec(300)
require("%sqstd/regScriptDebugger.nut")(debugTableData)
require("console").setObjPrintFunc(debugTableData)

enable_gyroscope(true)
isAppLoaded.subscribe(@(_) enable_gyroscope(true))
isOnlineSettingsAvailable.subscribe(@(_) enable_gyroscope(true))
