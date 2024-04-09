from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_cur_circuit_name, get_game_version_str } = require("app")
let { platformId } = require("%sqstd/platform.nut")

local bugReportUrl = "{url}?f.platform={platform}&f.version={version}&f.circuit={circuit}".subst({
  url = loc("url/bugreport", "auto_local auto_login https://community.gaijin.net/issues/p/wtm/new_issue")
  platform = platformId
  version = get_game_version_str()
  circuit = get_cur_circuit_name()
})

return {
  openBugReport = @() eventbus_send("openUrl", { baseUrl = bugReportUrl })
}