from "%globalsDarg/darg_library.nut" import *
let { TANK } = require("%appGlobals/unitConst.nut")
let { AB_PRIMARY_WEAPON, AB_SECONDARY_WEAPON, AB_SPECIAL_WEAPON, AB_MACHINE_GUN
} = require("%rGui/hud/actionBar/actionType.nut")
let { EII_EXTINGUISHER, EII_TOOLKIT, EII_SMOKE_GRENADE, EII_SMOKE_SCREEN,
  EII_ARTILLERY_TARGET, EII_SPECIAL_UNIT_2, EII_SPECIAL_UNIT
} = require("%rGui/hud/weaponsButtonsConfig.nut")
let cfgHudCommon = require("cfgHudCommon.nut")
let { mkCircleTankPrimaryGun, mkCircleTankSecondaryGun, mkCircleTankMachineGun, mkCircleZoom,
  mkCircleBtnEditView, mkBigCircleBtnEditView, mkCountTextRight, mkCircleTargetTrackingBtn
} = require("%rGui/hud/buttons/circleTouchHudButtons.nut")
let { withActionButtonCtor, withActionBarButtonCtor, withAnyActionBarButtonCtor,
  mkRBPos, mkLBPos, mkRTPos, mkLTPos, mkCBPos } = require("hudTuningPkg.nut")
let { tankMoveStick, tankMoveStickView, tankGamepadMoveBlock
} = require("%rGui/hud/tankMovementBlock.nut")
let tankArrowsMovementBlock = require("%rGui/hud/tankArrowsMovementBlock.nut")
let { currentTankMoveCtrlType } = require("%rGui/options/chooseMovementControls/tankMoveControlType.nut")
let { currentTargetTrackingType } = require("%rGui/options/options/tankControlsOptions.nut")
let { isGamepad, isKeyboard } = require("%rGui/activeControls.nut")
let { moveArrowsView } = require("%rGui/components/movementArrows.nut")
let { hitCamera, hitCameraTankEditView } = require("%rGui/hud/hitCamera/hitCamera.nut")
let { tacticalMap, tacticalMapEditView } = require("%rGui/hud/components/tacticalMap.nut")
let winchButton = require("%rGui/hud/buttons/winchButton.nut")
let { doll, dollEditView, speedText, speedTextEditView, crewDebuffs, crewDebuffsEditView,
  techDebuffs, techDebuffsEditView } = require("%rGui/hud/tankStateModule.nut")
let { moveIndicator, moveIndicatorTankEditView } = require("%rGui/hud/components/moveIndicator.nut")
let mkFreeCameraButton = require("%rGui/hud/buttons/freeCameraButton.nut")
let mkSquareBtnEditView = require("%rGui/hudTuning/squareBtnEditView.nut")
let { bulletMainButton, bulletExtraButton } = require("%rGui/hud/bullets/bulletButton.nut")
let { mkBulletEditView } = require("%rGui/hud/weaponsButtonsView.nut")
let { DBGLEVEL } = require("dagor.system")

let isViewMoveArrows = Computed(@() currentTankMoveCtrlType.value == "arrows")
let isBattleMoveArrows = Computed(@() (isViewMoveArrows.value || isKeyboard.value) && !isGamepad.value)
let isTargetTracking = Computed(@() !currentTargetTrackingType.value)

let aspectRatio = sw(100) / sh(100)
let actionBarInterval = aspectRatio < 2 ? 130 : 150
let actionBarTransform = @(idx, isBullet = false)
  mkRBPos([hdpx(-actionBarInterval * idx), isBullet ? 0 : hdpx(43)])

