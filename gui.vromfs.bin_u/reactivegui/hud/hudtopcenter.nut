from "%globalsDarg/darg_library.nut" import *
let { isInRoom } = require("%appGlobals/sessionLobbyState.nut")
let scoreBoard = require("%rGui/hud/scoreBoard.nut")
let hudDamageLog = require("%rGui/hud/hudDamageLog.nut")
let { mainHintsBlock } = require("%rGui/hudHints/hintBlocks.nut")
let { getHudConfigParameter } = require("%rGui/hud/hudConfigParameters.nut")
let { capZonesList } = require("capZones/capZonesList.ui.nut")
let captureZoneIndicators = require("%rGui/hud/capZones/captureZoneIndicators.nut")

return @() {
  watch = isInRoom
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    isInRoom.value ? scoreBoard : null
    capZonesList
    captureZoneIndicators
    getHudConfigParameter("showDamageLog") ? hudDamageLog : null
    mainHintsBlock
  ]
}
