from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
from "soundOptions" import *
let { send } = require("eventbus")

const SOUND_MAX = 100 //in the native code they are fixed, and get_volume_limits return always the same values

let getVolumeInt = @(sndType) is_sound_inited() ? (get_sound_volume(sndType) * 100.0 + 0.5).tointeger()
  : 100
let setVolumes = @(sndTypes, val) sndTypes.each(function(st) {
  if (val == getVolumeInt(st))
    return
  set_sound_volume(st, val.tofloat() / SOUND_MAX, true)
  send("saveProfile", {})
})

let function mkSoundSlider(sndTypes, locId) {
  let volumes = sndTypes.map(getVolumeInt)
  let curVal = volumes.reduce(@(res, v) max(res, v), 0)
  let value = Watched(curVal)
  setVolumes(sndTypes, curVal) //sync volumes
  value.subscribe(@(v) setVolumes(sndTypes, v))
  return {
    locId
    value
    ctrlType = OCT_SLIDER
    valToString = @(v) $"{v}%"
    ctrlOverride = {
      min = 0
      max = 100
      unit = 1 //step
    }
  }
}

log("SoundOptions: is_sound_inited on load ?", is_sound_inited())

return [
  mkSoundSlider([SND_TYPE_MASTER], "options/volume_master")
  mkSoundSlider([SND_TYPE_MUSIC, SND_TYPE_MENU_MUSIC], "options/volume_music")
  mkSoundSlider(
    [ SND_TYPE_SFX, SND_TYPE_ENGINE, SND_TYPE_MY_ENGINE, SND_TYPE_GUNS ],
    "options/volume_sfx")
  mkSoundSlider([SND_TYPE_DIALOGS], "options/volume_dialogs")
]
