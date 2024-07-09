from "%globalsDarg/darg_library.nut" import *
let { allow_voice_messages } = require("%appGlobals/permissions.nut")
let { isInMpSession } = require("%appGlobals/clientState/clientState.nut")
let { Z_ORDER, mkLBPos, mkLTPos, mkRBPos, mkRTPos, mkCTPos } = require("hudTuningPkg.nut")
let { optDoubleCourseGuns } = require("cfgOptions.nut")
let {
  aircraftMovement,
  aircraftIndicators,
  aircraftMovementEditView,
  aircraftIndicatorsEditView,
  aircraftMoveStick,
  aircraftMoveStickView,
  aircraftMoveArrows,
  isAircraftMoveArrowsAvailable
} = require("%rGui/hud/aircraftMovementBlock.nut")
let { voiceMsgStickBlock, voiceMsgStickView } = require("%rGui/hud/voiceMsg/voiceMsgStick.nut")
let { ctrlPieStickBlock, ctrlPieStickView } = require("%rGui/hud/controlsPieMenu/ctrlPieStick.nut")
let { isCtrlPieAvailable } = require("%rGui/hud/controlsPieMenu/ctrlPieState.nut")
let { isCameraPieAvailable } = require("%rGui/hud/cameraPieMenu/cameraPieState.nut")
let { cameraPieStickBlock, cameraPieStickView } = require("%rGui/hud/cameraPieMenu/cameraPieStick.nut")
let { aircraftRadarEditView, aircraftRadar } = require("%rGui/hud/aircraftRadar.nut")
let cfgHudCommon = require("cfgHudCommon.nut")
let { hitCamera, hitCameraCommonEditView } = require("%rGui/hud/hitCamera/hitCamera.nut")
let { mkFreeCameraButton, mkViewBackButton } = require("%rGui/hud/buttons/cameraButtons.nut")
let mkSquareBtnEditView = require("%rGui/hudTuning/squareBtnEditView.nut")
let { mkMyPlace, myPlaceUi, mkAirMyScores, myScoresUi } = require("%rGui/hud/myScores.nut")
let { xrayModel, dmModules, xrayModelEditView, dmModulesEditView } = require("%rGui/hud/aircraftStateModule.nut")
let { mkCirclePlaneCourseGuns, mkCirclePlaneCourseGunsSingle, mkCircleBtnPlaneEditView, mkCirclePlaneTurretsGuns,
  bigButtonSize, bigButtonImgSize, mkCircleZoom, mkCircleWeaponryItem, mkCircleLockBtn, mkBigCirclePlaneBtnEditView
} = require("%rGui/hud/buttons/circleTouchHudButtons.nut")
let { Cannon0, MGun0, hasCanon0, hasMGun0,
  BombsState, hasBombs,
  RocketsState, hasRockets,
  TorpedoesState, hasTorpedos,
  isActiveTurretCamera
} = require("%rGui/hud/airState.nut")
let { returnToShipButton, mkSquareButtonEditView } = require("%rGui/hud/buttons/squareTouchHudButtons.nut")
let { zoomSlider, zoomSliderEditView } = require("%rGui/hud/zoomSlider.nut")
let { moveArrowsAirView } = require("%rGui/components/movementArrows.nut")
let { chatLogAndKillLogPlace, chatLogAndKillLogEditView } = require("%rGui/hudHints/hintBlocks.nut")
let { canShowRadar } = require("%rGui/hudTuning/hudTuningState.nut")