return {
  primaryGunRight = withActionButtonCtor(AB_PRIMARY_WEAPON, mkCircleTankPrimaryGun,
    {
      defTransform = mkRBPos([hdpx(-250), hdpx(-303)])
      editView = mkBigCircleBtnEditView("ui/gameuiskin#hud_main_weapon_fire.svg")
    })

  primaryGunLeft = withActionButtonCtor(AB_PRIMARY_WEAPON,
    @(a) mkCircleTankPrimaryGun(a, "btn_weapon_primary_alt", mkCountTextRight),
    {
      defTransform = mkLBPos([0, hdpx(-420)])
      editView = mkBigCircleBtnEditView("ui/gameuiskin#hud_main_weapon_fire.svg")
    })

  secondaryGun = withActionButtonCtor(AB_SECONDARY_WEAPON,
    mkCircleTankSecondaryGun("ID_FIRE_GM_SECONDARY_GUN", "ui/gameuiskin#hud_main_weapon_fire.svg"),
    {
      defTransform = mkRBPos([hdpx(-81), hdpx(-425)])
      editView = mkCircleBtnEditView("ui/gameuiskin#hud_main_weapon_fire.svg")
    })

  specialGun = withActionButtonCtor(AB_SPECIAL_WEAPON,
    mkCircleTankSecondaryGun("ID_FIRE_GM_SPECIAL_GUN", "ui/gameuiskin#icon_rocket_in_progress.svg"),
    {
      defTransform = mkRBPos([hdpx(-28), hdpx(-265)])
      editView = mkCircleBtnEditView("ui/gameuiskin#icon_rocket_in_progress.svg")
    })

  machineGun = withActionButtonCtor(AB_MACHINE_GUN, mkCircleTankMachineGun,
    {
      defTransform = mkRBPos([hdpx(-155), hdpx(-155)])
      editView = mkCircleBtnEditView("ui/gameuiskin#hud_aircraft_machine_gun.svg")
    })

  zoom = {
    ctor = mkCircleZoom
    defTransform = mkRBPos([hdpx(-426), hdpx(-188)])
    editView = mkCircleBtnEditView("ui/gameuiskin#hud_tank_binoculars.svg")
  }

  winch = {
    ctor = @() winchButton
    defTransform = mkLTPos([0, hdpx(100)])
    editView = mkSquareBtnEditView("ui/gameuiskin#hud_winch.svg")
  }

  freeCameraButton = {
    ctor = mkFreeCameraButton
    defTransform = mkLTPos([hdpx(0), hdpx(240)])
    editView = mkSquareBtnEditView("ui/gameuiskin#hud_free_camera.svg")
  }

  targetTrackingButton = {
    ctor = mkCircleTargetTrackingBtn
    defTransform = mkLBPos([hdpx(190), hdpx(-420)])
    editView = mkBigCircleBtnEditView("ui/gameuiskin#hud_tank_target_tracking.svg")
    isVisibleInEditor = isTargetTracking
    isVisibleInBattle = isTargetTracking
  }

  abExtinguisher = withActionBarButtonCtor(EII_EXTINGUISHER, TANK,
    { defTransform = actionBarTransform(0) })
  abToolkit = withActionBarButtonCtor(EII_TOOLKIT, TANK,
    { defTransform = actionBarTransform(1) })
  abSmokeGrenade = withAnyActionBarButtonCtor([ EII_SMOKE_GRENADE, EII_SMOKE_SCREEN ], TANK,
    { defTransform = actionBarTransform(2) })
  abArtilleryTarget = withActionBarButtonCtor(EII_ARTILLERY_TARGET, TANK,
    { defTransform = actionBarTransform(3) })
  abSpecialUnit2 = withActionBarButtonCtor(EII_SPECIAL_UNIT_2, TANK,
    { defTransform = actionBarTransform(4) })
  abSpecialUnit = withActionBarButtonCtor(EII_SPECIAL_UNIT, TANK,
    { defTransform = actionBarTransform(5) })

  bulletMain = {
    ctor = @() bulletMainButton
    defTransform = actionBarTransform(6, true)
    editView = mkBulletEditView("ui/gameuiskin#hud_ammo_ap1_he1.svg", 1)
  }

  bulletExtra = {
    ctor = @() bulletExtraButton
    defTransform = actionBarTransform(7, true)
    editView = mkBulletEditView("ui/gameuiskin#hud_ammo_ap1_he1.svg", 2)
  }

  moveStick = {
    ctor = @() @() {
      watch = isGamepad
      key = "tank_move_stick_zone"
      children = isGamepad.value ? tankGamepadMoveBlock : tankMoveStick
    }
    defTransform = mkLBPos([0, 0])
    editView = tankMoveStickView
    isVisibleInEditor = Computed(@() !isViewMoveArrows.value)
    isVisibleInBattle = Computed(@() !isBattleMoveArrows.value)
  }

  moveArrows = {
    ctor = @() {
      key = "tank_move_stick_zone"
      children = tankArrowsMovementBlock
    }
    defTransform = mkLBPos([0, 0])
    editView = moveArrowsView
    isVisibleInEditor = isViewMoveArrows
    isVisibleInBattle = isBattleMoveArrows
  }

  hitCamera = {
    ctor = @() hitCamera
    defTransform = mkRTPos([0, 0])
    editView = hitCameraTankEditView
    hideForDelayed = false
  }

  tacticalMap = {
    ctor = @() tacticalMap
    defTransform = mkLTPos([hdpx(155), 0])
    editView = tacticalMapEditView
    hideForDelayed = false
  }

  doll = {
    ctor = @() doll
    defTransform = mkLBPos([hdpx(520), 0])
    editView = dollEditView
    hideForDelayed = false
  }

  moveIndicator = DBGLEVEL > 0
    ? {
        ctor = @() moveIndicator
        defTransform = mkCBPos([0, -sh(20)])
        editView = moveIndicatorTankEditView
        hideForDelayed = false
      }
  : null

  speedText = {
    ctor = @() speedText
    defTransform = mkLBPos([hdpx(420), hdpx(-105)])
    editView = speedTextEditView
    hideForDelayed = false
  }

  crewDebuffs = {
    ctor = @() crewDebuffs
    defTransform = mkLBPos([hdpx(365), hdpx(-50)])
    editView = crewDebuffsEditView
    hideForDelayed = false
  }

  techDebuffs = {
    ctor = @() techDebuffs
    defTransform = mkLBPos([hdpx(255), 0])
    editView = techDebuffsEditView
    hideForDelayed = false
  }
}.__update(cfgHudCommon).filter(@(v) v != null)
