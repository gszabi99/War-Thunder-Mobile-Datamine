from "%scripts/dagui_library.nut" import *
let { get_user_system_info, get_battery, is_charging, get_thermal_state } = require("sysinfo")
let { get_game_version_str, get_base_game_version_str } = require("app")
let { getCountryCode } = require("auth_wt")
let { getLocalLanguage } = require("language")
let { getAppsFlyerUID } = require("appsFlyer")
let { isDownloadedFromGooglePlay, getBuildMarket } = require("android.platform")
let { is_android, is_ios } = require("%sqstd/platform.nut")
let { myUserName } = require("%appGlobals/profileStates.nut")
let { authState } = require("authState.nut")
let { getFirebaseAppInstanceId = @() null}  = is_android ? require_optional ("android.firebase.analytics")
                                            : is_ios ? require_optional ("ios.firebase.analytics")
                                            : {}

let isHuaweiBuild = getBuildMarket() == "appgallery"

function getSysInfo() {
  let tbl = get_user_system_info()
  tbl.userName <- myUserName.get()
  tbl.appsflyer_id <- getAppsFlyerUID()
  tbl.gameVersion <- get_game_version_str()
  tbl.apkVersion <- get_base_game_version_str()
  tbl.battery <- get_battery()
  tbl.isCharging <- is_charging()
  tbl.thermalState <- get_thermal_state()
  tbl.authorization <- authState.get().loginType
  tbl.location <- getCountryCode() 
  tbl.gameLanguage <- getLocalLanguage() 
  if (getFirebaseAppInstanceId()!=null)
    tbl.appInstanceId <- getFirebaseAppInstanceId()
  tbl.installStore <- is_android && isHuaweiBuild ? "huawei"
    : is_android && isDownloadedFromGooglePlay() ? "google"
    : is_ios ? "iOS"
    : "other"

  if ("cpuFeatures" in tbl)
    if (type(tbl.cpuFeatures) == "table") {
      let values = tbl.cpuFeatures.filter(@(v) v)
        .keys()
        .sort(@(a, b) a <=> b)
      tbl.cpuFeatures = $";{";".join(values)};"
    }
    else if (type(tbl.cpuFeatures) != "string")
      tbl.$rawdelete("cpuFeatures")

  return tbl
}

return {
  getSysInfo = getSysInfo
}
