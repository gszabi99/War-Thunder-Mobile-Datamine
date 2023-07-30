//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let updateClientStates = require("clientState/updateClientStates.nut")

const ROOT_BLK = "%gui/emptyScene.blk"

let function loadRootScreen() {
  let guiScene = ::get_cur_gui_scene()
  guiScene.loadScene(ROOT_BLK, null)
  guiScene.showCursor(false) //show cursor by darg only
  updateClientStates()
}

::gui_start_empty_screen <- loadRootScreen

return loadRootScreen