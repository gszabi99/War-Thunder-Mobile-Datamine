from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/activeControls.nut" import isGamepad, isKeyboard
from "%appGlobals/unitConst.nut" import TANK
from "%rGui/compass/compass.nut" import mkCompass, mkCompassEditView
from "%rGui/compass/compassState.nut" import isCompassVisible
from "%rGui/components/movementArrows.nut" import moveArrowsView
from "%rGui/hud/actionBar/actionBarState.nut" import actionBarItems
from "%rGui/hud/actionBar/actionType.nut" import AB_PRIMARY_WEAPON, AB_PRIMARY_WEAPON_EXTRA, AB_SECONDARY_WEAPON,
  AB_SPECIAL_WEAPON, AB_MACHINE_GUN, AB_FIREWORK, AB_TOOLKIT
from "%rGui/hud/bullets/bulletButton.nut" import bulletMainButton, bulletExtraButton
from "%rGui/hud/bullets/bulletSelectorCircle.nut" import mkSecGunWithBullets, mkSecGunWithBulletsEditView
from "%rGui/hud/bullets/hudUnitBulletsState.nut" import isFakeSecondary, isFakeSpecial, hasOnlyOneSideGroup,
  mainBulletInfoSec, extraBulletInfoSec, mainBulletCountSec, bulletsInfoSec, currentBulletNameSec, nextBulletNameSec,
  selectBulletSec, mainBulletInfoSpec, extraBulletInfoSpec, mainBulletCountSpec, extraBulletCountSec,
  extraBulletCountSpec, bulletsInfoSpec, currentBulletNameSpec, nextBulletNameSpec, selectBulletSpec
from "%rGui/hud/bullets/sideBulletButton.nut" import sideGunBulletMainButton, sideGunBulletExtraButton
from "%rGui/hud/buttons/actionButtonComps.nut" import mkActionItemEditView
from "%rGui/hud/buttons/cameraButtons.nut" import mkFreeCameraButton
from "%rGui/hud/buttons/circleTouchHudButtons.nut" import mkCircleTankPrimaryGun, mkCircleGroundMachineGun,
  mkCircleFireworkBtn, mkCircleTargetTrackingBtn, mkCircleZoomCtor, mkCircleBtnEditView, mkBigCircleBtnEditView,
  mkCountTextRight
from "%rGui/hud/buttons/repairButton.nut" import tankRrepairButtonCtor
import "%rGui/hud/buttons/winchButton.nut" as winchButton
from "%rGui/hud/components/moveIndicator.nut" import NEED_SHOW_POSE_INDICATOR, mkMoveIndicator,
  moveIndicatorTankEditView
from "%rGui/hud/components/tacticalMap.nut" import mkTacticalMapForHud, tacticalMapEditView, tacticalMapSize
from "%rGui/hud/crewRank.nut" import crewRankCtr, crewRankEditView, isVisibleCrewRank
from "%rGui/hud/fireworkState.nut" import fwVisibleInEditor, fwVisibleInBattle
from "%rGui/hud/groundMovementBlock.nut" import tankMoveStick, moveStickView, tankGamepadMoveBlock
from "%rGui/hud/hitCamera/hitCamera.nut" import hitCamera, hitCameraTankEditView
from "%rGui/hud/hudTouchButtonStyle.nut" import touchButtonSize
from "%rGui/hud/missionScore.nut" import missionScoreCtr, missionScoreEditView
from "%rGui/hud/myScores.nut" import mkMyPlace, mkMyPlaceUi, mkTankMyScores, mkMyScoresUi
from "%rGui/hud/scoreBoard.nut" import scoreBoardType, scoreBoardCfgByType
import "%rGui/hud/tankArrowsMovementBlock.nut" as tankArrowsMovementBlock
from "%rGui/hud/tankStateModule.nut" import mkDoll, dollEditView, mkSpeedText, speedTextEditView, mkCrewDebuffs,
  crewDebuffsEditView, mkTechDebuffs, techDebuffsEditView
from "%rGui/hud/voiceMsg/voiceMsgStick.nut" import voiceMsgStickBlock, voiceMsgStickView, isVoiceMsgStickVisibleInBattle
from "%rGui/hud/weaponsButtonsConfig.nut" import EII_EXTINGUISHER, EII_SMOKE_GRENADE, EII_SMOKE_SCREEN,
  EII_ARTILLERY_TARGET, EII_SPECIAL_UNIT_2, EII_SPECIAL_UNIT, EII_TOOLKIT_SPLIT, EII_MEDICALKIT
