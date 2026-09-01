#default:forbid-root-table

from "%scripts/dagui_library.nut" import dlog, mkWatched, log
from "dagor.random" import set_rnd_seed
from "dagor.system" import DBGLEVEL
from "dagor.time" import get_time_msec, ref_time_ticks
from "frp" import warn_on_deprecated_methods
from "dagui" import run_reactive_gui


let startLoadTime = get_time_msec()



warn_on_deprecated_methods(DBGLEVEL > 0)

require("%globalScripts/ui_globals.nut")
require("%globalScripts/debugTools/matchingErrorDebug.nut")

require("%globalScripts/version.nut")




set_rnd_seed(ref_time_ticks())



require("%scripts/loadRootScreen.nut")

require("%scripts/loading.nut")

require("%sqstd/regScriptProfiler.nut")("dagui", dlog) 


let isLoadedOnce = keepref(mkWatched(persist, "isLoadedOnce", false))
if (!isLoadedOnce.get()) {
  isLoadedOnce.set(true)
  run_reactive_gui()
}

log($"DaGui scripts load before login {get_time_msec() - startLoadTime} msec")
