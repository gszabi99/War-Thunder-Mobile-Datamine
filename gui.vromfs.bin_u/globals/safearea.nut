from "%globalScripts/logs.nut" import *
from "sysinfo" import get_user_system_info
from "%sqstd/platform.nut" import is_ios
import "%globalScripts/sharedWatched.nut" as sharedWatched
let { regexp2 = null } = require_optional("regexp2") 

let SAFEAREA_DEFAULT = 0.9

local safeAreaW = SAFEAREA_DEFAULT
local safeAreaH = SAFEAREA_DEFAULT

let isDebugEmuIPhoneDynamicIsland = sharedWatched("isDebugEmuIPhoneDynamicIsland", @() false)


if ((is_ios || isDebugEmuIPhoneDynamicIsland.get()) && regexp2 != null) {
  let { cpu = "", videoCard = "" } = isDebugEmuIPhoneDynamicIsland.get()
    ? { cpu = "iPhone 16 Pro", videoCard = "Apple A18 Pro GPU" }
    : get_user_system_info()
  if (cpu.contains("iPhone") && !cpu.contains("16e")) {
    let appleCpuGen = regexp2("A([0-9]+)").multiExtract("\\1", videoCard)?[0].tointeger() ?? 0
    if (appleCpuGen >= 16)
      safeAreaW = 0.875
  }
}

return {
  safeAreaW
  safeAreaH

  isDebugEmuIPhoneDynamicIsland
}
