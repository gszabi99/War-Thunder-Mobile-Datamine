from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/components/moveIndicator.nut" import NEED_SHOW_POSE_INDICATOR, mkMoveIndicator,
  moveIndicatorShipEditView
from "%rGui/hud/components/tacticalMap.nut" import mkTacticalMapForHud, tacticalMapEditView
from "%rGui/hud/hitCamera/hitCamera.nut" import hitCamera, hitCameraCommonEditView
from "%rGui/hud/hudThreatRocketsBlock.nut" import simpleThreatRocketsIndicator, simpleThreatRocketsIndicatorEditView
from "%rGui/hud/hudThreatTorpedosBlock.nut" import simpleThreatTorpedosIndicator, simpleThreatTorpedosIndicatorEditView
from "%rGui/hud/myScores.nut" import mkMyPlace, mkMyPlaceUi, mkMyDamage, mkMyScoresUi
from "%rGui/hud/scoreBoard.nut" import scoreBoardType, scoreBoardCfgByType
from "%rGui/hud/shipStateModule.nut" import mkDollCtor, mkDollEditView, mkShipDebuffs, shipDebuffsEditView,
  mkCrewHealthCtor, mkCrewHealthEditView, defHealthSize
from "%rGui/hudState.nut" import isPlayingReplay
from "%rGui/hudTuning/cfg/hudTuningPkg.nut" import mkLBPos, mkLTPos, mkRTPos, mkCBPos, mkCTPos
import "%rGui/hudTuning/cfg/initHudTuningCfg.nut" as initHudTuningCfg


let dollPosX = clamp(saSize[0] / 2 - hdpx(460), hdpx(420), hdpx(540))

let hasMyScores = Computed(@() scoreBoardCfgByType?[scoreBoardType.get()].addMyScores)

return initHudTuningCfg({
  hitCamera = {
    canHide = false
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
    canHide = false
    ctor = mkDollCtor(defHealthSize)
    defTransform = mkLBPos([dollPosX, hdpx(-38)])
    editView = mkDollEditView(defHealthSize)
    isVisibleInBattle = Computed(@() !isPlayingReplay.get())
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
  torpedoThreatIndicator = {
    ctor = simpleThreatTorpedosIndicator
    defTransform = mkLBPos([dollPosX + hdpx(-55), hdpx(-55)])
    editView = simpleThreatTorpedosIndicatorEditView
    hideForDelayed = false
  }
}.filter(@(v) v != null))