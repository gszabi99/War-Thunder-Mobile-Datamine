from "%globalsDarg/darg_library.nut" import *
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { Z_ORDER, mkLBPos, mkLTPos, mkRBPos, mkRTPos, mkCTPos } = require("%rGui/hudTuning/cfg/hudTuningPkg.nut")
let { optDoubleCourseGuns } = require("%rGui/hudTuning/cfg/cfgOptions.nut")
let {
  aircraftMovement,
  aircraftIndicators,
  aircraftMovementEditView,
  aircraftIndicatorsEditView,
  aircraftMoveStick,
  aircraftMoveSecondaryStick
  aircraftMoveStickView,
  aircraftMoveArrows,
  isAircraftMoveArrowsAvailable,
  brakeButton,
  brakeButtonEditView
} = require("%rGui/hud/aircraftMovementBlock.nut")
let { radarHudCtor, radarHudEditView } = require("%rGui/radar/radar.nut")
let { voiceMsgStickBlock, voiceMsgStickView, isVoiceMsgStickVisibleInBattle
} = require("%rGui/hud/voiceMsg/voiceMsgStick.nut")
let { ctrlPieStickBlock, ctrlPieStickView } = require("%rGui/hud/controlsPieMenu/ctrlPieStick.nut")
let { isCtrlPieAvailable } = require("%rGui/hud/controlsPieMenu/ctrlPieState.nut")
let { isCameraPieAvailable } = require("%rGui/hud/cameraPieMenu/cameraPieState.nut")
let { cameraPieStickBlock, cameraPieStickView } = require("%rGui/hud/cameraPieMenu/cameraPieStick.nut")
let { bombPieStickBlockCtor, bombPieStickView } = require("%rGui/hud/buttons/bombPieStick.nut")
let { airMapEditView, airMap } = require("%rGui/hud/airMap.nut")
let cfgHudCommon = require("%rGui/hudTuning/cfg/cfgHudCommon.nut")
let { hitCamera, hitCameraCommonEditView } = require("%rGui/hud/hitCamera/hitCamera.nut")
let { mkFreeCameraButton, mkViewBackButton } = require("%rGui/hud/buttons/cameraButtons.nut")
let mkSquareBtnEditView = require("%rGui/hudTuning/squareBtnEditView.nut")
let { mkMyPlace, mkMyPlaceUi, mkAirMyScores, mkMyScoresUi } = require("%rGui/hud/myScores.nut")
let { scoreBoardType, scoreBoardCfgByType } = require("%rGui/hud/scoreBoard.nut")
let { xrayModel, dmModules, xrayModelEditView, dmModulesEditView, xrayDollSize } = require("%rGui/hud/aircraftStateModule.nut")
let { mkCirclePlaneCourseGuns, mkCirclePlaneCourseGunsSingle, mkCircleBtnPlaneEditView, mkCirclePlaneTurretsGuns,
  bigButtonSize, bigButtonImgSize, mkCircleZoomCtor, mkCircleWeaponryItemCtor, mkCircleLockBtn, mkBigCirclePlaneBtnEditView, airButtonSize,
  buttonAirImgSize, mkCircleSecondaryGuns
} = require("%rGui/hud/buttons/circleTouchHudButtons.nut")
let { Cannon0, MGun0, hasCanon0, hasMGun0, AddGun, hasAddGun, isActiveTurretCamera
  hasBombs, RocketsState, hasRockets, TorpedoesState, hasTorpedos,
} = require("%rGui/hud/airState.nut")
let { mkSimpleSquareButton, mkSquareButtonEditView } = require("%rGui/hud/buttons/squareTouchHudButtons.nut")
let { mkZoomSlider, zoomSliderEditView } = require("%rGui/hud/zoomSlider.nut")
let { moveArrowsAirView } = require("%rGui/components/movementArrows.nut")
let { canShowRadar } = require("%rGui/hudTuning/hudTuningState.nut")
let { curActionBarTypes } = require("%rGui/hud/actionBar/actionBarState.nut")

let returnToShipShortcutIds = {
  AB_SUPPORT_PLANE = "ID_WTM_LAUNCH_AIRCRAFT"
  AB_SUPPORT_PLANE_2 = "ID_WTM_LAUNCH_AIRCRAFT_2"
  AB_SUPPORT_PLANE_3 = "ID_WTM_LAUNCH_AIRCRAFT_3"
  AB_SUPPORT_PLANE_4 = "ID_WTM_LAUNCH_AIRCRAFT_4"
}

