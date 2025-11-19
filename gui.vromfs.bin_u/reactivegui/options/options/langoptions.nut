from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
from "app" import get_base_game_version_str
from "soundOptions" import set_option_speech_country_type, get_option_speech_country_type, UNIT_LANG, GAME_LANG

let { getLocalLanguage, getSpeechLanguage, setSpeechLanguage } = require("language")
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { ndbRead, ndbExists } = require("nestdb")
let { check_version } = require("%sqstd/version_compare.nut")
let { has_extended_sound } = require("%appGlobals/permissions.nut")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")


const NDB_ID = "language.localizationInfo"
let language = Watched(getLocalLanguage())
let languageVoice = Watched(getSpeechLanguage())

let isSpeechTypeSupported = check_version(">=1.20.0.26", get_base_game_version_str())

let langByUnitCrew = [UNIT_LANG, GAME_LANG]
function getSpeechType() {
  if (!isSettingsAvailable.get() || !has_extended_sound.get() || !isSpeechTypeSupported)
    return GAME_LANG
  let speechType = get_option_speech_country_type()
  return langByUnitCrew.contains(speechType) ? speechType : GAME_LANG
}
let speechUnitCountryType = Watched(getSpeechType())

let langById = {}
let getLangTitle = @(id) langById?[id].title ?? id

let optLang = {
  locId = "options/language_ui"
  ctrlType = OCT_LIST
  value = language
  list = Watched([])
  valToString = getLangTitle
}

let optLangByUnit = {
  locId = "options/speech_country_type"
  ctrlType = OCT_LIST
  value = speechUnitCountryType
  list = Computed(@() has_extended_sound.get() && isSpeechTypeSupported ? langByUnitCrew : [])
  valToString = @(v) loc(v == UNIT_LANG ? "options/speech_country_unit" : "options/speech_country_player")
}

let optLangVoice = {
  locId = "options/speech_country_list"
  ctrlType = OCT_LIST
  value = languageVoice
  list = Watched([])
  valToString = getLangTitle
}

function applySpeechUnitType() {
  if (!isSettingsAvailable.get() || get_option_speech_country_type() == speechUnitCountryType.get())
    return
  set_option_speech_country_type(speechUnitCountryType.get())
  eventbus_send("saveProfile", {})
}

function applyListToOptions() {
  let langList = ndbExists(NDB_ID) ? ndbRead(NDB_ID) : []
  foreach (l in langList)
    langById[l.id] <- l
  optLang.list.set(langList.map(@(l) l.id))
  let voiceList = langList.filter(@(l) l.hasUnitSpeech).map(@(l) l.id)
  optLangVoice.list.set(speechUnitCountryType.get() == UNIT_LANG ? [] : voiceList)
  if (voiceList.len() > 0 && !voiceList.contains(languageVoice.get()))
    languageVoice.set(voiceList[0])
}

applySpeechUnitType()
applyListToOptions()
eventbus_subscribe("onAcesInitComplete", @(_) language.set(getLocalLanguage()))
eventbus_subscribe("localizationInfoUpdate", @(_) applyListToOptions())
language.subscribe(@(value) eventbus_send("language.setWithReloadScene", { value }))
languageVoice.subscribe(function(value) {
  setSpeechLanguage(value)
  eventbus_send("saveProfile", {})}
)
speechUnitCountryType.subscribe(function(_) {
  applySpeechUnitType()
  applyListToOptions()
})
has_extended_sound.subscribe(@(v) v ? null : speechUnitCountryType.set(GAME_LANG))
isSettingsAvailable.subscribe(function(v) {
  if (!v)
    return
  speechUnitCountryType.set(getSpeechType())
  applySpeechUnitType()
})

return {
  optLang
  langOptions = [
    optLang
    optLangByUnit
    optLangVoice
  ]
}