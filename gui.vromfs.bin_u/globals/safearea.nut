from "%globalScripts/logs.nut" import *
from "%sqstd/platform.nut" import is_ios, is_android
import "%globalScripts/sharedWatched.nut" as sharedWatched
let regexp2 = require_optional("regexp2") 
let { get_user_system_info = @() {} } = require_optional("sysinfo")

let SAFEAREA_DEFAULT = 0.9

local safeAreaW = SAFEAREA_DEFAULT
local safeAreaH = SAFEAREA_DEFAULT

let isDebugEmuIPhoneDynamicIsland = sharedWatched("isDebugEmuIPhoneDynamicIsland", @() false)
let isDebugEmuGooglePixel9 = sharedWatched("isDebugEmuGooglePixel9", @() false)


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


if ((is_android || isDebugEmuGooglePixel9.get()) && regexp2 != null) {
  let { cpu = "" } = isDebugEmuGooglePixel9.get()
    ? { cpu = "Google Pixel 9 Pro " } 
    : get_user_system_info()
  if (cpu.contains("Pixel") && !cpu.contains("XL")) {
    let modelGen = regexp2("Pixel ([0-9]+)").multiExtract("\\1", cpu)?[0].tointeger() ?? 0
    if (modelGen >= 9)
      safeAreaW = 0.89
  }
}

return {
  safeAreaW
  safeAreaH

  isDebugEmuIPhoneDynamicIsland
  isDebugEmuGooglePixel9
}
