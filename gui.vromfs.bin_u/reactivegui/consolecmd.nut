from "%globalsDarg/darg_library.nut" import *
import "DataBlock" as DataBlock
from "blkGetters" import get_local_custom_settings_blk
from "console" import register_command
from "eventbus" import eventbus_send
from "math" import round
from "sound_wt" import startSound, playSound, stopSound
from "string" import format
from "%sqstd/string.nut" import hexStringToInt
from "%darg/helpers/inspector.nut" import inspectorToggle
from "%appGlobals/currenciesState.nut" import balance
from "%appGlobals/dirtyWordsFilter.nut" import debugDirtyWordsFilter
from "%appGlobals/pServer/profileSeasons.nut" import curSeasons
from "%appGlobals/permissions.nut" import allPermissions, dbgPermissions
from "%appGlobals/updater/addons.nut" import localizeAddons
from "types" import String, Float, Integer





register_command(@() inspectorToggle(), "ui.inspector")

register_command(function(colorStr, multiplier) {
  if (!(colorStr instanceof String) || (colorStr.len() != 8 && colorStr.len() != 6))
    return log("first param must be string with len 6 or 8")
  if ((!(multiplier instanceof Float) && !(multiplier instanceof Integer)) || multiplier < 0)
    return log("second param must be numeric > 0")

  let colorInt = hexStringToInt(colorStr)
  let a = round(min(255, multiplier * (colorStr.len() == 8 ? ((colorInt & 0xFF000000) >> 24) : 255))).tointeger()
  let r = round(min(255, multiplier * ((colorInt & 0xFF0000) >> 16))).tointeger()
  let g = round(min(255, multiplier * ((colorInt & 0xFF00) >> 8))).tointeger()
  let b = round(min(255, multiplier * (colorInt & 0xFF))).tointeger()
  let resColor = (a << 24) + (r << 16) + (g << 8) + b
  log(format("color = 0x%X, Color(%d, %d, %d, %d)", resColor, r, g, b, a))
}, "debug.multiply_color")

allPermissions.get().each(@(_, id) register_command(function() {
  dbgPermissions.mutate(@(v) v[id] <- !v?[id])
  log($"{id} = {allPermissions.get()?[id]}")
}, $"toggle_permission.{id}"))

register_command(@(name) log(localizeAddons([name])), "debug.addonLoc")

register_command(@(name) playSound(name), "debug.guiSound.play")
register_command(@(name) startSound(name), "debug.guiSound.start")
register_command(@(name) stopSound(name), "debug.guiSound.stop")

register_command(@(text) debugDirtyWordsFilter(text, false, console_print), "debug.dirty_words_filter.phrase")
register_command(@(text) debugDirtyWordsFilter(text, true,  console_print), "debug.dirty_words_filter.name")

let printSorted = @(tbl) console_print(
  "\n".join(
    tbl.map(@(v, k) { v, k })
      .values()
      .sort(@(a, b) a.k <=> b.k)
      .map(@(v) $"{v.k} = {v.v}")))

register_command(@() printSorted(balance.get()), "debug.balance_full")
register_command(@() printSorted(balance.get().filter(@(v) v != 0)), "debug.balance_not_empty")
register_command(@() printSorted(curSeasons.get().map(@(s) s.idx)), "debug.current_seasons_with_inactive")
register_command(@() printSorted(curSeasons.get().filter(@(s) s.isActive).map(@(s) s.idx)), "debug.current_seasons")

register_command(function() {
    const fileName = "localCustomSettings.blk"
    let blk = get_local_custom_settings_blk()
    blk.saveToTextFile(fileName)
    console_print($"Saved to: {fileName}")
  },
  "debug.save_local_custom_settings_blk_to_file")

register_command(function(fileName) {
    let sBlk = get_local_custom_settings_blk()
    let blk = DataBlock()
    if (!blk.tryLoad(fileName)) {
      console_print($"Failed to load from '{fileName}'")
      return
    }
    sBlk.setFrom(blk)
    console_print($"Success")
    eventbus_send("saveProfile", {})
    eventbus_send("reloadDargVM", { msg = "loaded new custom settings" })
  },
  "debug.load_local_custom_settings_blk_from_file")
