from "frp" import Watched, Computed
from "%sqstd/globalState.nut" import hardPersistWatched


let HUD_TYPE = {
  HT_HUD = "hud",
  HT_FREECAM = "freecam",
  HT_CUTSCENE = "cutscene",
  HT_BENCHMARK = "benchmark",
  HT_NONE = "none"
}

let curHudType = hardPersistWatched("curHudType", HUD_TYPE.HT_NONE)
let debugHudType = hardPersistWatched("debugHudType", null)
let viewHudType = Computed(@() debugHudType.get() ?? curHudType.get())

return HUD_TYPE.__merge({
  curHudType
  debugHudType
  viewHudType
  isHudAttached = Watched(false)
})
