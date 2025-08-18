from "%globalsDarg/darg_library.nut" import *
let { mkZoomSlider, zoomSliderEditView } = require("%rGui/hud/zoomSlider.nut")
let { Z_ORDER, mkRBPos, mkCTPos, mkLTPos } = require("%rGui/hudTuning/cfg/hudTuningPkg.nut")
let { scoreBoardEditView, needScoreBoard, scoreBoardCfgByType, scoreBoardType } = require("%rGui/hud/scoreBoard.nut")
let { capZonesEditView, capZonesList } = require("%rGui/hud/capZones/capZones.nut")
let { chatLogAndKillLogPlace, chatLogAndKillLogEditView } = require("%rGui/hudHints/hintBlocks.nut")
let { mkMenuButton, mkMenuButtonEditView } = require("%rGui/hud/menuButton.nut")
let { optFontSize, optTextWidth } = require("%rGui/hudTuning/cfg/cfgOptions.nut")

return {
  zoomSlider = {
    ctor = mkZoomSlider
    defTransform = mkRBPos([hdpx(-640), hdpx(-130)])
    editView = zoomSliderEditView
    priority = Z_ORDER.SLIDER
  }

  scores = {
    ctor = @(scale) @() {
      watch = scoreBoardType
      children = scoreBoardCfgByType?[scoreBoardType.get()].ctor(scale)
    }
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

  menuBtn = {
    ctor = @(scale) mkMenuButton(scale)
    defTransform = mkLTPos([0, 0])
    priority = Z_ORDER.SUPERIOR
    editView = mkMenuButtonEditView
    hideForDelayed = false
  }
}