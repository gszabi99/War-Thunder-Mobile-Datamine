from "%globalsDarg/darg_library.nut" import *
let { mkMissionResultTitle } = require("%rGui/debriefing/missionResultTitle.nut")

let mkDebriefingEmpty = @(debrData) debrData == null ? null : {
  size = FLEX
  halign = ALIGN_CENTER
  children = mkMissionResultTitle(debrData, true)
}

return mkDebriefingEmpty