let hasMyScores = Computed(@() scoreBoardCfgByType?[scoreBoardType.get()].addMyScores)

return cfgHudCommon.__merge({

  zoomSlider = {
    ctor = mkZoomSlider
    defTransform = mkLBPos([hdpx(100), hdpx(-365)])
    editView = zoomSliderEditView
    priority = Z_ORDER.SLIDER
  }

  bomb = {
    ctor = bombPieStickBlockCtor
    defTransform = mkLBPos([hdpx(327), hdpx(-5)])
    editView = bombPieStickView
    priority = Z_ORDER.STICK
    isVisibleInBattle = hasBombs
  }

  rocket = {
    ctor = mkCircleWeaponryItemCtor("ID_ROCKETS", RocketsState, hasRockets, "ui/gameuiskin#hud_rb_rocket.svg", false)
    defTransform = mkLBPos([hdpx(285), hdpx(-148)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_rb_rocket.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisibleInBattle = hasRockets
  }

  torpedo = {
    ctor = mkCircleWeaponryItemCtor("ID_WTM_AIRCRAFT_TORPEDOES", TorpedoesState, hasTorpedos, "ui/gameuiskin#hud_torpedo.svg", false)
    defTransform = mkLBPos([hdpx(435), hdpx(-107)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_torpedo.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisibleInBattle = hasTorpedos
  }

  lock = {
    ctor = @(scale) {
      key = "plane_lock_target"
      children = mkCircleLockBtn("ID_LOCK_TARGET", scale)
    }
    defTransform = mkLBPos([hdpx(0), hdpx(-220)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_target_tracking_off.svg")
    isVisibleInBattle = Computed(@() !isActiveTurretCamera.value)
  }

  zoom = {
    ctor = mkCircleZoomCtor("ui/gameuiskin#hud_binoculars_zoom.svg", "ui/gameuiskin#hud_binoculars.svg", 1.2)
    defTransform = mkLBPos([hdpx(0), hdpx(-445)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_binoculars.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
  }






















  back = {
    ctor = @(scale) @() {
      watch = curActionBarTypes
      children = returnToShipShortcutIds.findvalue(@(_, id) id in curActionBarTypes.get())
          ? mkSimpleSquareButton(returnToShipShortcutIds.findvalue(@(_, id) id in curActionBarTypes.get()),
              "ui/gameuiskin#hud_ship_switch.svg", scale)
        : null
    }
    defTransform = mkRBPos([hdpx(-680), hdpx(-0)])
    editView = mkSquareButtonEditView("ui/gameuiskin#hud_ship_switch.svg")
  }

  hitCamera = {
    ctor = hitCamera
    defTransform = mkRTPos([0, 0])
    editView = hitCameraCommonEditView
    hideForDelayed = false
    priority = Z_ORDER.SUPERIOR
  }

  radar = {
    ctor = airMap
    defTransform = mkLTPos([hdpx(120), 0])
    editView = airMapEditView
    hideForDelayed = false
    isVisibleInBattle = canShowRadar
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
    ctor = xrayModel
    defTransform = mkLBPos([hdpx(480), hdpx(30)])
    editView = xrayModelEditView
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
    ctor = aircraftMovement
    defTransform = mkRBPos([hdpx(-120), 0])
    editView = aircraftMovementEditView
    priority = Z_ORDER.STICK
  }

  brakeButton = {
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
    priority = Z_ORDER.BUTTON
  }

  freeCameraButton = {
    ctor = mkFreeCameraButton
    defTransform = mkLTPos([hdpx(0), hdpx(255)])
    editView = mkSquareBtnEditView("ui/gameuiskin#hud_free_camera.svg")
    priority = Z_ORDER.BUTTON
  }

  courseGuns = {
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
    ctor = aircraftMoveStick
    defTransform = mkRBPos([hdpx(-20), hdpx(-320)])
    editView = aircraftMoveStickView
    priority = Z_ORDER.STICK
  }

  moveSecondaryStick = {
    ctor = aircraftMoveSecondaryStick
    defTransform = mkLBPos([hdpx(200), hdpx(-320)])
    editView = aircraftMoveStickView
    priority = Z_ORDER.STICK
  }

  moveArrows = {
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

  chatLogAndKillLog = cfgHudCommon.chatLogAndKillLog.__merge({ defTransform = mkLTPos([hdpx(220), hdpx(320)]) })
})
