from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/activeControls.nut" import isGamepad
from "%rGui/components/movementArrows.nut" import moveArrowsAirView
from "%rGui/hud/actionBar/actionBarState.nut" import curActionBarTypes
from "%rGui/hud/airMap.nut" import airMapEditView, airMap
from "%rGui/hud/airState.nut" import Cannon0, MGun0, hasCanon0, hasMGun0, AddGun, hasAddGun, isActiveTurretCamera,
  hasBombs, RocketsState, hasRockets, TorpedoesState, hasTorpedos, isTorpedoReady, hasFlare, HasBooster
from "%rGui/hud/aircraftMovementBlock.nut" import aircraftMovement, aircraftIndicators, aircraftMovementEditView,
  aircraftIndicatorsEditView, aircraftMoveStick, aircraftMoveSecondaryStick, aircraftMoveStickView, aircraftMoveArrows,
  isAircraftMoveArrowsAvailable, brakeButton, brakeButtonEditView
from "%rGui/hud/aircraftStateModule.nut" import xrayModel, dmModules, xrayModelEditView, dmModulesEditView, xrayDollSize
from "%rGui/hud/buttons/bombPieStick.nut" import bombPieStickBlockCtor, bombPieStickView
from "%rGui/hud/buttons/cameraButtons.nut" import mkFreeCameraButton, mkViewBackButton
from "%rGui/hud/buttons/circleTouchHudButtons.nut" import mkCirclePlaneCourseGuns, mkCirclePlaneCourseGunsSingle,
  mkCircleBtnPlaneEditView, mkCirclePlaneTurretsGuns, bigButtonSize, bigButtonImgSize, mkCircleZoomCtor,
  mkCircleWeaponryItemCtor, mkCircleLockBtn, mkBigCirclePlaneBtnEditView, airButtonSize, buttonAirImgSize,
  mkCircleSecondaryGuns, mkBoosterCtorBtn, boosterBtnEditView
import "%rGui/hud/buttons/flaresButton.nut" as flaresButton
from "%rGui/hud/buttons/squareTouchHudButtons.nut" import mkSimpleSquareButton, mkSquareButtonEditView
from "%rGui/hud/cameraPieMenu/cameraPieState.nut" import isCameraPieAvailable
from "%rGui/hud/cameraPieMenu/cameraPieStick.nut" import cameraPieStickBlock, cameraPieStickView
from "%rGui/hud/components/tacticalMap.nut" import mkTacticalMapForHud, tacticalMapEditView
from "%rGui/hud/controlsPieMenu/ctrlPieState.nut" import isCtrlPieAvailable
from "%rGui/hud/controlsPieMenu/ctrlPieStick.nut" import ctrlPieStickBlock, ctrlPieStickView
from "%rGui/hud/hitCamera/hitCamera.nut" import hitCamera, hitCameraCommonEditView
from "%rGui/hud/myScores.nut" import mkMyPlace, mkMyPlaceUi, mkAirMyScores, mkMyScoresUi
from "%rGui/hud/scoreBoard.nut" import scoreBoardType, scoreBoardCfgByType
from "%rGui/hud/voiceMsg/voiceMsgStick.nut" import voiceMsgStickBlock, voiceMsgStickView, isVoiceMsgStickVisibleInBattle
from "%rGui/hud/zoomSlider.nut" import mkZoomSlider, zoomSliderEditView
from "%rGui/hudState.nut" import isPlayingReplay
import "%rGui/hudTuning/cfg/cfgHudCommon.nut" as cfgHudCommon
from "%rGui/hudTuning/cfg/cfgOptions.nut" import optDoubleCourseGuns
from "%rGui/hudTuning/cfg/hudTuningPkg.nut" import Z_ORDER, mkLBPos, mkLTPos, mkRBPos, mkRTPos, mkCTPos
import "%rGui/hudTuning/cfg/initHudTuningCfg.nut" as initHudTuningCfg
from "%rGui/hudTuning/hudTuningState.nut" import shouldShowRadar, shouldShowAirTacticalMap
import "%rGui/hudTuning/squareBtnEditView.nut" as mkSquareBtnEditView
from "%rGui/missionState.nut" import raceForceCannotShoot, notGtRace
from "%rGui/radar/radar.nut" import radarHudCtor, radarHudEditView


