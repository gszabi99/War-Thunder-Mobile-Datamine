from "eventbus" import eventbus_subscribe
from "dagui" import get_cur_gui_scene


const ROOT_BLK = "%gui/emptyScene.blk"

function loadRootScreen(...) {
  let guiScene = get_cur_gui_scene()
  guiScene.loadScene(ROOT_BLK, null)
  guiScene.showCursor(false) 
}

eventbus_subscribe("gui_start_empty_screen", loadRootScreen)

return loadRootScreen