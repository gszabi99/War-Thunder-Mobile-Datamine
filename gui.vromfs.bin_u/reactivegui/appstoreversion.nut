from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { is_ios } = require("%sqstd/platform.nut")


let appStoreProdVersion = hardPersistWatched("appStoreVersion.appStoreProdVersion", "")

if (is_ios && appStoreProdVersion.get() == "") {
  appStoreProdVersion.subscribe(@(v) log($"appStoreProdVersion: {v}"))
  eventbus_subscribe("ios.platform.onGetAppStoreProdVersion",
    @(v) type(v.value) == "string" ? appStoreProdVersion.set(v.value)
      : logerr($"Wrong event ios.platform.onGetAppStoreProdVersion result type = {type(v.value)}: {v.value}"))
  require("ios.platform").getAppStoreProdVersion()
}

return { appStoreProdVersion }