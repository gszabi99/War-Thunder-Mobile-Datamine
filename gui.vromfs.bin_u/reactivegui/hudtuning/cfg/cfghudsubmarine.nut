from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import SUBMARINE
from "%rGui/components/movementArrows.nut" import moveArrowsViewWithMode
from "%rGui/hud/buttons/rhombTouchHudButtons.nut" import mkRhombZoomButton, mkDivingLockButton
from "%rGui/hud/oxygenBlock.nut" import oxygenLevel, oxygenLevelEditView, depthControl, depthControlEditView
import "%rGui/hud/shipMovementBlock.nut" as shipMovementBlock
from "%rGui/hud/submarineDepthBlock.nut" import depthSliderBlock, depthSliderEditView
from "%rGui/hud/voiceMsg/voiceMsgStick.nut" import voiceMsgStickBlock, voiceMsgStickView, isVoiceMsgStickVisibleInBattle
from "%rGui/hud/weaponsButtonsConfig.nut" import EII_TOOLKIT, EII_ACOUSTIC_DECOY
from "%rGui/hudState.nut" import isPlayingReplay
import "%rGui/hudTuning/cfg/cfgHudCommon.nut" as cfgHudCommon
import "%rGui/hudTuning/cfg/cfgHudCommonNaval.nut" as cfgHudCommonNaval
from "%rGui/hudTuning/cfg/hudTuningPkg.nut" import Z_ORDER, mkRBPos, mkLBPos, weaponryButtonDynamicCtor,
  withActionBarButtonCtor
import "%rGui/hudTuning/cfg/initHudTuningCfg.nut" as initHudTuningCfg
from "%rGui/hudTuning/weaponBtnEditView.nut" import mkWeaponBtnEditView


return cfgHudCommon.__merge(cfgHudCommonNaval, initHudTuningCfg({
  zoom = {
    ctor = mkRhombZoomButton
    defTransform = mkRBPos([hdpx(-506), hdpx(-220)])
    editView = mkWeaponBtnEditView("ui/gameuiskin#hud_binoculars.svg", 1.34)
    isVisibleInBattle = Computed(@() !isPlayingReplay.get())
  }

  divingLock = {
    ctor = mkDivingLockButton
    defTransform = mkRBPos([hdpx(-181), hdpx(-329)])
    editView = mkWeaponBtnEditView("ui/gameuiskin#hud_submarine_diving.svg", 1.34)
  }

  weapon1 = weaponryButtonDynamicCtor(0,
    {
      canHide = false
      defTransform = mkRBPos([hdpx(-290), hdpx(-220)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon2 = weaponryButtonDynamicCtor(1,
    {
      canHide = false
      defTransform = mkRBPos([hdpx(-398), hdpx(-112)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon3 = weaponryButtonDynamicCtor(2,
    {
      canHide = false
      defTransform = mkRBPos([hdpx(-290), hdpx(-4)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon4 = weaponryButtonDynamicCtor(3,
    {
      canHide = false
      defTransform = mkRBPos([hdpx(-182), hdpx(-112)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  depthSLider = {
    canHide = false
    ctor = depthSliderBlock
    defTransform = mkRBPos([hdpx(20), hdpx(-129)])
    editView = depthSliderEditView
    priority = Z_ORDER.SLIDER
  }

  abToolkit = withActionBarButtonCtor(EII_TOOLKIT, SUBMARINE,
    { defTransform = mkRBPos([hdpx(-650), hdpx(43)]) })

  acousticDecoy = withActionBarButtonCtor(EII_ACOUSTIC_DECOY, SUBMARINE,
    { defTransform = mkRBPos([hdpx(-500), hdpx(43)]) })

  voiceCmdStick = {
    ctor = voiceMsgStickBlock
    defTransform = mkRBPos([hdpx(-10), hdpx(-10)])
    editView = voiceMsgStickView
    isVisibleInBattle = isVoiceMsgStickVisibleInBattle
    priority = Z_ORDER.STICK
  }

  moveArrows = {
    canHide = false
    ctor = @(scale) shipMovementBlock(SUBMARINE, scale)
    defTransform = mkLBPos([0, -hdpx(54)])
    editView = moveArrowsViewWithMode
    priority = Z_ORDER.STICK
  }

  oxygen = {
    ctor = oxygenLevel
    defTransform = mkRBPos([hdpx(-180), hdpx(-500)])
    editView = oxygenLevelEditView
    hideForDelayed = false
  }

  depthControl = {
    canHide = false
    ctor = depthControl
    defTransform = mkRBPos([0, hdpx(-500)])
    editView = depthControlEditView
    hideForDelayed = false
  }
}))