return cfgHudCommon.__merge({

  zoomSlider = {
    ctor = @() zoomSlider
    defTransform = mkLBPos([hdpx(100), hdpx(-350)])
    editView = zoomSliderEditView
    priority = Z_ORDER.SLIDER
  }

  bomb = {
    ctor = @() mkCircleWeaponryItem("ID_BOMBS", BombsState, hasBombs, "ui/gameuiskin#hud_bomb.svg", false, true)
    defTransform = mkLBPos([hdpx(327), hdpx(-5)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_bomb.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisibleInBattle = hasBombs
  }

  rocket = {
    ctor = @() mkCircleWeaponryItem("ID_ROCKETS", RocketsState, hasRockets, "ui/gameuiskin#hud_rb_rocket.svg", true)
    defTransform = mkLBPos([hdpx(272), hdpx(-148)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_rb_rocket.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisibleInBattle = hasRockets
  }

  torpedo = {
    ctor = @() mkCircleWeaponryItem("ID_TORPEDOES", TorpedoesState, hasTorpedos, "ui/gameuiskin#hud_torpedo.svg", true)
    defTransform = mkLBPos([hdpx(435), hdpx(-107)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_torpedo.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisibleInBattle = hasTorpedos
  }

  lock = {
    ctor = @() {
      key = "plane_lock_target"
      children = mkCircleLockBtn("ID_LOCK_TARGET")
    }
    defTransform = mkLBPos([hdpx(0), hdpx(-162)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_target_tracking_off.svg")
    isVisibleInBattle = Computed(@() !isActiveTurretCamera.value)
  }

  zoom = {
    ctor = @() mkCircleZoom("ui/gameuiskin#hud_binoculars_zoom.svg", "ui/gameuiskin#hud_binoculars.svg")
    defTransform = mkLBPos([hdpx(0), hdpx(-370)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_binoculars.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
  }

  back = {
    ctor = returnToShipButton
    defTransform = mkRBPos([hdpx(-240), hdpx(-0)])
    editView = mkSquareButtonEditView("ui/gameuiskin#hud_ship_selection.svg")
  }

  hitCamera = {
    ctor = @() hitCamera
    defTransform = mkRTPos([0, 0])
    editView = hitCameraCommonEditView
    hideForDelayed = false
  }

  radar = {
    ctor = @() aircraftRadar
    defTransform = mkLTPos([hdpx(105), 0])
    editView = aircraftRadarEditView
    hideForDelayed = false
    isVisibleInBattle = canShowRadar
  }

  myPlace = {
    ctor = @() myPlaceUi
    defTransform = isWidescreen ? mkCTPos([hdpx(290), 0]) : mkRTPos([-hdpx(90), hdpx(260)])
    editView = mkMyPlace(1)
    hideForDelayed = false
  }

  myScores = {
    ctor = @() myScoresUi
    defTransform = isWidescreen ? mkCTPos([hdpx(380), 0]) : mkRTPos([0, hdpx(260)])
    editView = { children = mkAirMyScores(221) }
    hideForDelayed = false
  }

  dmModules = {
    ctor = @() dmModules
    defTransform = mkLBPos([hdpx(480), hdpx(30)])
    editView = dmModulesEditView
    hideForDelayed = false
  }

  xpayModel = {
    ctor = @() xrayModel
    defTransform = mkLBPos([hdpx(820), hdpx(30)])
    editView = xrayModelEditView
    hideForDelayed = false
  }

  voiceCmdStick = {
    ctor = @() voiceMsgStickBlock
    defTransform = mkRBPos([0, hdpx(-0)])
    editView = voiceMsgStickView
    isVisibleInEditor = allow_voice_messages
    isVisibleInBattle = Computed(@() allow_voice_messages.get() && isInMpSession.get())
    priority = Z_ORDER.STICK
  }

  movement = {
    ctor = @() aircraftMovement
    defTransform = mkRBPos([hdpx(-140), 0])
    editView = aircraftMovementEditView
    priority = Z_ORDER.STICK
  }

  indicators = {
    ctor = @() aircraftIndicators
    defTransform = mkRBPos([hdpx(-20), hdpx(-500)])
    editView = aircraftIndicatorsEditView
    hideForDelayed = false
  }

  viewBackButton = {
    ctor = mkViewBackButton
    defTransform = mkLTPos([hdpx(0), hdpx(210)])
    editView = mkSquareBtnEditView("ui/gameuiskin#hud_look_back.svg")
    priority = Z_ORDER.BUTTON
  }

  freeCameraButton = {
    ctor = mkFreeCameraButton
    defTransform = mkLTPos([hdpx(0), hdpx(350)])
    editView = mkSquareBtnEditView("ui/gameuiskin#hud_free_camera.svg")
    priority = Z_ORDER.BUTTON
  }

  courseGuns = {
    ctor = @() @() {
      key = "plane_course_guns"
      watch = isActiveTurretCamera
      children = isActiveTurretCamera.get() ? mkCirclePlaneTurretsGuns(bigButtonSize, bigButtonImgSize)
        : mkCirclePlaneCourseGuns()
    }
    defTransform = mkLBPos([hdpx(60), hdpx(-0)])
    editView = mkBigCirclePlaneBtnEditView("ui/gameuiskin#hud_aircraft_machine_gun.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisible = @(options) !optDoubleCourseGuns.has(options)
    options = [ optDoubleCourseGuns ]
  }

  cannons = {
    ctor = @() @() {
      watch = [hasCanon0, hasMGun0, isActiveTurretCamera]
      children = isActiveTurretCamera.get() ? mkCirclePlaneTurretsGuns(bigButtonSize, bigButtonImgSize)
        : hasCanon0.get() ? mkCirclePlaneCourseGunsSingle("ID_FIRE_CANNONS", Cannon0, hasCanon0, bigButtonSize, bigButtonImgSize)
        : mkCirclePlaneCourseGunsSingle("ID_FIRE_MGUNS", MGun0, hasMGun0, bigButtonSize, bigButtonImgSize)
    }
    defTransform = mkLBPos([hdpx(70), hdpx(-5)])
    editView = mkBigCirclePlaneBtnEditView("ui/gameuiskin#hud_aircraft_machine_gun.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisible = optDoubleCourseGuns.has
    options = [ optDoubleCourseGuns ]
  }

  miniguns = {
    ctor = @() mkCirclePlaneCourseGunsSingle("ID_FIRE_MGUNS",
      MGun0,
      Computed(@() hasCanon0.get() && hasMGun0.get()))
    defTransform = mkLBPos([hdpx(142), hdpx(-245)])
    editView = mkCircleBtnPlaneEditView("ui/gameuiskin#hud_aircraft_machine_gun.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisible = optDoubleCourseGuns.has
    options = [ optDoubleCourseGuns ]
  }

  controlsStick = {
    ctor = @() ctrlPieStickBlock
    defTransform = mkRBPos([hdpx(-535), hdpx(-0)])
    editView = ctrlPieStickView
    isVisibleInBattle = isCtrlPieAvailable
    priority = Z_ORDER.STICK
  }

  cameraStick = {
    ctor = @() cameraPieStickBlock
    defTransform = mkRBPos([hdpx(-395), hdpx(-0)])
    editView = cameraPieStickView
    isVisibleInBattle = isCameraPieAvailable
    priority = Z_ORDER.STICK
  }

  moveStick = {
    ctor = @() @() {
      children = aircraftMoveStick
    }
    defTransform = mkRBPos([hdpx(20), hdpx(-220)])
    editView = aircraftMoveStickView
    priority = Z_ORDER.STICK
  }

  moveArrows = {
    ctor = aircraftMoveArrows
    defTransform = mkRBPos([hdpx(-300), hdpx(-150)])
    editView = moveArrowsAirView
    priority = Z_ORDER.STICK
    isVisibleInBattle = isAircraftMoveArrowsAvailable
  }

  chatLogAndKillLog = {
    ctor = chatLogAndKillLogPlace
    defTransform = mkLTPos([hdpx(220), hdpx(320)])
    editView = chatLogAndKillLogEditView
  }
})
