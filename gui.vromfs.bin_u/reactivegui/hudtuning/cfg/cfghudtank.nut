from "%globalsDarg/darg_library.nut" import *
let { TANK } = require("%appGlobals/unitConst.nut")
let { AB_PRIMARY_WEAPON, AB_SECONDARY_WEAPON, AB_SPECIAL_WEAPON, AB_MACHINE_GUN, AB_FIREWORK, AB_TOOLKIT
} = require("%rGui/hud/actionBar/actionType.nut")
let { actionBarItems } = require("%rGui/hud/actionBar/actionBarState.nut")
let { EII_EXTINGUISHER, EII_SMOKE_GRENADE, EII_SMOKE_SCREEN, EII_ARTILLERY_TARGET,
  EII_SPECIAL_UNIT_2, EII_SPECIAL_UNIT, EII_TOOLKIT_SPLIT, EII_MEDICALKIT
} = require("%rGui/hud/weaponsButtonsConfig.nut")
let cfgHudCommon = require("%rGui/hudTuning/cfg/cfgHudCommon.nut")
let { mkCircleTankPrimaryGun, mkCircleTankSecondaryGun, mkCircleTankMachineGun, mkCircleZoomCtor,
  mkCircleBtnEditView, mkBigCircleBtnEditView, mkCountTextRight, mkCircleTargetTrackingBtn,
  mkCircleFireworkBtn
} = require("%rGui/hud/buttons/circleTouchHudButtons.nut")
let { withActionBarButtonCtor, withAnyActionBarButtonCtor,
  withActionButtonScaleCtor, Z_ORDER, mkRBPos, mkLBPos, mkRTPos, mkLTPos, mkCBPos, mkCTPos
} = require("%rGui/hudTuning/cfg/hudTuningPkg.nut")
let { tankMoveStick, tankMoveStickView, tankGamepadMoveBlock
} = require("%rGui/hud/tankMovementBlock.nut")
let { voiceMsgStickBlock, voiceMsgStickView, isVoiceMsgStickVisibleInBattle
} = require("%rGui/hud/voiceMsg/voiceMsgStick.nut")
let tankArrowsMovementBlock = require("%rGui/hud/tankArrowsMovementBlock.nut")
let { currentTankMoveCtrlType } = require("%rGui/options/chooseMovementControls/tankMoveControlType.nut")
let { currentTargetTrackingType } = require("%rGui/options/options/tankControlsOptions.nut")
let { isGamepad, isKeyboard } = require("%appGlobals/activeControls.nut")
let { moveArrowsView } = require("%rGui/components/movementArrows.nut")
let { hitCamera, hitCameraTankEditView } = require("%rGui/hud/hitCamera/hitCamera.nut")
let { mkTacticalMapForHud, tacticalMapEditView } = require("%rGui/hud/components/tacticalMap.nut")
let winchButton = require("%rGui/hud/buttons/winchButton.nut")
let { mkDoll, dollEditView, mkSpeedText, speedTextEditView, mkCrewDebuffs, crewDebuffsEditView,
  mkTechDebuffs, techDebuffsEditView } = require("%rGui/hud/tankStateModule.nut")
let { NEED_SHOW_POSE_INDICATOR, mkMoveIndicator, moveIndicatorTankEditView
} = require("%rGui/hud/components/moveIndicator.nut")
let { mkFreeCameraButton } = require("%rGui/hud/buttons/cameraButtons.nut")
let mkSquareBtnEditView = require("%rGui/hudTuning/squareBtnEditView.nut")
let { bulletMainButton, bulletExtraButton } = require("%rGui/hud/bullets/bulletButton.nut")
let { mkBulletEditView, mkRepairActionItem } = require("%rGui/hud/weaponsButtonsView.nut")
let { mkMyPlace, mkMyPlaceUi, mkTankMyScores, mkMyScoresUi } = require("%rGui/hud/myScores.nut")
let { scoreBoardType, scoreBoardCfgByType } = require("%rGui/hud/scoreBoard.nut")
let { fwVisibleInEditor, fwVisibleInBattle } = require("%rGui/hud/fireworkState.nut")
let { missionScoreCtr, missionScoreEditView } = require("%rGui/hud/missionScore.nut")
let { optTankMoveControlType, gearDownOnStopButtonTouch, optDoublePrimaryGuns,
  optDoubleRepairBtn
} = require("%rGui/hudTuning/cfg/cfgOptions.nut")
let { tankRrepairButtonCtor } = require("%rGui/hud/buttons/repairButton.nut")
let { mkActionItemEditView } = require("%rGui/hud/buttons/actionButtonComps.nut")
let { isUnitAlive } = require("%rGui/hudState.nut")
let { curUnitHudTuningOptions } = require("%rGui/hudTuning/hudTuningBattleState.nut")
let { crewRankCtr, crewRankEditView, isVisibleCrewRank } = require("%rGui/hud/crewRank.nut")

