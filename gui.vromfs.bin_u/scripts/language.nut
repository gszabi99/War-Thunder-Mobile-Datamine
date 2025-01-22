from "%scripts/dagui_natives.nut" import get_language, set_language, get_localization_blk_copy
from "%scripts/dagui_library.nut" import *

let { g_listener_priority } = require("%scripts/g_listener_priority.nut")
let fonts = require("fonts")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { getLocalLanguage } = require("language")
let { register_command } = require("console")
let { resetTimeout } = require("dagor.workcycle")
let { ndbWrite } = require("nestdb")
let { saveProfile } = require("%scripts/clientState/saveProfile.nut")
let { subscribe_handler } = require("%sqStdLibs/helpers/subscriptions.nut")
let DataBlock  = require("DataBlock")
let { setSystemConfigOption } = require("%globalScripts/systemConfig.nut")
let { registerRespondent } = require("scriptRespondent")
let { resetAddonNamesCache } = require("%appGlobals/updater/addons.nut")

// Please use lang codes from ISO 639-1 standard for chatId
// See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
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

local currentLanguage = null
local currentSteamLanguage = ""
local shortLangName = ""

let steamLanguages = {
  English = "english"
  French = "french"
  Italian = "italian"
  German = "german"
  Spanish = "spanish"
  Russian = "russian"
  Polish = "polish"
  Czech = "czech"
  Turkish = "turkish"
  Chinese = "schinese"
  Japanese = "japanese"
  Portuguese = "portuguese"
  Greek = "greek"
  Ukrainian = "ukrainian"
  Hungarian = "hungarian"
  Korean = "koreana"
  TChinese = "tchinese"
  HChinese = "schinese"
  Thai = "thai"
}

function onChangeLanguage() {
  currentSteamLanguage = steamLanguages?[currentLanguage] ?? "english";
}

function saveLanguage(langName) {
  if (currentLanguage == langName)
    return
  currentLanguage = langName
  shortLangName = loc("current_lang")
  onChangeLanguage()
}

let langsById = {}
local isListInited = false

function setGameLocalization(langId, isForced = false) {
  if (langId == currentLanguage && !isForced)
    return
  log($"setGameLocalization from {currentLanguage} to {langId}")
  fonts.discardLoadedData()
  setSystemConfigOption("language", langId)
  set_language(langId)
  saveLanguage(langId)
  saveProfile()
  resetAddonNamesCache()
}

function reload() {
  setGameLocalization(currentLanguage, true)
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

//




}

let g_language = {

  function onEventInitConfigs(_p) {
    isListInited = false
  }
}

saveLanguage(getLocalLanguage())

let getCurrentSteamLanguage = @() currentSteamLanguage
let getShortName = @() shortLangName

function getGameLocalizationInfo() {
  checkInitList()
  return langsList
}


// called from native playerProfile on language change, so at this point we can use get_language
eventbus_subscribe("on_language_changed", function on_language_changed(...) {
  saveLanguage(get_language())
})

ndbWrite("language.localizationInfo", getGameLocalizationInfo())
eventbus_send("localizationInfoUpdate", {})

registerRespondent("get_current_steam_language", getCurrentSteamLanguage)

subscribe_handler(g_language, g_listener_priority.DEFAULT_HANDLER)

local langIdForSet = ""
let setLanguageWithReload = @() setGameLocalization(langIdForSet)

eventbus_subscribe("language.setWithReloadScene", function(msg) {
  langIdForSet = msg.value
  resetTimeout(0.1, setLanguageWithReload)
})

register_command(@() reload(), "ui.language_reload")

return {
  getCurrentSteamLanguage
  getShortName
  setGameLocalization
  getGameLocalizationInfo
}
