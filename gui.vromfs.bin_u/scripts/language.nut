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
  { id = "English", icon = "#ui/gameuiskin#lang_usa.svg", chatId = "en", hasUnitSpeech = true }
  { id = "Russian", icon = "#ui/gameuiskin#lang_russia.svg", chatId = "ru", hasUnitSpeech = true }
  { id = "French", icon = "#ui/gameuiskin#lang_france.svg", chatId = "fr", hasUnitSpeech = true }
  { id = "Italian", icon = "#ui/gameuiskin#lang_italy.svg", chatId = "it" }
  { id = "German", icon = "#ui/gameuiskin#lang_germany.svg", chatId = "de", hasUnitSpeech = true }
  { id = "Spanish", icon = "#ui/gameuiskin#lang_spain.svg", chatId = "es" }
  { id = "Portuguese", icon = "#ui/gameuiskin#lang_portugal.svg", chatId = "pt" }
  { id = "Greek", icon = "#ui/gameuiskin#lang_greece.svg", chatId = "el" }
  { id = "Polish", icon = "#ui/gameuiskin#lang_poland.svg", chatId = "pl" }
  { id = "Ukrainian", icon = "#ui/gameuiskin#lang_ukraine.svg", chatId = "uk" }
  { id = "Turkish", icon = "#ui/gameuiskin#lang_turkey.svg", chatId = "tr" }
  { id = "Indonesian", icon = "#ui/gameuiskin#lang_indonesia.svg", chatId = "id" }
  { id = "Chinese", icon = "#ui/gameuiskin#lang_china.svg", chatId = "zh", hasUnitSpeech = true  }
  { id = "TChinese", icon = "#ui/gameuiskin#lang_taiwan.svg", chatId = "zh" }
  { id = "Korean", icon = "#ui/gameuiskin#lang_korea.svg", chatId = "ko" }
  { id = "Japanese", icon = "#ui/gameuiskin#lang_japan.svg", chatId = "jp", hasUnitSpeech = true }
  { id = "Thai", icon = "#ui/gameuiskin#lang_thailand.svg", chatId = "th" }
]
  .map(function(lang) {
    let { id } = lang
    return {
      title = loc($"language/{id}")
      icon = ""
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