from "%rGui/hud/weaponsButtonsView.nut" import mkBulletEditView, mkRepairActionItem
from "%rGui/hudState.nut" import isUnitAlive, isPlayingReplay
import "%rGui/hudTuning/cfg/cfgHudCommon.nut" as cfgHudCommon
from "%rGui/hudTuning/cfg/cfgOptions.nut" import optTankMoveControlType, gearDownOnStopButtonTouch,
  optDoublePrimaryGuns, optDoubleRepairBtn, optSplitSideGunBullets, isBulletsRight, optBulletsRight
from "%rGui/hudTuning/cfg/hudTuningPkg.nut" import withActionBarButtonCtor, withAnyActionBarButtonCtor,
  withActionsButtonScaleCtor, withActionButtonScaleCtor, Z_ORDER, mkRBPos, mkLBPos, mkRTPos, mkLTPos, mkCBPos, mkCTPos
import "%rGui/hudTuning/cfg/initHudTuningCfg.nut" as initHudTuningCfg
from "%rGui/hudTuning/hudTuningBattleState.nut" import curUnitHudTuningOptions
import "%rGui/hudTuning/squareBtnEditView.nut" as mkSquareBtnEditView
from "%rGui/missionState.nut" import raceForceCannotShoot
from "%rGui/options/chooseMovementControls/groundMoveControlType.nut" import currentTankMoveCtrlType
from "%rGui/options/options/tankControlsOptions.nut" import currentTargetTrackingType
from "%rGui/radar/radar.nut" import radarHudWithOverlayCtor, radarHudEditView
from "%rGui/radar/radarState.nut" import showRadarOverMap, IsRadarVisible, IsRadarHudVisible, IsBScopeVisible
from "%rGui/radar/radarToggleButton.nut" import mkRadarToggleButton, mkRadarToggleButtonEditView


let isViewMoveArrows = Computed(@() currentTankMoveCtrlType.get() == "arrows")
let isBattleMoveArrows = Computed(@() (isViewMoveArrows.get() || isKeyboard.get()) && !isGamepad.get())
let isTargetTracking = Computed(@() !currentTargetTrackingType.get())
let hasMyScores = Computed(@() scoreBoardCfgByType?[scoreBoardType.get()].addMyScores)
let isRadarExist = Computed(@() IsBScopeVisible.get() && IsRadarVisible.get() && IsRadarHudVisible.get())
let notInReplay = Computed(@() !isPlayingReplay.get())

let actionBarInterval = isWidescreen ? 150 : 130
let actionBarTransform = @(idx, isBullet = false)
  mkRBPos([hdpx(-actionBarInterval * idx), isBullet ? 0 : hdpx(43)])
const tacticalMapPos = hdpx(155)

let hasDoubleChoiceSec = Computed(@() !isFakeSecondary.get() && hasOnlyOneSideGroup.get())
let hasDoubleChoiceSpec = Computed(@() !isFakeSpecial.get() && hasOnlyOneSideGroup.get())

let isSplitSideGun = Computed(@() optSplitSideGunBullets.has(curUnitHudTuningOptions.get()))
let hasSplitSingleSideGroup = Computed(@() isSplitSideGun.get() && hasOnlyOneSideGroup.get())
let hasDoubleChoiceSecOpt = Computed(@() !isSplitSideGun.get() && hasDoubleChoiceSec.get())
let hasDoubleChoiceSpecOpt = Computed(@() !isSplitSideGun.get() && hasDoubleChoiceSpec.get())
let curSecGunBulletsOrientation = Computed(@() isBulletsRight(curUnitHudTuningOptions.get(), "secondaryGun"))
let curSpecGunBulletsOrientation = Computed(@() isBulletsRight(curUnitHudTuningOptions.get(), "specialGun"))

