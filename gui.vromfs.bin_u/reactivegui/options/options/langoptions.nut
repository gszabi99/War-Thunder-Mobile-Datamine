from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { getLocalLanguage, getSpeechLanguage, setSpeechLanguage } = require("language")
let eventbus = require("eventbus")
let { DBGLEVEL } = require("dagor.system")
let { ndbRead, ndbExists } = require("nestdb")

const NDB_ID = "language.localizationInfo"
let language = Watched(getLocalLanguage())
let languageVoice = Watched(getSpeechLanguage())

let langById = {}
let getLangTitle = @(id) langById?[id].title ?? id

let optLang = {
  locId = "options/language_ui"
  ctrlType = OCT_LIST
  value = language
  list = Watched([])
  valToString = getLangTitle
}

let optLangVoice = {
  locId = "options/language_voice"
  ctrlType = OCT_LIST
  value = languageVoice
  list = Watched([])
  valToString = getLangTitle
}

let function applyListToOptions() {
  let langList = ndbExists(NDB_ID) ? ndbRead(NDB_ID) : []
  foreach (l in langList)
    langById[l.id] <- l
  optLang.list(langList.map(@(l) l.id))
  let voiceList = langList.filter(@(l) l.hasUnitSpeech).map(@(l) l.id)
  optLangVoice.list(voiceList)
  if (voiceList.len() > 0 && !voiceList.contains(languageVoice.value))
    languageVoice(voiceList[0])
}

applyListToOptions()
eventbus.subscribe("localizationInfoUpdate", @(_) applyListToOptions())
language.subscribe(@(value) eventbus.send("language.setWithReloadScene", { value }))
languageVoice.subscribe(@(value) setSpeechLanguage(value))

return {
  optLang
  langOptions = [
    optLang
    DBGLEVEL > 0 ? optLangVoice : null
  ]
}