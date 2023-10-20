from "%globalsDarg/darg_library.nut" import *
let { mkZoomButton, mkLockButton, mkWeaponryItemSelfAction, mkWeaponryContinuousSelfAction, mkSimpleButton, mkGroupAttackButton
} = require("%rGui/hud/weaponsButtonsView.nut")
let { mkWeaponBtnEditView } = require("%rGui/hudTuning/weaponBtnEditView.nut")
let { mkLBPos, mkLTPos, mkRBPos, mkRTPos, mkCTPos,
  weaponryButtonCtor, weaponryButtonsGroupCtor, weaponryButtonsChainedCtor } = require("hudTuningPkg.nut")
let { touchButtonSize } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkSimpleChainIcon } = require("%rGui/hud/weaponryBlockImpl.nut")
let {
  aircraftMovement,
  aircraftIndicators,
  aircraftMovementEditView,
  aircraftIndicatorsEditView
} = require("%rGui/hud/aircraftMovementBlock.nut")
let { aircraftRadarEditView, aircraftRadar } = require("%rGui/hud/aircraftRadar.nut")
let cfgHudCommon = require("cfgHudCommon.nut")
let { hitCamera, hitCameraCommonEditView } = require("%rGui/hud/hitCamera/hitCamera.nut")
let mkFreeCameraButton = require("%rGui/hud/buttons/freeCameraButton.nut")
let mkSquareBtnEditView = require("%rGui/hudTuning/squareBtnEditView.nut")
let { mkMyPlace, myPlaceUi, mkMyScores, myScoresUi } = require("%rGui/hud/myScores.nut")
let { doll, dollEditView } = require("%rGui/hud/aircraftStateModule.nut")

let isMyScoresFitTop = saRatio >= 1.92

return cfgHudCommon.__merge({
  bomb = weaponryButtonCtor("ID_BOMBS", mkWeaponryItemSelfAction,
    {
      defTransform = mkLBPos([hdpx(108), hdpx(-220)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_bomb.svg")
    })

  rocket = weaponryButtonCtor("ID_ROCKETS", mkWeaponryItemSelfAction,
    {
      defTransform = mkLBPos([hdpx(108), hdpx(-5)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_rb_rocket.svg", 0.8)
    })

  guns = weaponryButtonsChainedCtor(["ID_FIRE_MGUNS", "ID_FIRE_CANNONS"], mkWeaponryContinuousSelfAction,
    {
      defTransform = mkLBPos([hdpx(216), hdpx(-5)])
      editView = {
        size = [touchButtonSize * 2, touchButtonSize * 2]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          mkWeaponBtnEditView("ui/gameuiskin#hud_aircraft_machine_gun.svg", 1,
            { pos = [- touchButtonSize * 0.5, - touchButtonSize * 0.5] })
          mkSimpleChainIcon
          mkWeaponBtnEditView("ui/gameuiskin#hud_aircraft_canons.svg", 1,
            { pos = [touchButtonSize * 0.5, touchButtonSize * 0.5] })
        ]
      }
    })

  torpedo = weaponryButtonCtor("ID_TORPEDOES", mkWeaponryItemSelfAction,
    {
      defTransform = mkLBPos([hdpx(0), hdpx(-113)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_torpedo.svg", 0.8)
    })

  lock = weaponryButtonCtor("ID_LOCK_TARGET", mkLockButton,
    {
      defTransform = mkLBPos([hdpx(325), hdpx(-220)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_target_tracking_off.svg", 1.05)
    })

  zoom = weaponryButtonCtor("ID_ZOOM", mkZoomButton,
    {
      defTransform = mkLBPos([hdpx(216), hdpx(-330)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_binoculars.svg", 1.34)
    })

  change = weaponryButtonCtor("ID_WTM_AIRCRAFT_CHANGE", mkSimpleButton,
    {
      defTransform = mkLBPos([hdpx(541), hdpx(-5)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_aircraft_fighter.svg")
    })

  groupAttack = weaponryButtonCtor("ID_WTM_AIRCRAFT_GROUP_ATTACK", mkGroupAttackButton,
    {
      defTransform = mkLBPos([hdpx(541), hdpx(-225)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_aircraft_fighter.svg")
    })

  groupReturn = weaponryButtonCtor("ID_WTM_AIRCRAFT_RETURN", mkSimpleButton,
    {
      defTransform = mkLBPos([hdpx(431), hdpx(-335)])
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
    defTransform = isMyScoresFitTop ? mkCTPos([hdpx(290), 0]) : mkRTPos([-hdpx(90), hdpx(260)])
    editView = mkMyPlace(1)
    hideForDelayed = false
  }

  myScores = {
    ctor = @() myScoresUi
    defTransform = isMyScoresFitTop ? mkCTPos([hdpx(380), 0]) : mkRTPos([0, hdpx(260)])
    editView = mkMyScores(22100)
    hideForDelayed = false
  }

  doll = {
    ctor = @() doll
    defTransform = mkLBPos([hdpx(580), hdpx(30)])
    editView = dollEditView
    hideForDelayed = false
  }

  movement = {
    ctor = @() aircraftMovement
    defTransform = mkRBPos([hdpx(-36), 0])
    editView = aircraftMovementEditView
  }

  indicators = {
    ctor = @() aircraftIndicators
    defTransform = mkRBPos([0, hdpx(-290)])
    editView = aircraftIndicatorsEditView
    hideForDelayed = false
  }

  freeCameraButton = {
    ctor = mkFreeCameraButton
    defTransform = mkLTPos([hdpx(0), hdpx(450)])
    editView = mkSquareBtnEditView("ui/gameuiskin#hud_free_camera.svg")
  }
})
