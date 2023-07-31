from "%globalsDarg/darg_library.nut" import *
let { mkZoomButton, mkLockButton, mkWeaponryItemSelfAction, mkWeaponryContinuousSelfAction, mkSimpleButton
} = require("%rGui/hud/weaponsButtonsView.nut")
let { mkWeaponBtnEditView } = require("%rGui/hudTuning/weaponBtnEditView.nut")
let { mkLBPos, mkLTPos, mkRBPos, mkRTPos,
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
})
