from "%globalsDarg/darg_library.nut" import *
let { moveIndicator, moveIndicatorShipEditView } = require("%rGui/hud/components/moveIndicator.nut")
let { doll, dollEditView, shipDebuffs, shipDebuffsEditView, crewHealth, crewHealthEditView
} = require("%rGui/hud/shipStateModule.nut")
let { tacticalMap, tacticalMapEditView } = require("%rGui/hud/components/tacticalMap.nut")
let { mkLBPos, mkLTPos, mkRTPos, mkCBPos } = require("hudTuningPkg.nut")
let { hitCamera, hitCameraCommonEditView } = require("%rGui/hud/hitCamera/hitCamera.nut")
let { DBGLEVEL } = require("dagor.system")

return {
  hitCamera = {
    ctor = @() hitCamera
    defTransform = mkRTPos([0, 0])
    editView = hitCameraCommonEditView
    hideForDelayed = false
  }

  tacticalMap = {
    ctor = @() tacticalMap
    defTransform = mkLTPos([hdpx(105), 0])
    editView = tacticalMapEditView
    hideForDelayed = false
  }

  moveIndicator = DBGLEVEL > 0
    ? {
      ctor = @() moveIndicator
      defTransform = mkCBPos([0, -sh(13)])
      editView = moveIndicatorShipEditView
      hideForDelayed = false
    }
  : null

  doll = {
    ctor = @() doll
    defTransform = mkLBPos([hdpx(540), hdpx(-38)])
    editView = dollEditView
    hideForDelayed = false
  }

  debuffs = {
    ctor = @() shipDebuffs
    defTransform = mkLBPos([hdpx(616), 0])
    editView = shipDebuffsEditView
    hideForDelayed = false
  }

  crewHealth = {
    ctor = @() crewHealth
    defTransform = mkLBPos([hdpx(670), hdpx(-115)])
    editView = crewHealthEditView
    hideForDelayed = false
  }
}.filter(@(v) v != null)