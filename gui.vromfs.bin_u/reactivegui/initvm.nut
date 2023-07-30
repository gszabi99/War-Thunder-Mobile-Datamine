// configure scene when hosted in game
let { gui_scene } = require("daRg")
let { DBGLEVEL } = require("dagor.system")
let { debugTableData } = require("%sqStdLibs/helpers/toString.nut")

gui_scene.setConfigProps({
  clickRumbleEnabled = false
  reportNestedWatchedUpdate = DBGLEVEL > 0
  kbCursorControl = true

  gamepadCursorSpeed = 1.85
  gamepadCursorNonLin = 0.5
  gamepadCursorHoverMinMul = 0.07
  gamepadCursorHoverMaxMul = 0.8
  gamepadCursorHoverMaxTime = 1.0
})

require("frp").set_nested_observable_debug(DBGLEVEL > 0)
require("%sqstd/regScriptDebugger.nut")(debugTableData)
require("console").setObjPrintFunc(debugTableData)