from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "matching.errors" import SERVER_ERROR_FORCE_DISCONNECT
from "%globalScripts/yuplay2Consts.nut" import YU2_WRONG_LOGIN
from "%appGlobals/errorMsgBox.nut" import errorMsgBox, lastSessionDebugInfo
from "%sqstd/string.nut" import utf8ToLower
from "dagor.localize" import getCurrentLanguage
from "%rGui/language.nut" import setGameLocalization, getGameLocalizationInfo





function debug_change_language(isNext = true) {
  let list = getGameLocalizationInfo()
  let curLang = getCurrentLanguage()
  let curIdx = list.findindex(@(l) l.id == curLang) ?? 0
  let newIdx = curIdx + (isNext ? 1 : -1 + list.len())
  let newLang = list[newIdx % list.len()]
  setGameLocalization(newLang.id)
  dlog("Set language:", newLang.id)
}


register_command(@() debug_change_language(), "debug.change_language_to_next")
register_command(@() debug_change_language(false), "debug.change_language_to_prev")

getGameLocalizationInfo().each(function(lang) {
  register_command(@() setGameLocalization(lang.id), $"debug.language.set.{utf8ToLower(lang.id)}")
})

register_command(
  function() {
    lastSessionDebugInfo.set("sid:12345678")
    errorMsgBox(SERVER_ERROR_FORCE_DISCONNECT,
      [{ id = "exit", eventId = "matchingExitGame", styleId = "PRIMARY", isDefault = true }],
      { isPersist = true })
  },
  "debug.matchingError")
register_command(
  @() errorMsgBox(YU2_WRONG_LOGIN,
    [
      { id = "recovery", eventId = "loginRecovery", hotkeys = ["^J:X"] }
      { id = "exit", eventId = "loginExitGame", hotkeys = ["^J:Y"] }
      { id = "tryAgain", styleId = "PRIMARY", isDefault = true }
    ]),
  "debug.loginError")

