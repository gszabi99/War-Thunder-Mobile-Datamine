from "%globalsDarg/darg_library.nut" import *
let { gameType } = require("%rGui/missionState.nut")
let scoreBoard = require("%rGui/hud/scoreBoard.nut")
let hudDamageLog = require("%rGui/hud/hudDamageLog.nut")
let { mainHintsBlock } = require("%rGui/hudHints/hintBlocks.nut")
let { getHudConfigParameter } = require("%rGui/hud/hudConfigParameters.nut")
let { capZonesList } = require("capZones/capZonesList.ui.nut")
let captureZoneIndicators = require("%rGui/hud/capZones/captureZoneIndicators.nut")

let needScores = Computed(@() (gameType.value & (GT_MP_SCORE | GT_MP_TICKETS)) != 0)

return @() {
  watch = needScores
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    needScores.value ? scoreBoard : null
    capZonesList
    captureZoneIndicators
    getHudConfigParameter("showDamageLog") ? hudDamageLog : null
    mainHintsBlock
  ]
}
