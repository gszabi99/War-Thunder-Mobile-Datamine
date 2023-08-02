from "%globalsDarg/darg_library.nut" import *
let updaterScene = require("updaterScene.nut")
let messages = require("messages.nut")

gui_scene.setConfigProps({
  clickRumbleEnabled = false
})

return {
  size = flex()
  children = [
    updaterScene
    messages
  ]
}