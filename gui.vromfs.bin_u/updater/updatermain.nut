from "%globalsDarg/darg_library.nut" import *
let { ref_time_ticks } = require("dagor.time")
let { set_rnd_seed } = require("dagor.random")
set_rnd_seed(ref_time_ticks())

let updaterScene = require("updaterScene.nut")
let messages = require("messages.nut")

gui_scene.setConfigProps({
  clickRumbleEnabled = false
  defTextColor = 0xFFFFFFFF
})

return {
  size = flex()
  children = [
    updaterScene
    messages
  ]
}