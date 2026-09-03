from "%globalsDarg/darg_library.nut" import *
import "DataBlock" as DataBlock
from "console" import register_command
from "dagor.workcycle" import resetTimeout
from "eventbus" import eventbus_send, eventbus_subscribe
import "fonts" as fonts
from "language" import getLocalLanguage
from "modules" import reset_static_memos
from "nestdb" import ndbWrite
from "scriptRespondent" import registerRespondent
from "%globalScripts/systemConfig.nut" import setSystemConfigOption
from "%appGlobals/clientState/languageState.nut" import currentLanguage, currentSteamLanguage
from "%appGlobals/loginState.nut" import isReadyToFullLoad
from "%appGlobals/updater/addons.nut" import resetAddonNamesCache
from "guiScriptUtils" import get_language, set_language, get_localization_blk_copy
from "%rGui/clientState/saveProfile.nut" import saveProfile








let allLangs = [
  { id = "English",     iso639p1LngId = "en", hasUnitSpeech = true }
  { id = "Russian",     iso639p1LngId = "ru", hasUnitSpeech = true,
      gjNetLngId = "ru", wtmobLngId = "ru", wtLngId = "ru", cmntLngId = "ru", legalApiLngId = "ru" }
  { id = "French",      iso639p1LngId = "fr", hasUnitSpeech = true,
      gjNetLngId = "fr", wtmobLngId = "fr", wtLngId = "fr", legalApiLngId = "fr" }
  { id = "Italian",     iso639p1LngId = "it",
      gjNetLngId = "it", legalApiLngId = "it" }
  { id = "German",      iso639p1LngId = "de", hasUnitSpeech = true,
      gjNetLngId = "de", wtmobLngId = "de", wtLngId = "de", legalApiLngId = "de" }
  { id = "Spanish",     iso639p1LngId = "es",
      gjNetLngId = "es", wtmobLngId = "es", wtLngId = "es", legalApiLngId = "es" }
  { id = "Portuguese",  iso639p1LngId = "pt",
      gjNetLngId = "pt", wtLngId = "pt", legalApiLngId = "pt" }
  { id = "Greek",       iso639p1LngId = "el",
      legalApiLngId = "el" }
  { id = "Polish",      iso639p1LngId = "pl",
      gjNetLngId = "pl", wtmobLngId = "pl", wtLngId = "pl", legalApiLngId = "pl" }
  { id = "Ukrainian",   iso639p1LngId = "uk",
      wtmobLngId = "ua", legalApiLngId = "ua" }
  { id = "Czech",       iso639p1LngId = "cs",
      gjNetLngId = "cs", wtLngId = "cz", legalApiLngId = "cs" }
  { id = "Turkish",     iso639p1LngId = "tr",
      gjNetLngId = "tr", wtmobLngId = "tr", legalApiLngId = "tr" }
  { id = "Indonesian",  iso639p1LngId = "id",
      legalApiLngId = "id" }
  { id = "Chinese",     iso639p1LngId = "zh", hasUnitSpeech = true,
      gjNetLngId = "zh", wtmobLngId = "zh", wtLngId = "zh", legalApiLngId = "zh" }
  { id = "TChinese",    iso639p1LngId = "zh",
      gjNetLngId = "zh", wtmobLngId = "zh", wtLngId = "zh", legalApiLngId = "zh" }
  { id = "Korean",      iso639p1LngId = "ko",
      gjNetLngId = "ko", wtLngId = "ko", legalApiLngId = "ko" }
  { id = "Japanese",    iso639p1LngId = "ja", hasUnitSpeech = true,
      gjNetLngId = "ja", legalApiLngId = "ja" }
  { id = "Thai",        iso639p1LngId = "th",
      legalApiLngId = "th" }
]
  .map(function(lang) {
    let { id } = lang
    return {
      title = loc($"language/{id}")
      hasUnitSpeech = false
      gjNetLngId    = "en"
      wtmobLngId    = "en"
      wtLngId       = "en"
      cmntLngId     = "en"
      legalApiLngId = "en"
    }.__update(lang)
  })

let saveLanguage = @(langName) currentLanguage.set(langName)

let langsById = {}
local isListInited = false

function setGameLocalization(langId, isForced = false) {
  if (langId == currentLanguage.get() && !isForced)
    return
  log($"setGameLocalization from {currentLanguage.get()} to {langId}")
  fonts.discardLoadedData()
  setSystemConfigOption("language", langId)
  set_language(langId)
  saveLanguage(langId)
  reset_static_memos()
  saveProfile()
  resetAddonNamesCache()
}

function reload() {
  setGameLocalization(currentLanguage.get(), true)
}

let langsList = []


function checkInitList() {
  if (isListInited)
    return
  isListInited = true

  let locBlk = DataBlock()
  get_localization_blk_copy(locBlk)
  let ttBlk = locBlk?.text_translation ?? DataBlock()
  let existingLangs = ttBlk % "lang"

  langsList.replace(allLangs.filter(@(l) existingLangs.contains(l.id) || l.id == "English"))
  langsById.clear()
  foreach (lang in langsList)
    langsById[lang.id] <- lang






}

isReadyToFullLoad.subscribe(function(v) {
  if (v)
    isListInited = false
})

saveLanguage(getLocalLanguage())

function getGameLocalizationInfo() {
  checkInitList()
  return langsList
}


eventbus_subscribe("on_language_changed", function on_language_changed(...) {
  saveLanguage(get_language())
})

ndbWrite("language.localizationInfo", getGameLocalizationInfo())
eventbus_send("localizationInfoUpdate", {})

registerRespondent("get_current_steam_language", @() currentSteamLanguage.get())

local langIdForSet = ""
let setLanguageWithReload = @() setGameLocalization(langIdForSet)

eventbus_subscribe("language.setWithReloadScene", function(msg) {
  langIdForSet = msg.value
  resetTimeout(0.1, setLanguageWithReload)
})

register_command(@() reload(), "ui.language_reload")

let curLangInfo = allLangs.findvalue(@(v) v.id == currentLanguage.get()) ?? allLangs.findvalue(@(v) v.id == "English")
let { gjNetLngId, wtmobLngId, wtLngId, cmntLngId, legalApiLngId, iso639p1LngId } = curLangInfo 
return {
  setGameLocalization
  getGameLocalizationInfo
  curLangInfo

  gjNetLngId
  wtmobLngId
  wtLngId
  cmntLngId
  legalApiLngId
  iso639p1LngId
}
