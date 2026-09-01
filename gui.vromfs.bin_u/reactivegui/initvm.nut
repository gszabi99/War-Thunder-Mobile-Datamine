from "%globalsDarg/darg_library.nut" import *
from "app" import get_cur_circuit_name
from "controlsOptions" import enable_gyroscope
from "dagor.system" import DBGLEVEL
from "%sqstd/platform.nut" import is_pc
import "%globalScripts/isAppLoaded.nut" as isAppLoaded
from "%globalScripts/systemConfig.nut" import getSystemConfigOption, setSystemConfigOption
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


warn_on_deprecated_methods(DBGLEVEL > 0)
if (is_pc)
  set_slow_update_threshold_usec(300)
require("%sqstd/regScriptDebugger.nut")(debugTableData)
require("console").setObjPrintFunc(debugTableData)

enable_gyroscope(true)
isAppLoaded.subscribe(@(_) enable_gyroscope(true))
isOnlineSettingsAvailable.subscribe(@(_) enable_gyroscope(true))

if (is_pc && get_cur_circuit_name().indexof("production") == null
  && getSystemConfigOption("debug/netLogerr") == null)
    setSystemConfigOption("debug/netLogerr", true)
