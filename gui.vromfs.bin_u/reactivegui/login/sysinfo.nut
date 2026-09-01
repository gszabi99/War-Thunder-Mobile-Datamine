from "%globalsDarg/darg_library.nut" import *
from "android.platform" import isDownloadedFromGooglePlay, getBuildMarket
from "app" import get_game_version_str, get_base_game_version_str
from "appsFlyer" import getAppsFlyerUID
from "auth_wt" import getCountryCode
from "language" import getLocalLanguage
from "sysinfo" import get_user_system_info, get_battery, is_charging, get_thermal_state
from "%sqstd/platform.nut" import is_android, is_ios
from "%appGlobals/profileStates.nut" import myUserName
from "authState.nut" import authState
from "types" import Table, String


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
    if (tbl.cpuFeatures instanceof Table) {
      let values = tbl.cpuFeatures.filter(@(v) v)
        .keys()
        .sort(@(a, b) a <=> b)
      tbl.cpuFeatures = $";{";".join(values)};"
    }
    else if (!(tbl.cpuFeatures instanceof String))
      tbl.$rawdelete("cpuFeatures")

  return tbl
}

return {
  getSysInfo = getSysInfo
}
