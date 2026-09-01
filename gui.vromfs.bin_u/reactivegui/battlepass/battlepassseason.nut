from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/timeToText.nut" import secondsToHoursLoc
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/gradientDefComps.nut" import doubleSideGradient


let battlePassSeason = @(text, seasonEndTime, children = null, ovr = {}) doubleSideGradient.__merge({
  padding = const [hdpx(20), hdpx(200), hdpx(17), hdpx(30) ]
  halign = ALIGN_LEFT
  flow = FLOW_VERTICAL
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc(text)
      halign = ALIGN_RIGHT
      valign = ALIGN_BOTTOM
      children = {
        pos = const [hdpx(70), 0]
        children
      }
    }.__update(fontMedium)
    @() {
      watch = serverTime
      key = "battle_pass_time" 
      rendObj = ROBJ_TEXT
      text = loc("battlepass/endsin", { time = secondsToHoursLoc(seasonEndTime - serverTime.get())})
    }.__update(fontVeryTiny)
  ]
}.__update(ovr))

return battlePassSeason