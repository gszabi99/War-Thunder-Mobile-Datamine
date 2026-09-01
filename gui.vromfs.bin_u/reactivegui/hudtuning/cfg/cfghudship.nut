from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/permissions.nut" import has_strategy_mode
from "%appGlobals/unitConst.nut" import SHIP
from "%rGui/components/movementArrows.nut" import moveArrowsViewWithMode
from "%rGui/hud/buttons/rhombTouchHudButtons.nut" import mkRhombFireworkBtn, mkRhombZoomButton, mkSupportPlaneBtn,
  mkAntiairButton, mkRhombSimpleActionBtn
from "%rGui/hud/fireworkState.nut" import fwVisibleInEditor, fwVisibleInBattle
import "%rGui/hud/shipMovementBlock.nut" as shipMovementBlock
import "%rGui/hud/supportPlaneConfig.nut" as supportPlaneConfig
from "%rGui/hud/voiceMsg/voiceMsgStick.nut" import voiceMsgStickBlock, voiceMsgStickView, isVoiceMsgStickVisibleInBattle
from "%rGui/hud/weaponsButtonsConfig.nut" import EII_SMOKE_SCREEN, EII_TOOLKIT, EII_ELECTRONIC_WARFARE, EII_IRCM,
  EII_CIWS
from "%rGui/hudState.nut" import isPlayingReplay
import "%rGui/hudTuning/cfg/cfgHudCommon.nut" as cfgHudCommon
import "%rGui/hudTuning/cfg/cfgHudCommonNaval.nut" as cfgHudCommonNaval
from "%rGui/hudTuning/cfg/hudTuningPkg.nut" import Z_ORDER, mkRBPos, mkLBPos, weaponryButtonDynamicCtor,
  withActionBarButtonCtor, withActionButtonScaleCtor
import "%rGui/hudTuning/cfg/initHudTuningCfg.nut" as initHudTuningCfg
from "%rGui/hudTuning/weaponBtnEditView.nut" import mkWeaponBtnEditView, mkNumberedWeaponEditView


let { AB_FIREWORK, AB_SUPPORT_PLANE, AB_SUPPORT_PLANE_2, AB_SUPPORT_PLANE_3,



} = require("%rGui/hud/actionBar/actionType.nut")


const consumableStart = hdpx(-372)
let consumableGap = isWidescreen ? hdpx(-150) : hdpx(-128)
return cfgHudCommon.__merge(cfgHudCommonNaval, initHudTuningCfg({
  zoom = {
    ctor = mkRhombZoomButton
    defTransform = mkRBPos([hdpx(-380), hdpx(-220)])
    editView = mkWeaponBtnEditView("ui/gameuiskin#hud_binoculars.svg", 1.34)
    isVisibleInBattle = Computed(@() !isPlayingReplay.get())
  }

  plane1 = {
    ctor = @(scale) mkSupportPlaneBtn(AB_SUPPORT_PLANE, supportPlaneConfig[0], scale)
    defTransform = mkRBPos([0, hdpx(-220)])
    editView = mkNumberedWeaponEditView(supportPlaneConfig[0].image, 1, false)
  }





















  weapon1 = weaponryButtonDynamicCtor(0,
    {
      canHide = false
      defTransform = mkRBPos([hdpx(-190), hdpx(-220)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon2 = weaponryButtonDynamicCtor(1,
    {
      canHide = false
      defTransform = mkRBPos([hdpx(-285), hdpx(-125)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon3 = weaponryButtonDynamicCtor(2,
    {
      canHide = false
      defTransform = mkRBPos([hdpx(-190), hdpx(-30)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon4 = weaponryButtonDynamicCtor(3,
    {
      canHide = false
      defTransform = mkRBPos([hdpx(-95), hdpx(-125)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon5 = weaponryButtonDynamicCtor(4,
    {
      canHide = false
      defTransform = mkRBPos([hdpx(-285), hdpx(-315)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon6 = weaponryButtonDynamicCtor(5,
    {
      canHide = false
      defTransform = mkRBPos([hdpx(-95), hdpx(-315)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon7 = weaponryButtonDynamicCtor(6,
    {
      canHide = false
      defTransform = mkRBPos([hdpx(-190), hdpx(-410)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })










  abSmokeScreen = withActionBarButtonCtor(EII_SMOKE_SCREEN, SHIP,
    { defTransform = mkRBPos([consumableStart, hdpx(43)]) })

  abToolkit = withActionBarButtonCtor(EII_TOOLKIT, SHIP,
    { defTransform = mkRBPos([consumableStart + consumableGap, hdpx(43)]) })

  abIrcm = withActionBarButtonCtor(EII_IRCM, SHIP,
     { defTransform = mkRBPos([consumableStart + consumableGap * 2, hdpx(43)]) })

  abCaptureBlocker = withActionBarButtonCtor(EII_ELECTRONIC_WARFARE, SHIP,
     { defTransform = mkRBPos([consumableStart + consumableGap * 3, hdpx(43)]) })

  abCiws = withActionBarButtonCtor(EII_CIWS, SHIP,
     { defTransform = mkRBPos([consumableStart + consumableGap * 4, hdpx(43)]) })

  firework = withActionButtonScaleCtor(AB_FIREWORK, mkRhombFireworkBtn,
    {
      defTransform = mkRBPos([hdpx(-285), hdpx(-505)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_ammo_fireworks.svg", 1.0)
      isVisibleInEditor = fwVisibleInEditor
      isVisibleInBattle = fwVisibleInBattle
    })

  voiceCmdStick = {
    ctor = voiceMsgStickBlock
    defTransform = mkRBPos([hdpx(5), 0])
    editView = voiceMsgStickView
    isVisibleInBattle = isVoiceMsgStickVisibleInBattle
    priority = Z_ORDER.STICK
  }

  moveArrows = {
    canHide = false
    ctor = @(scale) shipMovementBlock(SHIP, scale)
    defTransform = mkLBPos([0, -hdpx(54)])
    editView = moveArrowsViewWithMode
    priority = Z_ORDER.STICK
  }
}))
