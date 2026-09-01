from "%globalsDarg/darg_library.nut" import *
from "app" import get_cur_circuit_name, get_game_version_str
from "eventbus" import eventbus_send
from "%sqstd/platform.nut" import platformId
from "%appGlobals/curCircuitOverride.nut" import getCurCircuitOverride


local bugReportUrl = "{url}?f.platform={platform}&f.version={version}&f.circuit={circuit}".subst({
  url = getCurCircuitOverride("bugReportURL",loc("url/bugreport", "auto_local auto_login https://community.gaijin.net/issues/p/wtm/new_issue"))
  platform = platformId
  version = get_game_version_str()
  circuit = get_cur_circuit_name()
})

return {
  openBugReport = @() eventbus_send("openUrl", { baseUrl = bugReportUrl })
}