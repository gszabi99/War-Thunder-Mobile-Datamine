from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import OCT_SLIDER, OCT_LIST
from "soundOptions" import SND_TYPE_MASTER, SND_TYPE_MUSIC, SND_TYPE_MENU_MUSIC, SND_TYPE_SFX,
  SND_TYPE_ENGINE, SND_TYPE_MY_ENGINE, SND_TYPE_GUNS, SND_TYPE_DIALOGS, SND_TYPE_RADIO,
  is_sound_inited, get_sound_volume, set_sound_volume, get_option_voice_message_voice, set_option_voice_message_voice
let { eventbus_send } = require("eventbus")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")
let { optionsVersion } = require("%rGui/options/guiOptions.nut")

const SOUND_MAX = 100 

let getVolumeInt = @(sndType) is_sound_inited() ? (get_sound_volume(sndType) * 100.0 + 0.5).tointeger()
  : 100
let setVolumes = @(sndTypes, val) sndTypes.reduce(function(res, v) {
  if (val == getVolumeInt(v))
    return res
  set_sound_volume(v, val.tofloat() / SOUND_MAX, true)
  return true
}, false)

function mkSoundSlider(sndTypes, locId) {
  function getSaved() {
    let volumes = sndTypes.map(getVolumeInt)
    return volumes.reduce(@(res, v) max(res, v), 0)
  }
  let value = Watched(getSaved())
  function updateSaved() {
    if (!isSettingsAvailable.value)
      return
    if (setVolumes(sndTypes, value.value))
      eventbus_send("saveProfile", {})
  }
  updateSaved()
  isSettingsAvailable.subscribe(function(_) {
    value(getSaved())
    updateSaved()
  })
  value.subscribe(@(_) updateSaved())

  optionsVersion.subscribe(function(_) {
    value(getSaved())
    updateSaved()
  })

  return {
    locId
    value
    ctrlType = OCT_SLIDER
    valToString = @(v) $"{v}%"
    ctrlOverride = {
      min = 0
      max = 100
      unit = 1 
    }
  }
}

let radioMessageVoice = Watched(get_option_voice_message_voice())
isSettingsAvailable.subscribe(@(v) v ? radioMessageVoice.set(get_option_voice_message_voice()) : null)
radioMessageVoice.subscribe(function(value) {
  if (!isSettingsAvailable.get() || value == get_option_voice_message_voice())
    return
  set_option_voice_message_voice(value)
  eventbus_send("saveProfile", {})
})

let optRadioMessagesVoice = {
  locId = "options/radio_messages_voice"
  ctrlType = OCT_LIST
  value = radioMessageVoice
  list = [ 1, 2, 3, 4 ]
  valToString = @(v) loc($"options/radio_messages_voice/voice{v}")
}

log("SoundOptions: is_sound_inited on load ?", is_sound_inited())

return {
  soundOptions = [
    mkSoundSlider([SND_TYPE_MASTER], "options/volume_master")
    mkSoundSlider([SND_TYPE_MUSIC, SND_TYPE_MENU_MUSIC], "options/volume_music")
    mkSoundSlider(
      [ SND_TYPE_SFX, SND_TYPE_ENGINE, SND_TYPE_MY_ENGINE, SND_TYPE_GUNS ],
      "options/volume_sfx")
    mkSoundSlider([SND_TYPE_DIALOGS], "options/volume_dialogs")
    mkSoundSlider([SND_TYPE_RADIO], "options/volume_radio_messages")
    optRadioMessagesVoice
  ]
  radioMessageVoice
}
