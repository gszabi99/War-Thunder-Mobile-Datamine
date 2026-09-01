#default:forbid-root-table

from "%globalsDarg/darg_library.nut" import *
from "dagor.random" import set_rnd_seed
from "dagor.time" import ref_time_ticks
import "messages.nut" as messages
import "updaterScene.nut" as updaterScene


set_rnd_seed(ref_time_ticks())


gui_scene.setConfigProps({
  clickRumbleEnabled = false
  defTextColor = 0xFFFFFFFF
})

return {
  size = FLEX
  children = [
    updaterScene
    messages
  ]
}