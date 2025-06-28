from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { hardPersistWatched } = require("%sqstd/globalState.nut")


let isExtendedSoundAllowed = hardPersistWatched("debugOptions.isExtendedSoundAllowed", false)

register_command(
  function() {
    isExtendedSoundAllowed.set(!isExtendedSoundAllowed.get())
    console_print($"isExtendedSoundAllowed = {isExtendedSoundAllowed.get()}") 
  },
  "ui.debug.extendedSound")

return {
  isExtendedSoundAllowed
}