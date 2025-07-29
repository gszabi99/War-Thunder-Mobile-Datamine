from "%globalsDarg/darg_library.nut" import *
let { doubleSideGradient } = require("%rGui/components/gradientDefComps.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { seasonName, seasonEndTime} = require("battlePassState.nut")

let battlePassSeason = doubleSideGradient.__merge({
  padding = const [hdpx(20), hdpx(200), hdpx(17), hdpx(30) ]
  halign = ALIGN_LEFT
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    @(){
      watch = seasonName
      rendObj = ROBJ_TEXT
      text = loc(seasonName.value)
    }.__update(fontMedium)
    @(){
      key = "battle_pass_time" 
      watch = [seasonEndTime, serverTime]
      rendObj = ROBJ_TEXT
      text = loc("battlepass/endsin", { time = secondsToHoursLoc(seasonEndTime.value - serverTime.get())})
    }.__update(fontVeryTiny)
  ]
}
)
return battlePassSeason