from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/capZones/capZones.nut" import capZonesEditView, capZonesList
from "%rGui/hud/eventMissionMessageBox.nut" import msgBlock, msgBlockEditView
from "%rGui/hud/menuButton.nut" import mkMenuButton, mkMenuButtonEditView
from "%rGui/hud/missionScoreState.nut" import isCTFProgressType, isNotCTFProgressType
from "%rGui/hud/raceLeadership.nut" import raceLeadershipEditView, raceLeadershipCtor
from "%rGui/hud/scoreBoard.nut" import scoreBoardEditView, needScoreBoard, scoreBoardCfgByType, scoreBoardType
from "%rGui/hud/zoomSlider.nut" import mkZoomSlider, zoomSliderEditView
from "%rGui/hudHints/hintBlocks.nut" import chatLogAndKillLogPlace, chatLogAndKillLogEditView
from "%rGui/hudState.nut" import isPlayingReplay
from "%rGui/hudTuning/cfg/cfgOptions.nut" import optFontSize, optTextWidth
from "%rGui/hudTuning/cfg/hudTuningPkg.nut" import Z_ORDER, mkRBPos, mkCTPos, mkLTPos, mkRTPos
import "%rGui/hudTuning/cfg/initHudTuningCfg.nut" as initHudTuningCfg
from "%rGui/missionState.nut" import isGtRace
from "%rGui/respawn/respawnState.nut" import isUseSpawnScore
from "%rGui/respawn/spawnScore.nut" import spawnScoreEditView, hudSpawnScoreCtor


return initHudTuningCfg({
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
    isVisibleInBattle = Computed(@() needScoreBoard.get() && !isPlayingReplay.get())
  }

  zoneIndicators = {
    ctor = capZonesList
    defTransform = mkCTPos([0, hdpx(42)])
    editView = capZonesEditView
    hideForDelayed = false
    isVisibleInBattle = isNotCTFProgressType
    isVisibleInEditor = isNotCTFProgressType
  }

  spawnScore = {
    ctor = hudSpawnScoreCtor
    defTransform = mkCTPos([hdpx(170), hdpx(42)])
    editView = spawnScoreEditView
    hideForDelayed = false
    isVisibleInBattle = isUseSpawnScore
    isVisibleInEditor = isUseSpawnScore
  }

  eventMissionMessageBox = {
    ctor = msgBlock
    defTransform = mkCTPos([0, hdpx(42)])
    editView = msgBlockEditView
    isVisibleInBattle = isCTFProgressType
    isVisibleInEditor = isCTFProgressType
  }

  chatLogAndKillLog = {
    ctor = chatLogAndKillLogPlace
    defTransform = mkLTPos([0, hdpx(360)])
    editView = chatLogAndKillLogEditView
    options = [ optFontSize, optTextWidth ]
  }

  menuBtn = {
    canHide = false
    ctor = @(scale) mkMenuButton(scale)
    defTransform = mkLTPos([0, 0])
    priority = Z_ORDER.SUPERIOR
    editView = mkMenuButtonEditView
    hideForDelayed = false
  }

  raceLeadership = {
    ctor = raceLeadershipCtor
    defTransform = mkRTPos([0, 0])
    editView = raceLeadershipEditView
    options = [ optFontSize ]
    isVisibleInBattle = isGtRace
    isVisibleInEditor = isGtRace
  }
})