let isViewMoveArrows = Computed(@() currentTankMoveCtrlType.value == "arrows")
let isBattleMoveArrows = Computed(@() (isViewMoveArrows.get() || isKeyboard.get()) && !isGamepad.get())
let isTargetTracking = Computed(@() !currentTargetTrackingType.get())
let hasMyScores = Computed(@() scoreBoardCfgByType?[scoreBoardType.get()].addMyScores)

let actionBarInterval = isWidescreen ? 150 : 130
let actionBarTransform = @(idx, isBullet = false)
  mkRBPos([hdpx(-actionBarInterval * idx), isBullet ? 0 : hdpx(43)])

return {
  primaryGun = withActionButtonScaleCtor(AB_PRIMARY_WEAPON,
    @(a, scale) mkCircleTankPrimaryGun(AB_PRIMARY_WEAPON)(a, scale, "btn_weapon_primary_alt", mkCountTextRight),
    {
      defTransform = mkLBPos([0, hdpx(-420)])
      editView = mkBigCircleBtnEditView("ui/gameuiskin#hud_main_weapon_fire.svg")
      priority = Z_ORDER.BUTTON_PRIMARY
      options = [ optDoublePrimaryGuns ]
    })

  primaryExtraGun = withActionButtonScaleCtor(AB_PRIMARY_WEAPON, mkCircleTankPrimaryGun(AB_PRIMARY_WEAPON),
    {
      defTransform = mkRBPos([hdpx(-250), hdpx(-303)])
      editView = mkBigCircleBtnEditView("ui/gameuiskin#hud_main_weapon_fire.svg")
      priority = Z_ORDER.BUTTON_PRIMARY
      isVisible = @(options) optDoublePrimaryGuns.has(options)
      options = [ optDoublePrimaryGuns ]
    })

  secondaryGun = withActionButtonScaleCtor(AB_SECONDARY_WEAPON,
    mkCircleTankSecondaryGun("ID_FIRE_GM_SECONDARY_GUN", AB_SECONDARY_WEAPON, "ui/gameuiskin#hud_main_weapon_fire.svg"),
    {
      defTransform = mkRBPos([hdpx(-81), hdpx(-425)])
      editView = mkCircleBtnEditView("ui/gameuiskin#hud_main_weapon_fire.svg")
    })

  specialGun = withActionButtonScaleCtor(AB_SPECIAL_WEAPON,
    mkCircleTankSecondaryGun("ID_FIRE_GM_SPECIAL_GUN", AB_SPECIAL_WEAPON, "ui/gameuiskin#icon_rocket_in_progress.svg"),
    {
      defTransform = mkRBPos([hdpx(-28), hdpx(-265)])
      editView = mkCircleBtnEditView("ui/gameuiskin#icon_rocket_in_progress.svg")
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  machineGun = {
    ctor = @(scale) mkCircleTankMachineGun(Computed(@() actionBarItems.get()?[AB_MACHINE_GUN]), AB_MACHINE_GUN, scale)
    priority = Z_ORDER.BUTTON
    defTransform = mkRBPos([hdpx(-155), hdpx(-155)])
    editView = mkCircleBtnEditView("ui/gameuiskin#hud_aircraft_machine_gun.svg")
  }

  zoom = {
    ctor = mkCircleZoomCtor()
    defTransform = mkRBPos([hdpx(-426), hdpx(-188)])
    editView = mkCircleBtnEditView("ui/gameuiskin#hud_tank_binoculars.svg")
    priority = Z_ORDER.BUTTON
  }

  winch = {
    ctor = winchButton
    defTransform = mkLTPos([0, hdpx(100)])
    editView = mkSquareBtnEditView("ui/gameuiskin#hud_winch.svg")
    priority = Z_ORDER.BUTTON
  }

  freeCameraButton = {
    ctor = mkFreeCameraButton
    defTransform = mkLTPos([hdpx(0), hdpx(240)])
    editView = mkSquareBtnEditView("ui/gameuiskin#hud_free_camera.svg")
    priority = Z_ORDER.BUTTON
  }

  targetTrackingButton = {
    ctor = mkCircleTargetTrackingBtn
    defTransform = mkLBPos([hdpx(190), hdpx(-420)])
    editView = mkCircleBtnEditView("ui/gameuiskin#hud_tank_target_tracking.svg")
    isVisibleInEditor = isTargetTracking
    isVisibleInBattle = isTargetTracking
    priority = Z_ORDER.BUTTON
  }

  abExtinguisher = withActionBarButtonCtor(EII_EXTINGUISHER, TANK,
    {
      defTransform = actionBarTransform(0),
      shouldShowDisabled = true
      isVisibleInBattle = isUnitAlive
    })

  abToolkit = {
    ctor = @(scale) function() {
      let needSplitRepairBtn = Computed(@() optDoubleRepairBtn.has(curUnitHudTuningOptions.get()))
      let actionItem = Computed(@() actionBarItems.get()?[AB_TOOLKIT])
      return {
        watch = needSplitRepairBtn
        children = needSplitRepairBtn.get()
          ? @() {
            watch = actionItem
            children = mkRepairActionItem(EII_TOOLKIT_SPLIT, actionItem.get(), scale)
          }
          : tankRrepairButtonCtor(scale)
      }
    }
    defTransform = actionBarTransform(1)
    editView = @(opt) function() {
      let image = optDoubleRepairBtn.has(opt)
        ? "ui/gameuiskin#hud_consumable_toolkit.svg"
        : "ui/gameuiskin#hud_consumable_repair.svg"
      return mkActionItemEditView(image)
    }
    priority = Z_ORDER.STICK
    isVisibleInBattle = isUnitAlive
    options = [ optDoubleRepairBtn ]
  }

  medical = withActionBarButtonCtor(EII_MEDICALKIT, TANK, {
    defTransform = mkRBPos([hdpx(-300), hdpx(-130)])
    priority = Z_ORDER.STICK
    isVisible = @(options) optDoubleRepairBtn.has(options)
    isVisibleInBattle = isUnitAlive
    options = [ optDoubleRepairBtn ]
  })

  abSmokeGrenade = withAnyActionBarButtonCtor([ EII_SMOKE_GRENADE, EII_SMOKE_SCREEN ], TANK,
    { defTransform = actionBarTransform(2) })
  abArtilleryTarget = withActionBarButtonCtor(EII_ARTILLERY_TARGET, TANK,
    { defTransform = actionBarTransform(3) })
  abSpecialUnit2 = withActionBarButtonCtor(EII_SPECIAL_UNIT_2, TANK,
    { defTransform = actionBarTransform(4) })
  abSpecialUnit = withActionBarButtonCtor(EII_SPECIAL_UNIT, TANK,
    { defTransform = actionBarTransform(5) })

  firework = withActionButtonScaleCtor(AB_FIREWORK, mkCircleFireworkBtn(AB_FIREWORK),
    {
      defTransform = mkRBPos([hdpx(-240), hdpx(-490)])
      editView = mkCircleBtnEditView("ui/gameuiskin#hud_ammo_fireworks.svg")
      isVisibleInEditor = fwVisibleInEditor
      isVisibleInBattle = fwVisibleInBattle
    })

  bulletMain = {
    ctor = bulletMainButton
    defTransform = actionBarTransform(7, true)
    editView = mkBulletEditView("ui/gameuiskin#hud_ammo_ap1_he1.svg", 1)
    priority = Z_ORDER.BUTTON
  }

  bulletExtra = {
    ctor = bulletExtraButton
    defTransform = actionBarTransform(6, true)
    editView = mkBulletEditView("ui/gameuiskin#hud_ammo_ap1_he1.svg", 2)
    priority = Z_ORDER.BUTTON
  }

  voiceCmdStick = {
    ctor = voiceMsgStickBlock
    defTransform = mkRBPos([hdpx(5), hdpx(-130)])
    editView = voiceMsgStickView
    isVisibleInBattle = isVoiceMsgStickVisibleInBattle
    priority = Z_ORDER.STICK
  }

  moveStick = {
    ctor = @(scale) @() {
      watch = isGamepad
      key = "tank_move_stick_zone"
      children = isGamepad.get() ? tankGamepadMoveBlock(scale) : tankMoveStick(scale)
    }
    defTransform = mkLBPos([0, 0])
    editView = tankMoveStickView
    isVisibleInEditor = Computed(@() !isViewMoveArrows.get())
    isVisibleInBattle = Computed(@() !isBattleMoveArrows.get())
    priority = Z_ORDER.STICK
    options = [ optTankMoveControlType, gearDownOnStopButtonTouch ]
  }

  moveArrows = {
    ctor = @(scale) {
      key = "tank_move_stick_zone"
      children = tankArrowsMovementBlock(scale)
    }
    defTransform = mkLBPos([0, 0])
    editView = moveArrowsView
    isVisibleInEditor = isViewMoveArrows
    isVisibleInBattle = isBattleMoveArrows
    priority = Z_ORDER.STICK
    options = [ optTankMoveControlType, gearDownOnStopButtonTouch ]
  }

  chatLogAndKillLog = cfgHudCommon.chatLogAndKillLog.__merge({ defTransform = mkLTPos([hdpx(155), hdpx(360)]) })

  hitCamera = {
    ctor = hitCamera
    defTransform = mkRTPos([0, 0])
    editView = hitCameraTankEditView
    hideForDelayed = false
  }

  tacticalMap = {
    ctor = mkTacticalMapForHud
    defTransform = mkLTPos([hdpx(155), 0])
    editView = tacticalMapEditView
    hideForDelayed = false
  }

  myPlace = {
    ctor = mkMyPlaceUi
    defTransform = isWidescreen ? mkCTPos([hdpx(290), 0]) : mkRTPos([-hdpx(90), hdpx(330)])
    editView = mkMyPlace(1)
    hideForDelayed = false
    isVisibleInBattle = hasMyScores
  }

  myScores = {
    ctor = mkMyScoresUi
    defTransform = isWidescreen ? mkCTPos([hdpx(380), 0]) : mkRTPos([0, hdpx(330)])
    editView = { children = mkTankMyScores(221) }
    hideForDelayed = false
    isVisibleInBattle = hasMyScores
  }

  doll = {
    ctor = mkDoll
    defTransform = mkLBPos([hdpx(540), 0])
    editView = dollEditView
    hideForDelayed = false
  }

  moveIndicator = NEED_SHOW_POSE_INDICATOR
    ? {
        ctor = mkMoveIndicator
        defTransform = mkCBPos([0, -sh(20)])
        editView = moveIndicatorTankEditView
        hideForDelayed = false
      }
  : null

  speedText = {
    ctor = mkSpeedText
    defTransform = mkLBPos([hdpx(420), hdpx(-105)])
    editView = speedTextEditView
    hideForDelayed = false
  }

  crewDebuffs = {
    ctor = mkCrewDebuffs
    defTransform = mkLBPos([hdpx(365), hdpx(-50)])
    editView = crewDebuffsEditView
    hideForDelayed = false
  }

  techDebuffs = {
    ctor = mkTechDebuffs
    defTransform = mkLBPos([hdpx(210), 0])
    editView = techDebuffsEditView
    hideForDelayed = false
  }

  missionScore = {
    ctor = missionScoreCtr
    defTransform = mkRTPos([hdpx(80), hdpx(20)])
    editView = missionScoreEditView
  }

  crewRank = {
    ctor = crewRankCtr
    defTransform = mkLBPos([hdpx(540), -hdpx(215)])
    editView = crewRankEditView
    isVisibleInBattle = isVisibleCrewRank
    isVisibleInEditor = isVisibleCrewRank
  }
}.__update(cfgHudCommon).filter(@(v) v != null)
