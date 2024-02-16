from "%globalsDarg/darg_library.nut" import *
// configure scene when hosted in game
let { DBGLEVEL } = require("dagor.system")

gui_scene.setConfigProps({
  clickRumbleEnabled = false
  reportNestedWatchedUpdate = DBGLEVEL > 0
  kbCursorControl = true
  actionClickByBehavior = true

  gamepadCursorSpeed = 1.85
  gamepadCursorNonLin = 0.5
  gamepadCursorHoverMinMul = 0.07
  gamepadCursorHoverMaxMul = 0.8
  gamepadCursorHoverMaxTime = 1.0
})

if ("defTextColor" in gui_scene.config)
  gui_scene.setConfigProps({ defTextColor = 0xFFFFFFFF })

require("frp").set_nested_observable_debug(DBGLEVEL > 0)
require("%sqstd/regScriptDebugger.nut")(debugTableData)
require("console").setObjPrintFunc(debugTableData)