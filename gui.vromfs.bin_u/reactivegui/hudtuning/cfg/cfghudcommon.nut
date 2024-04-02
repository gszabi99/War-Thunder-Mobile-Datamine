from "%globalsDarg/darg_library.nut" import *
let { zoomSlider, zoomSliderEditView } = require("%rGui/hud/zoomSlider.nut")
let { Z_ORDER, mkRBPos, mkCTPos } = require("hudTuningPkg.nut")
let { mkScores, mkZoneIndicators } = require("%rGui/hud/hudTopCenter.nut")
let { scoreBoardEditView } = require("%rGui/hud/scoreBoard.nut")
let { capZonesEditView } = require("%rGui/hud/capZones/capZonesList.ui.nut")

return {
  zoomSlider = {
    ctor = @() zoomSlider
    defTransform = mkRBPos([hdpx(-640), hdpx(-130)])
    editView = zoomSliderEditView
    priority = Z_ORDER.SLIDER
  }

  scores = {
    ctor = @() mkScores
    defTransform = mkCTPos([0, -hdpx(16)])
    editView = scoreBoardEditView
    hideForDelayed = false
  }

  zoneIndicators = {
    ctor = mkZoneIndicators
    defTransform = mkCTPos([0, hdpx(42)])
    editView = capZonesEditView
    hideForDelayed = false
  }
}