return cfgHudCommon.__merge(initHudTuningCfg({
  primaryGun = withActionsButtonScaleCtor([AB_PRIMARY_WEAPON, AB_PRIMARY_WEAPON_EXTRA],
    @(a, aType, scale) mkCircleTankPrimaryGun(a, aType, scale, "btn_weapon_primary_alt", mkCountTextRight),
    {
      canHide = false
      defTransform = mkLBPos([0, hdpx(-420)])
      editView = mkBigCircleBtnEditView("ui/gameuiskin#hud_main_weapon_fire.svg")
      priority = Z_ORDER.BUTTON_PRIMARY
      options = [ optDoublePrimaryGuns ]
    })

  primaryExtraGun = withActionsButtonScaleCtor([AB_PRIMARY_WEAPON, AB_PRIMARY_WEAPON_EXTRA],
    mkCircleTankPrimaryGun,
    {
      canHide = false
      defTransform = mkRBPos([hdpx(-250), hdpx(-303)])
      editView = mkBigCircleBtnEditView("ui/gameuiskin#hud_main_weapon_fire.svg")
      priority = Z_ORDER.BUTTON_PRIMARY
      isVisible = @(options) optDoublePrimaryGuns.has(options)
      options = [ optDoublePrimaryGuns ]
    })

  secondaryGun = withActionButtonScaleCtor(AB_SECONDARY_WEAPON,
    mkSecGunWithBullets("ID_FIRE_GM_SECONDARY_GUN", AB_SECONDARY_WEAPON, "ui/gameuiskin#hud_main_weapon_fire.svg",
      mainBulletInfoSec, extraBulletInfoSec, mainBulletCountSec, extraBulletCountSec,
      bulletsInfoSec, currentBulletNameSec, nextBulletNameSec, @() selectBulletSec(0), @() selectBulletSec(1),
      hasDoubleChoiceSecOpt, curSecGunBulletsOrientation),
    {
      defTransform = mkRBPos([hdpx(-150), hdpx(-450)])
      editView = @(options) optSplitSideGunBullets.has(options)
        ? mkCircleBtnEditView("ui/gameuiskin#hud_main_weapon_fire.svg")
        : mkSecGunWithBulletsEditView("ui/gameuiskin#hud_main_weapon_fire.svg",
            isBulletsRight(options, "secondaryGun"))
      options = [optSplitSideGunBullets, optBulletsRight]
    })

  specialGun = withActionButtonScaleCtor(AB_SPECIAL_WEAPON,
    mkSecGunWithBullets("ID_FIRE_GM_SPECIAL_GUN", AB_SPECIAL_WEAPON, "ui/gameuiskin#icon_rocket_in_progress.svg",
      mainBulletInfoSpec, extraBulletInfoSpec, mainBulletCountSpec, extraBulletCountSpec,
      bulletsInfoSpec, currentBulletNameSpec, nextBulletNameSpec, @() selectBulletSpec(0), @() selectBulletSpec(1),
      hasDoubleChoiceSpecOpt, curSpecGunBulletsOrientation),
    {
      defTransform = mkRBPos([hdpx(-30), hdpx(-265)])
      editView = @(options) optSplitSideGunBullets.has(options)
        ? mkCircleBtnEditView("ui/gameuiskin#icon_rocket_in_progress.svg")
        : mkSecGunWithBulletsEditView("ui/gameuiskin#icon_rocket_in_progress.svg",
            isBulletsRight(options, "specialGun"))
      priority = Z_ORDER.BUTTON_PRIMARY
      options = [optSplitSideGunBullets, optBulletsRight]
    })

  machineGun = {
    ctor = @(scale) mkCircleGroundMachineGun("ID_FIRE_GM_MACHINE_GUN", Computed(@() actionBarItems.get()?[AB_MACHINE_GUN]), AB_MACHINE_GUN, scale)
    priority = Z_ORDER.BUTTON
    defTransform = mkRBPos([hdpx(-155), hdpx(-155)])
    editView = mkCircleBtnEditView("ui/gameuiskin#hud_aircraft_machine_gun.svg")
  }

  zoom = {
    ctor = mkCircleZoomCtor()
    defTransform = mkRBPos([hdpx(-426), hdpx(-188)])
    editView = mkCircleBtnEditView("ui/gameuiskin#hud_tank_binoculars.svg")
    isVisibleInBattle = Computed(@() !isPlayingReplay.get())
    priority = Z_ORDER.BUTTON
  }

  winch = {
    ctor = winchButton
    defTransform = mkLTPos([0, hdpx(100)])
    editView = mkSquareBtnEditView("ui/gameuiskin#hud_winch.svg")
    isVisibleInBattle = notInReplay
    priority = Z_ORDER.BUTTON
  }

  freeCameraButton = {
    ctor = mkFreeCameraButton
    defTransform = mkLTPos([hdpx(0), hdpx(240)])
    editView = mkSquareBtnEditView("ui/gameuiskin#hud_free_camera.svg")
    isVisibleInBattle = notInReplay
    priority = Z_ORDER.BUTTON
  }

  targetTrackingButton = {
    ctor = mkCircleTargetTrackingBtn
    defTransform = mkLBPos([hdpx(190), hdpx(-420)])
    editView = mkCircleBtnEditView("ui/gameuiskin#hud_tank_target_tracking.svg")
    isVisibleInEditor = isTargetTracking
    isVisibleInBattle = Computed(@() isTargetTracking.get() && !raceForceCannotShoot.get())
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

  sideGunBulletMain = {
    ctor = sideGunBulletMainButton
    defTransform = mkRBPos([hdpx(-actionBarInterval * 7) - (touchButtonSize * 0.1).tointeger(), hdpx(-150)])
    editView = mkBulletEditView("ui/gameuiskin#hud_ammo_ap1_he1.svg", 1, 0.8)
    priority = Z_ORDER.BUTTON
    isVisible = @(options) optSplitSideGunBullets.has(options)
    isVisibleInBattle = hasSplitSingleSideGroup
    options = [optSplitSideGunBullets]
  }

  sideGunBulletExtra = {
    ctor = sideGunBulletExtraButton
    defTransform = mkRBPos([hdpx(-actionBarInterval * 6) - (touchButtonSize * 0.1).tointeger(), hdpx(-150)])
    editView = mkBulletEditView("ui/gameuiskin#hud_ammo_ap1_he1.svg", 2, 0.8)
    priority = Z_ORDER.BUTTON
    isVisible = @(options) optSplitSideGunBullets.has(options)
    isVisibleInBattle = hasSplitSingleSideGroup
    options = [optSplitSideGunBullets]
  }

  voiceCmdStick = {
    ctor = voiceMsgStickBlock
    defTransform = mkRBPos([hdpx(5), hdpx(-130)])
    editView = voiceMsgStickView
    isVisibleInBattle = isVoiceMsgStickVisibleInBattle
    priority = Z_ORDER.STICK
  }

  moveStick = {
    canHide = false
    ctor = @(scale) @() {
      watch = isGamepad
      key = "tank_move_stick_zone"
      children = isGamepad.get() ? tankGamepadMoveBlock(scale) : tankMoveStick(scale)
    }
    defTransform = mkLBPos([0, 0])
    editView = moveStickView
    isVisibleInEditor = Computed(@() !isViewMoveArrows.get())
    isVisibleInBattle = Computed(@() !isBattleMoveArrows.get())
    priority = Z_ORDER.STICK
    options = [ optTankMoveControlType, gearDownOnStopButtonTouch ]
  }

  moveArrows = {
    canHide = false
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
    canHide = false
    ctor = hitCamera
    defTransform = mkRTPos([0, 0])
    editView = hitCameraTankEditView
    hideForDelayed = false
  }

  tacticalMap = {
    ctor = mkTacticalMapForHud
    defTransform = mkLTPos([tacticalMapPos, 0])
    editView = tacticalMapEditView
    isVisibleInBattle = Computed(@() !showRadarOverMap.get() || !isRadarExist.get())
    hideForDelayed = false
  }

  myPlace = {
    ctor = mkMyPlaceUi
    defTransform = isWidescreen ? mkCTPos([hdpx(340), 0]) : mkRTPos([-hdpx(90), hdpx(330)])
    editView = mkMyPlace(1)
    hideForDelayed = false
    isVisibleInBattle = hasMyScores
  }

  myScores = {
    ctor = mkMyScoresUi
    defTransform = isWidescreen ? mkCTPos([hdpx(430), 0]) : mkRTPos([0, hdpx(330)])
    editView = { children = mkTankMyScores(221) }
    hideForDelayed = false
    isVisibleInBattle = hasMyScores
  }

  doll = {
    canHide = false
    ctor = mkDoll
    defTransform = mkLBPos([hdpx(540), 0])
    editView = dollEditView
    isVisibleInBattle = notInReplay
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

  radarToggle = {
    ctor = mkRadarToggleButton
    defTransform = mkLTPos([tacticalMapPos + tacticalMapSize[0], 0])
    editView = mkRadarToggleButtonEditView
    priority = Z_ORDER.BUTTON
    isVisibleInBattle = isRadarExist
  }

  radarHud = {
    ctor = radarHudWithOverlayCtor
    defTransform = mkLTPos([tacticalMapPos, 0])
    editView = radarHudEditView
    priority = Z_ORDER.BUTTON
    isVisibleInBattle = Computed(@() isRadarExist.get() && showRadarOverMap.get())
  }

  compass = {
    ctor = mkCompass
    defTransform = mkCTPos([0, hdpx(120)])
    editView = mkCompassEditView
    priority = Z_ORDER.BUTTON
    isVisibleInBattle = Computed(@() isCompassVisible && isRadarExist.get())
  }

}.filter(@(v) v != null)))
