//-file:plus-string

//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let fonts = require("fonts")
let { split_by_chars } = require("string")
let { send, subscribe } = require("eventbus")
let { getLocalLanguage } = require("language")
let { register_command } = require("console")
let { resetTimeout } = require("dagor.workcycle")
let { ndbWrite } = require("nestdb")
let { saveProfile } = require("%scripts/clientState/saveProfile.nut")
let DataBlock  = require("DataBlock")

let allLangs = [
  { id = "English", icon = "#ui/gameuiskin#lang_usa.svg", chatId = "en", hasUnitSpeech = true }
  { id = "Russian", icon = "#ui/gameuiskin#lang_russia.svg", chatId = "ru", hasUnitSpeech = true }
  { id = "French", icon = "#ui/gameuiskin#lang_france.svg", chatId = "fr", hasUnitSpeech = true }
  { id = "Italian", icon = "#ui/gameuiskin#lang_italy.svg", chatId = "it" }
  { id = "German", icon = "#ui/gameuiskin#lang_germany.svg", chatId = "de", hasUnitSpeech = true }
  { id = "Spanish", icon = "#ui/gameuiskin#lang_spain.svg", chatId = "es" }
  { id = "Portuguese", icon = "#ui/gameuiskin#lang_portugal.svg", chatId = "pt" }
  { id = "Polish", icon = "#ui/gameuiskin#lang_poland.svg", chatId = "pl" }
  { id = "Turkish", icon = "#ui/gameuiskin#lang_turkey.svg", chatId = "tr" }
  { id = "Chinese", icon = "#ui/gameuiskin#lang_china.svg", chatId = "zh" }
  { id = "TChinese", icon = "#ui/gameuiskin#lang_taiwan.svg", chatId = "zh" }
  { id = "Korean", icon = "#ui/gameuiskin#lang_korea.svg", chatId = "ko" }
  { id = "Japanese", icon = "#ui/gameuiskin#lang_japan.svg", chatId = "jp", hasUnitSpeech = true }
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

::g_language <- {
  currentLanguage = null
  currentSteamLanguage = ""
  shortLangName = ""

  langsList = []
  langsById = {}
  isListInited = false

  steamLanguages = {
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
    Ukrainian = "ukrainian"
    Hungarian = "hungarian"
    Korean = "koreana"
    TChinese = "tchinese"
    HChinese = "schinese"
  }
}

::g_language.getLanguageName <- function getLanguageName() {
  return this.currentLanguage
}

::g_language.getShortName <- function getShortName() {
  return this.shortLangName
}

::g_language.getCurLangInfo <- function getCurLangInfo() {
  return this.getLangInfoById(this.currentLanguage)
}

::g_language.onChangeLanguage <- function onChangeLanguage() {
  ::g_language.currentSteamLanguage = this.steamLanguages?[this.currentLanguage] ?? "english";
}

::g_language.saveLanguage <- function saveLanguage(langName) {
  if (this.currentLanguage == langName)
    return
  this.currentLanguage = langName
  this.shortLangName = loc("current_lang")
  ::g_language.onChangeLanguage()
}

::g_language.saveLanguage(getLocalLanguage())
let currentLanguageW = Watched(::g_language.currentLanguage)

::g_language.setGameLocalization <- function setGameLocalization(langId, _reloadScene = false, _suggestPkgDownload = false, isForced = false) {
  if (langId == this.currentLanguage && !isForced)
    return

  fonts.discardLoadedData()
  ::setSystemConfigOption("language", langId)
  ::set_language(langId)
  ::g_language.saveLanguage(langId)
  currentLanguageW(this.currentLanguage)
  saveProfile()
}

::g_language.reload <- function reload() {
  this.setGameLocalization(this.currentLanguage, true, false, true)
}

::g_language.checkInitList <- function checkInitList() {
  if (this.isListInited)
    return
  this.isListInited = true

  let locBlk = DataBlock()
  ::get_localization_blk_copy(locBlk)
  let ttBlk = locBlk?.text_translation ?? DataBlock()
  let existingLangs = ttBlk % "lang"

  this.langsList = allLangs.filter(@(l) existingLangs.contains(l.id))
  this.langsById = {}
  foreach (lang in this.langsList)
    this.langsById[lang.id] <- lang
}

::g_language.getGameLocalizationInfo <- function getGameLocalizationInfo() {
  this.checkInitList()
  return this.langsList
}

::g_language.getLangInfoById <- function getLangInfoById(id) {
  this.checkInitList()
  return this.langsById?[id]
}

/*
  return localized text from @config (table or datablock) by id
  if text value require to be localized need to start it with #

  defaultValue returned when not fount id in config.
  if defaultValue == null  - it will return id instead

  example config:
  {
    text = "..."   //default text. returned when not found lang specific.
    text_ru = "#locId"  //russian text, taken from localization  loc("locId")
    text_en = "localized text"  //english text. already localized.
  }
*/
::g_language.getLocTextFromConfig <- function getLocTextFromConfig(config, id = "text", defaultValue = null) {
  local res = null
  let key = "_".concat(id, this.shortLangName)
  if (key in config)
    res = config[key]
  else
    res = config?[id] ?? res

  if (type(res) != "string")
    return defaultValue || id

  if (res.len() > 1 && res.slice(0, 1) == "#")
    return loc(res.slice(1))
  return res
}

::g_language.isAvailableForCurLang <- function isAvailableForCurLang(block) {
  if (!block?["showForLangs"])
    return true

  let availableForLangs = split_by_chars(block.showForLangs, ";")
  return availableForLangs.contains(this.getLanguageName())
}

::g_language.onEventInitConfigs <- function onEventInitConfigs(_p) {
  this.isListInited = false
}

::get_current_language <- function get_current_language() {
  return ::g_language.getLanguageName()
}

// called from native playerProfile on language change, so at this point we can use get_language
::on_language_changed <- function on_language_changed() {
  ::g_language.saveLanguage(::get_language())
}

::g_language.getCurrentSteamLanguage <- function getCurrentSteamLanguage() {
  return this.currentSteamLanguage
}

ndbWrite("language.localizationInfo", ::g_language.getGameLocalizationInfo())
send("localizationInfoUpdate", {})

// used in native code
::get_current_steam_language <- function get_current_steam_language() {
  return ::g_language.getCurrentSteamLanguage()
}

::subscribe_handler(::g_language, ::g_listener_priority.DEFAULT_HANDLER)

local langIdForSet = ""
let setLanguageWithReload = @() ::g_language.setGameLocalization(langIdForSet, true)

subscribe("language.setWithReloadScene", function(msg) {
  langIdForSet = msg.value
  resetTimeout(0.1, setLanguageWithReload)
})

register_command(@() ::g_language.reload(), "ui.language_reload")

return {
  currentLanguageW
}
