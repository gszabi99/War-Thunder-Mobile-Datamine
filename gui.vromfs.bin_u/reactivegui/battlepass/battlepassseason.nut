from "%globalsDarg/darg_library.nut" import *
let { doubleSideGradient } = require("%rGui/components/gradientDefComps.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")

let battlePassSeason = @(text, seasonEndTime, children = null, ovr = {}) doubleSideGradient.__merge({
  padding = const [hdpx(20), hdpx(200), hdpx(17), hdpx(30) ]
  halign = ALIGN_LEFT
  flow = FLOW_VERTICAL
  gap = hdpx(10)
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
}.__update(ovr)
)
return battlePassSeason