let returnToShipShortcutIds = {
  AB_SUPPORT_PLANE = "ID_WTM_LAUNCH_AIRCRAFT"
  AB_SUPPORT_PLANE_2 = "ID_WTM_LAUNCH_AIRCRAFT_2"
  AB_SUPPORT_PLANE_3 = "ID_WTM_LAUNCH_AIRCRAFT_3"
  AB_SUPPORT_PLANE_4 = "ID_WTM_LAUNCH_AIRCRAFT_4"
}

let hasMyScores = Computed(@() scoreBoardCfgByType?[scoreBoardType.get()].addMyScores)

return cfgHudCommon.__merge(initHudTuningCfg({

  zoomSlider = {
    ctor = mkZoomSlider
    defTransform = mkLBPos([hdpx(100), hdpx(-365)])
    editView = zoomSliderEditView
    priority = Z_ORDER.SLIDER
    isVisibleInBattle = notGtRace
  }

  bomb = {
    ctor = bombPieStickBlockCtor
    defTransform = mkLBPos([hdpx(327), hdpx(-5)])
    editView = bombPieStickView
    priority = Z_ORDER.STICK
    isVisibleInBattle = Computed(@() hasBombs.get() && !isActiveTurretCamera.get())
  }

  rocket = {
    ctor = mkCircleWeaponryItemCtor("ID_ROCKETS", RocketsState, hasRockets, "ui/gameuiskin#hud_rb_rocket.svg")
    defTransform = mkLBPos([hdpx(285), hdpx(-148)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_rb_rocket.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisibleInBattle = hasRockets
  }

  torpedo = {
    ctor = mkCircleWeaponryItemCtor("ID_WTM_AIRCRAFT_TORPEDOES", TorpedoesState, hasTorpedos, "ui/gameuiskin#hud_torpedo.svg", isTorpedoReady)
    defTransform = mkLBPos([hdpx(435), hdpx(-107)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_torpedo.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisibleInBattle = hasTorpedos
  }

  flares = {
    ctor = flaresButton
    defTransform = mkLBPos([hdpx(150), hdpx(-230)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_ltc.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisibleInBattle = hasFlare
  }

  lock = {
    ctor = @(scale) {
      key = "plane_lock_target"
      children = mkCircleLockBtn("ID_LOCK_TARGET", scale)
    }
    defTransform = mkLBPos([hdpx(0), hdpx(-220)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_target_tracking_off.svg")
    isVisibleInBattle = Computed(@() !isActiveTurretCamera.get() && !raceForceCannotShoot.get() && !isPlayingReplay.get())
  }

  zoom = {
    ctor = mkCircleZoomCtor("ui/gameuiskin#hud_binoculars_zoom.svg", "ui/gameuiskin#hud_binoculars.svg", 1.2)
    defTransform = mkLBPos([hdpx(0), hdpx(-445)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_binoculars.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisibleInBattle = Computed(@() !isPlayingReplay.get() && notGtRace.get())
  }






















  back = {
    ctor = @(scale) @() {
      watch = curActionBarTypes
      children = returnToShipShortcutIds.findvalue(@(_, id) id in curActionBarTypes.get())
          ? mkSimpleSquareButton(returnToShipShortcutIds.findvalue(@(_, id) id in curActionBarTypes.get()),
              "ui/gameuiskin#hud_ship_switch.svg", scale)
        : null
    }
    defTransform = mkRBPos([hdpx(-680), 0])
    editView = mkSquareButtonEditView("ui/gameuiskin#hud_ship_switch.svg")
  }

  hitCamera = {
    canHide = false
    ctor = hitCamera
    defTransform = mkRTPos([0, 0])
    editView = hitCameraCommonEditView
    hideForDelayed = false
    priority = Z_ORDER.SUPERIOR
  }

  tacticalMap = {
    ctor = mkTacticalMapForHud
    defTransform = mkLTPos([hdpx(155), 0])
    editView = tacticalMapEditView
    hideForDelayed = false
    isVisibleInBattle = shouldShowAirTacticalMap
    isVisibleInEditor = shouldShowAirTacticalMap
  }

  radar = {
    ctor = airMap
    defTransform = mkLTPos([hdpx(120), 0])
    editView = airMapEditView
    hideForDelayed = false
    isVisibleInBattle = shouldShowRadar
    isVisibleInEditor = shouldShowRadar
  }

  myPlace = {
    ctor = mkMyPlaceUi
    defTransform = isWidescreen ? mkCTPos([hdpx(290), 0]) : mkRTPos([-hdpx(90), hdpx(260)])
    editView = mkMyPlace(1)
    hideForDelayed = false
    isVisibleInBattle = hasMyScores
  }

  myScores = {
    ctor = mkMyScoresUi
    defTransform = isWidescreen ? mkCTPos([hdpx(380), 0]) : mkRTPos([0, hdpx(260)])
    editView = { children = mkAirMyScores(221) }
    hideForDelayed = false
    isVisibleInBattle = hasMyScores
  }

  dmModules = {
    ctor = dmModules
    defTransform = mkLBPos([hdpx(480) + xrayDollSize, hdpx(30)])
    editView = dmModulesEditView
    hideForDelayed = false
  }

  xpayModel = {
    canHide = false
    ctor = xrayModel
    defTransform = mkLBPos([hdpx(480), hdpx(30)])
    editView = xrayModelEditView
    isVisibleInBattle = Computed(@() !isPlayingReplay.get())
    hideForDelayed = false
  }

  voiceCmdStick = {
    ctor = voiceMsgStickBlock
    defTransform = mkRBPos([0, hdpx(-0)])
    editView = voiceMsgStickView
    isVisibleInBattle = isVoiceMsgStickVisibleInBattle
    priority = Z_ORDER.STICK
  }

  movement = {
    canHide = false
    ctor = aircraftMovement
    defTransform = mkRBPos([hdpx(-120), 0])
    editView = aircraftMovementEditView
    priority = Z_ORDER.STICK
  }

  brakeButton = {
    canHide = false
    ctor = brakeButton
    defTransform = mkRBPos([hdpx(-10), hdpx(-130)])
    editView = brakeButtonEditView
    priority = Z_ORDER.BUTTON
  }

  indicators = {
    ctor = aircraftIndicators
    defTransform = mkRBPos([hdpx(-20), hdpx(-500)])
    editView = aircraftIndicatorsEditView
    hideForDelayed = false
  }

  viewBackButton = {
    ctor = mkViewBackButton
    defTransform = mkLTPos([hdpx(0), hdpx(130)])
    editView = mkSquareBtnEditView("ui/gameuiskin#hud_look_back.svg")
    isVisibleInBattle = Computed(@() !isPlayingReplay.get())
    priority = Z_ORDER.BUTTON
  }

  freeCameraButton = {
    ctor = mkFreeCameraButton
    defTransform = mkLTPos([hdpx(0), hdpx(255)])
    editView = mkSquareBtnEditView("ui/gameuiskin#hud_free_camera.svg")
    isVisibleInBattle = Computed(@() !isPlayingReplay.get())
    priority = Z_ORDER.BUTTON
  }

  courseGuns = {
    canHide = false
    ctor = @(scale) @() {
      key = "air_course_guns_main"
      watch = isActiveTurretCamera
      children = isActiveTurretCamera.get() ? mkCirclePlaneTurretsGuns(bigButtonSize, bigButtonImgSize, scale)
        : mkCirclePlaneCourseGuns(bigButtonSize, bigButtonImgSize, scale)
    }
    defTransform = mkLBPos([hdpx(105), hdpx(-60)])
    editView = mkBigCirclePlaneBtnEditView("ui/gameuiskin#hud_aircraft_machine_gun.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisible = @(options) !optDoubleCourseGuns.has(options)
    options = [ optDoubleCourseGuns ]
  }
  courseGunsSecondBtn = {
    canHide = false
    ctor = @(scale) @() {
      key = "air_course_guns_second"
      watch = [isGamepad, isActiveTurretCamera]
      children = isGamepad.get() ? null
        : isActiveTurretCamera.get() ? mkCirclePlaneTurretsGuns(airButtonSize, buttonAirImgSize, scale)
        : mkCirclePlaneCourseGuns(airButtonSize, buttonAirImgSize, scale)
    }
    defTransform = mkRBPos([hdpx(-300), hdpx(-280)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_aircraft_machine_gun.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
  }

  cannons = {
    ctor = @(scale) @() {
      watch = [hasCanon0, hasMGun0, isActiveTurretCamera]
      key = "air_cannon"
      children = isActiveTurretCamera.get() ? mkCirclePlaneTurretsGuns(bigButtonSize, bigButtonImgSize, scale)
        : hasCanon0.get() ? mkCirclePlaneCourseGunsSingle("ID_FIRE_CANNONS", Cannon0, hasCanon0, scale, bigButtonSize, bigButtonImgSize)
        : mkCirclePlaneCourseGunsSingle("ID_FIRE_MGUNS", MGun0, hasMGun0, scale, bigButtonSize, bigButtonImgSize)
    }
    defTransform = mkLBPos([hdpx(105), hdpx(-60)])
    editView = mkBigCirclePlaneBtnEditView("ui/gameuiskin#hud_aircraft_machine_gun.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisible = optDoubleCourseGuns.has
    options = [ optDoubleCourseGuns ]
  }

  miniguns = {
    ctor = @(scale) @() {
      watch = hasCanon0
      key = "air_minigun"
      children = hasCanon0.get()
        ? mkCircleSecondaryGuns(airButtonSize, buttonAirImgSize, scale)
        : mkCirclePlaneCourseGunsSingle("ID_FIRE_ADDITIONAL_GUNS", AddGun, hasAddGun, scale)
    }
    defTransform = mkLBPos([hdpx(142), hdpx(-245)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_aircraft_machine_gun.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisible = optDoubleCourseGuns.has
    options = [ optDoubleCourseGuns ]
  }

  controlsStick = {
    canHide = false
    ctor = ctrlPieStickBlock
    defTransform = mkRBPos([hdpx(-545), hdpx(-0)])
    editView = ctrlPieStickView
    isVisibleInBattle = isCtrlPieAvailable
    priority = Z_ORDER.STICK
  }

  cameraStick = {
    ctor = cameraPieStickBlock
    defTransform = mkRBPos([hdpx(-415), hdpx(-0)])
    editView = cameraPieStickView
    isVisibleInBattle = isCameraPieAvailable
    priority = Z_ORDER.STICK
  }

  moveStick = {
    canHide = false
    ctor = aircraftMoveStick
    defTransform = mkRBPos([hdpx(-20), hdpx(-320)])
    editView = aircraftMoveStickView
    priority = Z_ORDER.STICK
  }

  moveSecondaryStick = {
    canHide = false
    ctor = aircraftMoveSecondaryStick
    defTransform = mkLBPos([hdpx(200), hdpx(-320)])
    editView = aircraftMoveStickView
    priority = Z_ORDER.STICK
  }

  moveArrows = {
    canHide = false
    ctor = aircraftMoveArrows
    defTransform = mkRBPos([hdpx(-450), hdpx(-150)])
    editView = moveArrowsAirView
    priority = Z_ORDER.STICK
    isVisibleInBattle = isAircraftMoveArrowsAvailable
  }

  radarHud = {
    ctor = radarHudCtor
    defTransform = mkRTPos([-hdpx(20), 0])
    editView = radarHudEditView
    priority = Z_ORDER.BUTTON
  }

  booster = {
    ctor = mkBoosterCtorBtn
    defTransform = mkRTPos([hdpx(-10), hdpx(630)])
    editView = boosterBtnEditView
    isVisibleInBattle = HasBooster
    priority = Z_ORDER.BUTTON
  }

  chatLogAndKillLog = cfgHudCommon.chatLogAndKillLog.__merge({ defTransform = mkLTPos([hdpx(220), hdpx(320)]) })
}))
