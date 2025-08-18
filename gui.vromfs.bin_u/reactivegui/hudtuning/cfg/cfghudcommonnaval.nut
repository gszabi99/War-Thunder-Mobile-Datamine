from "%globalsDarg/darg_library.nut" import *
let { NEED_SHOW_POSE_INDICATOR, mkMoveIndicator, moveIndicatorShipEditView
} = require("%rGui/hud/components/moveIndicator.nut")
let { mkDollCtor, mkDollEditView, mkShipDebuffs, shipDebuffsEditView, mkCrewHealthCtor, mkCrewHealthEditView,
  defHealthSize
} = require("%rGui/hud/shipStateModule.nut")
let { mkTacticalMapForHud, tacticalMapEditView } = require("%rGui/hud/components/tacticalMap.nut")
let { mkLBPos, mkLTPos, mkRTPos, mkCBPos, mkCTPos } = require("%rGui/hudTuning/cfg/hudTuningPkg.nut")
let { hitCamera, hitCameraCommonEditView } = require("%rGui/hud/hitCamera/hitCamera.nut")
let { mkMyPlace, mkMyPlaceUi, mkMyDamage, mkMyScoresUi } = require("%rGui/hud/myScores.nut")
let { scoreBoardType, scoreBoardCfgByType } = require("%rGui/hud/scoreBoard.nut")
let { simpleThreatRocketsIndicator, simpleThreatRocketsIndicatorEditView } = require("%rGui/hud/hudThreatRocketsBlock.nut")

let dollPosX = clamp(saSize[0] / 2 - hdpx(460), hdpx(420), hdpx(540))

let hasMyScores = Computed(@() scoreBoardCfgByType?[scoreBoardType.get()].addMyScores)

return {
  hitCamera = {
    ctor = hitCamera
    defTransform = mkRTPos([0, 0])
    editView = hitCameraCommonEditView
    hideForDelayed = false
  }

  tacticalMap = {
    ctor = mkTacticalMapForHud
    defTransform = mkLTPos([hdpx(105), 0])
    editView = tacticalMapEditView
    hideForDelayed = false
  }

  myPlace = {
    ctor = mkMyPlaceUi
    defTransform = isWidescreen ? mkCTPos([hdpx(290), 0]) : mkRTPos([-hdpx(90), hdpx(260)])
    editView = mkMyPlace(1)
    hideForDelayed = false
    isVisibleInBattle = hasMyScores
  }

  myDamage = {
    ctor = mkMyScoresUi
    defTransform = isWidescreen ? mkCTPos([hdpx(380), 0]) : mkRTPos([0, hdpx(260)])
    editView = mkMyDamage(22100)
    hideForDelayed = false
  }

  moveIndicator = NEED_SHOW_POSE_INDICATOR
    ? {
        ctor = mkMoveIndicator
        defTransform = mkCBPos([0, -sh(13)])
        editView = moveIndicatorShipEditView
        hideForDelayed = false
      }
    : null

  doll = {
    ctor = mkDollCtor(defHealthSize)
    defTransform = mkLBPos([dollPosX, hdpx(-38)])
    editView = mkDollEditView(defHealthSize)
    hideForDelayed = false
  }

  debuffs = {
    ctor = mkShipDebuffs
    defTransform = mkLBPos([dollPosX + hdpx(76), 0])
    editView = shipDebuffsEditView
    hideForDelayed = false
  }

  crewHealth = {
    ctor = mkCrewHealthCtor(defHealthSize)
    defTransform = mkLBPos([dollPosX + hdpx(130), hdpx(-115)])
    editView = mkCrewHealthEditView(defHealthSize)
    hideForDelayed = false
  }

  rocketThreatIndicator = {
    ctor = simpleThreatRocketsIndicator
    defTransform = mkLBPos([dollPosX + hdpx(-55), hdpx(-55)])
    editView = simpleThreatRocketsIndicatorEditView
    hideForDelayed = false
  }
}.filter(@(v) v != null)