from "%globalScripts/logs.nut" import *
from "%sqstd/platform.nut" import is_ios, is_android
import "%globalScripts/sharedWatched.nut" as sharedWatched
let regexp2 = require_optional("regexp2") 
let { get_user_system_info = @() {} } = require_optional("sysinfo")

let SAFEAREA_DEFAULT = 0.9

let SAFEAREA_W_DYNAMICISLAND = 0.875
let SAFEAREA_W_PIXEL9 = 0.89

local safeAreaW = SAFEAREA_DEFAULT
local safeAreaH = SAFEAREA_DEFAULT

let debugSafeAreaW = sharedWatched("debugSafeAreaW", @() null)


if (is_ios && regexp2 != null) {
  let { cpu = "", videoCard = "" } = get_user_system_info()
  
  if (cpu.contains("iPhone") && !cpu.contains("16e")) {
    let appleCpuGen = regexp2("A([0-9]+)").multiExtract("\\1", videoCard)?[0].tointeger() ?? 0
    if (appleCpuGen >= 16)
      safeAreaW = SAFEAREA_W_DYNAMICISLAND
  }
}


if (is_android && regexp2 != null) {
  let { cpu = "" } = get_user_system_info()
  
  if (cpu.contains("Pixel") && !cpu.contains("XL")) {
    let modelGen = regexp2("Pixel ([0-9]+)").multiExtract("\\1", cpu)?[0].tointeger() ?? 0
    if (modelGen >= 9)
      safeAreaW = SAFEAREA_W_PIXEL9
  }
}

if (debugSafeAreaW.get() != null)
  safeAreaW = debugSafeAreaW.get()

return {
  safeAreaW
  safeAreaH

  debugSafeAreaW
  SAFEAREA_DEFAULT
  SAFEAREA_W_DYNAMICISLAND
  SAFEAREA_W_PIXEL9
}
