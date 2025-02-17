from "%globalsDarg/darg_library.nut" import *
// configure scene when hosted in game
let { DBGLEVEL } = require("dagor.system")
let { is_pc } = require("%sqstd/platform.nut")

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
if (is_pc)
  set_slow_update_threshold_usec(300)
require("%sqstd/regScriptDebugger.nut")(debugTableData)
require("console").setObjPrintFunc(debugTableData)