from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/platform.nut" import is_ios
from "types" import String


let appStoreProdVersion = hardPersistWatched("appStoreVersion.appStoreProdVersion", "")

if (is_ios && appStoreProdVersion.get() == "") {
  appStoreProdVersion.subscribe(@(v) log($"appStoreProdVersion: {v}"))
  eventbus_subscribe("ios.platform.onGetAppStoreProdVersion",
    @(v) v.value instanceof String ? appStoreProdVersion.set(v.value)
      : logerr($"Wrong event ios.platform.onGetAppStoreProdVersion result type = {type(v.value)}: {v.value}"))
  require("ios.platform").getAppStoreProdVersion()
}

return { appStoreProdVersion }