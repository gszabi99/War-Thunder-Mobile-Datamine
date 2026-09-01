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
  { id = "English",     chatId = "en", hasUnitSpeech = true }
  { id = "Russian",     chatId = "ru", hasUnitSpeech = true }
  { id = "French",      chatId = "fr", hasUnitSpeech = true }
  { id = "Italian",     chatId = "it" }
  { id = "German",      chatId = "de", hasUnitSpeech = true }
  { id = "Spanish",     chatId = "es" }
  { id = "Portuguese",  chatId = "pt" }
  { id = "Greek",       chatId = "el" }
  { id = "Polish",      chatId = "pl" }
  { id = "Ukrainian",   chatId = "uk" }
  { id = "Czech",       chatId = "cs" }
  { id = "Turkish",     chatId = "tr" }
  { id = "Indonesian",  chatId = "id" }
  { id = "Chinese",     chatId = "zh", hasUnitSpeech = true }
  { id = "TChinese",    chatId = "zh" }
  { id = "Korean",      chatId = "ko" }
  { id = "Japanese",    chatId = "jp", hasUnitSpeech = true }
  { id = "Thai",        chatId = "th" }
]
  .map(function(lang) {
    let { id } = lang
    return {
      title = loc($"language/{id}")
      chatId = "en"
      hasUnitSpeech = false
    }.__update(lang)
  })



local shortLangName = loc("current_lang")

function saveLanguage(langName) {
  if (currentLanguage.get() == langName)
    return
  currentLanguage.set(langName)
  shortLangName = loc("current_lang")
}

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

  langsList.replace(allLangs.filter(@(l) existingLangs.contains(l.id)))
  langsById.clear()
  foreach (lang in langsList)
    langsById[lang.id] <- lang






}

isReadyToFullLoad.subscribe(function(v) {
  if (v)
    isListInited = false
})

saveLanguage(getLocalLanguage())

let getShortName = @() shortLangName

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

return {
  getShortName
  setGameLocalization
  getGameLocalizationInfo
}
