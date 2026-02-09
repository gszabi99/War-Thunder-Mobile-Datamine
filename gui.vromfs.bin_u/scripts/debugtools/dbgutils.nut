
from "%scripts/dagui_natives.nut" import get_cur_gui_scene, update_objects_under_windows_state, reload_main_script_module
from "%scripts/dagui_library.nut" import *
from "eventbus" import eventbus_subscribe
from "dagor.workcycle" import defer
let { setGameLocalization, getGameLocalizationInfo } = require("%scripts/language.nut")
let { register_command } = require("console")
let { getCurrentLanguage } = require("dagor.localize")

function reloadDagui() {
  get_cur_gui_scene()?.resetGamepadMouseTarget()
  reload_main_script_module()
  update_objects_under_windows_state(get_cur_gui_scene())
}

function debug_change_language(isNext = true) {
  let list = getGameLocalizationInfo()
  let curLang = getCurrentLanguage()
  let curIdx = list.findindex(@(l) l.id == curLang) ?? 0
  let newIdx = curIdx + (isNext ? 1 : -1 + list.len())
  let newLang = list[newIdx % list.len()]
  setGameLocalization(newLang.id)
  dlog("Set language:", newLang.id)
}

eventbus_subscribe("reloadDaguiVM", function(p) {
  log("Request reloadDaguiVM: ", p?.msg)
  defer(reloadDagui)
})

register_command(
  function() {
    reloadDagui()
    dlog("Dagui reloaded")
    return "Reload success"
  },
  "debug.reload_dagui")
register_command(@() debug_change_language(), "debug.change_language_to_next")
register_command(@() debug_change_language(false), "debug.change_language_to_prev")

