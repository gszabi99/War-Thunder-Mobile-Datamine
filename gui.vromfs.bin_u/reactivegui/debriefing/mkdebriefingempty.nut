from "%globalsDarg/darg_library.nut" import *
from "%rGui/debriefing/missionResultTitle.nut" import mkMissionResultTitle


let mkDebriefingEmpty = @(debrData) debrData == null ? null : {
  size = FLEX
  halign = ALIGN_CENTER
  children = mkMissionResultTitle(debrData, true)
}

return mkDebriefingEmpty
