from "%globalsDarg/darg_library.nut" import *
let { get_local_unixtime } = require("dagor.time")
let { set_rnd_seed } = require("dagor.random")
set_rnd_seed(get_local_unixtime())

let updaterScene = require("updaterScene.nut")
let messages = require("messages.nut")

gui_scene.setConfigProps({
  clickRumbleEnabled = false
})

if ("defTextColor" in gui_scene.config)
  gui_scene.setConfigProps({ defTextColor = 0xFFFFFFFF })

return {
  size = flex()
  children = [
    updaterScene
    messages
  ]
}