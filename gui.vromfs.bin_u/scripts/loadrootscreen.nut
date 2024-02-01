from "%scripts/dagui_natives.nut" import get_cur_gui_scene
from "%scripts/dagui_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let updateClientStates = require("clientState/updateClientStates.nut")

const ROOT_BLK = "%gui/emptyScene.blk"

function loadRootScreen(...) {
  let guiScene = get_cur_gui_scene()
  guiScene.loadScene(ROOT_BLK, null)
  guiScene.showCursor(false) //show cursor by darg only
  updateClientStates()
}

eventbus_subscribe("gui_start_empty_screen", loadRootScreen)

return loadRootScreen