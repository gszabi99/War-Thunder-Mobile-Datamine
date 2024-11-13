from "%globalsDarg/darg_library.nut" import *
let { mkZoomSlider, zoomSliderEditView } = require("%rGui/hud/zoomSlider.nut")
let { Z_ORDER, mkRBPos, mkCTPos, mkLTPos } = require("hudTuningPkg.nut")
let { scoreBoardEditView, mkScoreBoard, needScoreBoard } = require("%rGui/hud/scoreBoard.nut")
let { capZonesEditView, capZonesList } = require("%rGui/hud/capZones/capZones.nut")
let { chatLogAndKillLogPlace, chatLogAndKillLogEditView } = require("%rGui/hudHints/hintBlocks.nut")
let { optFontSize, optTextWidth } = require("cfgOptions.nut")

return {
  zoomSlider = {
    ctor = mkZoomSlider
    defTransform = mkRBPos([hdpx(-640), hdpx(-130)])
    editView = zoomSliderEditView
    priority = Z_ORDER.SLIDER
  }

  scores = {
    ctor = mkScoreBoard
    defTransform = mkCTPos([0, -hdpx(16)])
    editView = scoreBoardEditView
    hideForDelayed = false
    isVisibleInBattle = needScoreBoard
  }

  zoneIndicators = {
    ctor = capZonesList
    defTransform = mkCTPos([0, hdpx(42)])
    editView = capZonesEditView
    hideForDelayed = false
  }

  chatLogAndKillLog = {
    ctor = chatLogAndKillLogPlace
    defTransform = mkLTPos([0, hdpx(360)])
    editView = chatLogAndKillLogEditView
    options = [ optFontSize, optTextWidth ]
  }
}