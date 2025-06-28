
from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "eventbus" import eventbus_send
from "sysinfo" import get_user_system_info
from "%sqstd/platform.nut" import is_pc
from "%appGlobals/safeArea.nut" import isDebugEmuIPhoneDynamicIsland

let debugEmuIPhoneDynamicIslandModels = [
  { scr = [2556, 1179], desc = "14 Pro, 15, 15 Pro, 16" }
  { scr = [2796, 1290], desc = "14 Pro Max, 15 Plus, 15 Pro Max, 16 Plus" }
  { scr = [2622, 1206], desc = "16 Pro" }
  { scr = [2868, 1320], desc = "16 Pro Max" }
]

function debugSafeAreaEmulateIPhoneDynamicIsland() {
  if (!is_pc)
    return console_print("Not supported by platform")
  let isEnable = !isDebugEmuIPhoneDynamicIsland.get()
  if (isEnable) {
    let wndRes = get_user_system_info().gameResolution.split(" x ").map(@(v) v.tointeger())
    local isResolutionValid = false
    foreach (m in debugEmuIPhoneDynamicIslandModels)
      if (wndRes[0] == m.scr[0] && wndRes[1] == m.scr[1])
        isResolutionValid = true
    if (!isResolutionValid) {
      console_print($"Rejected. Change resolution {wndRes[0]}x{wndRes[1]} to any of those and try again:")
      foreach (m in debugEmuIPhoneDynamicIslandModels)
        console_print($"    {m.scr[0]}x{m.scr[1]} // {m.desc}")
      return
    }
  }
  isDebugEmuIPhoneDynamicIsland.set(isEnable)
  console_print($"isDebugEmuIPhoneDynamicIsland {isEnable}")
  eventbus_send("reloadDargVM", { msg = "safearea changed" })
  eventbus_send("reloadDaguiVM", { msg = "safearea changed" })
}

register_command(debugSafeAreaEmulateIPhoneDynamicIsland, "debug.safeArea.emulateIPhoneDynamicIsland")
