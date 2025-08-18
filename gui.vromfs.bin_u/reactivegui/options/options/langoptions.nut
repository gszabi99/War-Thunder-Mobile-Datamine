from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
from "soundOptions" import set_option_speech_country_type, get_option_speech_country_type, UNIT_LANG, GAME_LANG

let { getLocalLanguage, getSpeechLanguage, setSpeechLanguage } = require("language")
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { ndbRead, ndbExists } = require("nestdb")
let { isExtendedSoundAllowed } = require("%rGui/options/debugOptions.nut")

const NDB_ID = "language.localizationInfo"
let language = Watched(getLocalLanguage())
let languageVoice = Watched(getSpeechLanguage())
let speechUnitCountryType = Watched(get_option_speech_country_type())

let langById = {}
let getLangTitle = @(id) langById?[id].title ?? id

let optLang = {
  locId = "options/language_ui"
  ctrlType = OCT_LIST
  value = language
  list = Watched([])
  valToString = getLangTitle
}

let langByUnitCrew = [UNIT_LANG, GAME_LANG]
let optLangByUnit = {
  locId = "options/speech_country_type"
  ctrlType = OCT_LIST
  value = speechUnitCountryType
  list = Computed(@() isExtendedSoundAllowed.get() ? langByUnitCrew : [])
  valToString = @(v) loc(v == UNIT_LANG ? "options/speech_country_unit" : "options/speech_country_player")
}

let optLangVoice = {
  locId = "options/speech_country_list"
  ctrlType = OCT_LIST
  value = languageVoice
  list = Watched([])
  valToString = getLangTitle
}

function applyListToOptions() {
  let langList = ndbExists(NDB_ID) ? ndbRead(NDB_ID) : []
  foreach (l in langList)
    langById[l.id] <- l
  optLang.list(langList.map(@(l) l.id))
  let voiceList = langList.filter(@(l) l.hasUnitSpeech).map(@(l) l.id)
  optLangVoice.list(speechUnitCountryType.get() == UNIT_LANG ? [] : voiceList)
  if (voiceList.len() > 0 && !voiceList.contains(languageVoice.get()))
    languageVoice.set(voiceList[0])
}

applyListToOptions()
eventbus_subscribe("onAcesInitComplete", function(_) {
  language.set(getLocalLanguage())
  speechUnitCountryType.set(get_option_speech_country_type())
})
eventbus_subscribe("localizationInfoUpdate", @(_) applyListToOptions())
language.subscribe(@(value) eventbus_send("language.setWithReloadScene", { value }))
languageVoice.subscribe(function(value) {
  setSpeechLanguage(value)
  eventbus_send("saveProfile", {})}
)
speechUnitCountryType.subscribe(function(value) {
  set_option_speech_country_type(value)
  applyListToOptions()
})

return {
  optLang
  langOptions = [
    optLang
    optLangByUnit
    optLangVoice
  ]
}