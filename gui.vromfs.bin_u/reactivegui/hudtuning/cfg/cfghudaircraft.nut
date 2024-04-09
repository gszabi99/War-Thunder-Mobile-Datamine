from "%globalsDarg/darg_library.nut" import *
let { allow_voice_messages } = require("%appGlobals/permissions.nut")
let { set_chat_handler = null } = require("chat")
let { missionPlayVoice = null } = require("sound_wt")
let { isInMpSession } = require("%appGlobals/clientState/clientState.nut")
let { mkSimpleButton, mkGroupAttackButton
} = require("%rGui/hud/weaponsButtonsView.nut")
let { mkWeaponBtnEditView } = require("%rGui/hudTuning/weaponBtnEditView.nut")
let { Z_ORDER, mkLBPos, mkLTPos, mkRBPos, mkRTPos, mkCTPos,
  weaponryButtonCtor, weaponryButtonsGroupCtor } = require("hudTuningPkg.nut")
let { optDoubleCourseGuns } = require("cfgOptions.nut")
let {
  aircraftMovement,
  aircraftIndicators,
  aircraftMovementEditView,
  aircraftIndicatorsEditView
} = require("%rGui/hud/aircraftMovementBlock.nut")
let { voiceMsgStickBlock, voiceMsgStickView } = require("%rGui/hud/voiceMsg/voiceMsgStick.nut")
let { aircraftRadarEditView, aircraftRadar } = require("%rGui/hud/aircraftRadar.nut")
let cfgHudCommon = require("cfgHudCommon.nut")
let { hitCamera, hitCameraCommonEditView } = require("%rGui/hud/hitCamera/hitCamera.nut")
let mkFreeCameraButton = require("%rGui/hud/buttons/freeCameraButton.nut")
let mkSquareBtnEditView = require("%rGui/hudTuning/squareBtnEditView.nut")
let { mkMyPlace, myPlaceUi, mkMyScores, myScoresUi } = require("%rGui/hud/myScores.nut")
let { doll, dollEditView } = require("%rGui/hud/aircraftStateModule.nut")
let { mkCirclePlaneCourseGuns, mkCirclePlaneCourseGunsSingle, mkBigCircleBtnEditView, mkCircleBtnEditView,
  bigButtonSize, bigButtonImgSize, mkCircleZoom, mkCircleWeaponryItem, mkCircleLockBtn
} = require("%rGui/hud/buttons/circleTouchHudButtons.nut")
let { Cannon0, MGun0, hasCanon0, hasMGun0,
  BombsState, hasBombs,
  RocketsState, hasRockets,
} = require("%rGui/hud/airState.nut")


let allow_voice_messages_compatibility = Computed(@() allow_voice_messages.get() && !!set_chat_handler && !!missionPlayVoice)

return cfgHudCommon.__merge({
  bomb = {
    ctor = @() mkCircleWeaponryItem("ID_BOMBS", BombsState, hasBombs, "ui/gameuiskin#hud_bomb.svg", false, true)
    defTransform = mkLBPos([hdpx(320), hdpx(-10)])
    editView = mkCircleBtnEditView("ui/gameuiskin#hud_bomb.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
  }

  rocket = {
    ctor = @() mkCircleWeaponryItem("ID_ROCKETS", RocketsState, hasRockets, "ui/gameuiskin#hud_rb_rocket.svg", true, true)
    defTransform = mkLBPos([hdpx(227), hdpx(-287)])
    editView = mkCircleBtnEditView("ui/gameuiskin#hud_rb_rocket.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
  }

  lock = {
    ctor = @() mkCircleLockBtn("ID_LOCK_TARGET")
    defTransform = mkLBPos([hdpx(0), hdpx(-200)])
    editView = mkCircleBtnEditView("ui/gameuiskin#hud_target_tracking_off.svg")
  }

  zoom = {
    ctor = @() mkCircleZoom("ui/gameuiskin#hud_binoculars_zoom.svg", "ui/gameuiskin#hud_binoculars.svg")
    defTransform = mkLBPos([hdpx(100), hdpx(-440)])
    editView = mkCircleBtnEditView("ui/gameuiskin#hud_binoculars.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
  }
//












  groupReturn = weaponryButtonCtor("ID_WTM_AIRCRAFT_RETURN", mkSimpleButton,
    {
      defTransform = mkLBPos([hdpx(433), hdpx(-275)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_aircraft_fighter.svg")
    })

  back = weaponryButtonsGroupCtor([
      "ID_WTM_RETURN_TO_SHIP",
      "ID_WTM_RETURN_TO_SHIP_2",
      "ID_WTM_RETURN_TO_SHIP_3",
      "ID_WTM_RETURN_TO_SHIP_4"
    ],
    mkSimpleButton,
    {
      defTransform = mkLBPos([hdpx(433), hdpx(-113)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_ship_selection.svg")
    })

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
    editView = mkMyScores(22100)
    hideForDelayed = false
  }

  doll = {
    ctor = @() doll
    defTransform = mkLBPos([hdpx(580), hdpx(30)])
    editView = dollEditView
    hideForDelayed = false
  }

  voiceCmdStick = {
    ctor = @() voiceMsgStickBlock
    defTransform = mkRBPos([0, hdpx(-27)])
    editView = voiceMsgStickView
    isVisibleInEditor = allow_voice_messages_compatibility
    isVisibleInBattle = Computed(@() allow_voice_messages_compatibility.get() && isInMpSession.get())
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
    defTransform = mkRBPos([0, hdpx(-290)])
    editView = aircraftIndicatorsEditView
    hideForDelayed = false
  }

  freeCameraButton = {
    ctor = mkFreeCameraButton
    defTransform = mkLTPos([hdpx(0), hdpx(250)])
    editView = mkSquareBtnEditView("ui/gameuiskin#hud_free_camera.svg")
    priority = Z_ORDER.BUTTON
  }

  courseGuns = {
    ctor = mkCirclePlaneCourseGuns
    defTransform = mkLBPos([hdpx(70), hdpx(-5)])
    editView = mkBigCircleBtnEditView("ui/gameuiskin#hud_aircraft_machine_gun.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisible = @(options) !optDoubleCourseGuns.has(options)
    options = [ optDoubleCourseGuns ]
  }

  cannons = {
    ctor = @() @() {
      watch = [hasCanon0, hasMGun0]
      children = hasCanon0.get()
        ? mkCirclePlaneCourseGunsSingle("ID_FIRE_CANNONS", Cannon0, hasCanon0, bigButtonSize, bigButtonImgSize)
        : mkCirclePlaneCourseGunsSingle("ID_FIRE_MGUNS", MGun0, hasMGun0, bigButtonSize, bigButtonImgSize)
    }
    defTransform = mkLBPos([hdpx(70), hdpx(-5)])
    editView = mkBigCircleBtnEditView("ui/gameuiskin#hud_aircraft_machine_gun.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisible = optDoubleCourseGuns.has
    options = [ optDoubleCourseGuns ]
  }

  miniguns = {
    ctor = @() mkCirclePlaneCourseGunsSingle("ID_FIRE_MGUNS",
      MGun0,
      Computed(@() hasCanon0.get() && hasMGun0.get()))
    defTransform = mkLBPos([hdpx(200), hdpx(-135)])
    editView = mkCircleBtnEditView("ui/gameuiskin#hud_aircraft_machine_gun.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
    isVisible = optDoubleCourseGuns.has
    options = [ optDoubleCourseGuns ]
  }
})
