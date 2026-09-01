from "%globalsDarg/darg_library.nut" import *
from "string" import strip, startswith
from "types" import String


let parseDargHotkeysImpl = @(hotkey) hotkey.replace("^", "")
  .split("|")
  .map(@(v) strip(v))
  .filter(@(v) startswith(v, "J:"))

let parsed = {}
function parseDargHotkeys(hotkey) {
  if (hotkey not in parsed)
    parsed[hotkey] <- parseDargHotkeysImpl(hotkey)
  return parsed[hotkey]
}

function getGamepadHotkey(hotkeys) {
  if ((hotkeys?.len() ?? 0) == 0)
    return null

  foreach (hCfg in hotkeys) {
    let h = hCfg instanceof String ? hCfg : hCfg[0]
    if (!(h instanceof String))
      continue
    let list = parseDargHotkeys(h)
    if (list.len() > 0)
      return list[0]
  }
  return null
}

return {
  parseDargHotkeys
  getGamepadHotkey
}