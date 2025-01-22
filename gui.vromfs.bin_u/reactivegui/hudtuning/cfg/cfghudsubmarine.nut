from "%globalsDarg/darg_library.nut" import *
let { SUBMARINE } = require("%appGlobals/unitConst.nut")
let { isInMpSession } = require("%appGlobals/clientState/clientState.nut")
let { EII_TOOLKIT } = require("%rGui/hud/weaponsButtonsConfig.nut")
let cfgHudCommon = require("cfgHudCommon.nut")
let cfgHudCommonNaval = require("cfgHudCommonNaval.nut")
let { mkRhombZoomButton, mkDivingLockButton } = require("%rGui/hud/buttons/rhombTouchHudButtons.nut")
let { mkWeaponBtnEditView } = require("%rGui/hudTuning/weaponBtnEditView.nut")
let { Z_ORDER, mkRBPos, mkLBPos, weaponryButtonDynamicCtor,
  withActionBarButtonCtor } = require("hudTuningPkg.nut")
let { depthSliderBlock, depthSliderEditView } = require("%rGui/hud/submarineDepthBlock.nut")
let shipMovementBlock = require("%rGui/hud/shipMovementBlock.nut")
let { moveArrowsViewWithMode } = require("%rGui/components/movementArrows.nut")
let { voiceMsgStickBlock, voiceMsgStickView } = require("%rGui/hud/voiceMsg/voiceMsgStick.nut")
let { oxygenLevel, oxygenLevelEditView, depthControl, depthControlEditView
} = require("%rGui/hud/oxygenBlock.nut")

return cfgHudCommon.__merge(cfgHudCommonNaval, {
  zoom = {
    ctor = mkRhombZoomButton
    defTransform = mkRBPos([hdpx(-506), hdpx(-220)])
    editView = mkWeaponBtnEditView("ui/gameuiskin#hud_binoculars.svg", 1.34)
  }

  divingLock = {
    ctor = mkDivingLockButton
    defTransform = mkRBPos([hdpx(-181), hdpx(-329)])
    editView = mkWeaponBtnEditView("ui/gameuiskin#hud_submarine_diving.svg", 1.34)
  }

  weapon1 = weaponryButtonDynamicCtor(0,
    {
      defTransform = mkRBPos([hdpx(-290), hdpx(-220)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon2 = weaponryButtonDynamicCtor(1,
    {
      defTransform = mkRBPos([hdpx(-398), hdpx(-112)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon3 = weaponryButtonDynamicCtor(2,
    {
      defTransform = mkRBPos([hdpx(-290), hdpx(-4)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon4 = weaponryButtonDynamicCtor(3,
    {
      defTransform = mkRBPos([hdpx(-182), hdpx(-112)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  depthSLider = {
    ctor = depthSliderBlock
    defTransform = mkRBPos([hdpx(20), hdpx(-129)])
    editView = depthSliderEditView
    priority = Z_ORDER.SLIDER
  }

  abToolkit = withActionBarButtonCtor(EII_TOOLKIT, SUBMARINE,
    { defTransform = mkRBPos([hdpx(-650), hdpx(43)]) })

  voiceCmdStick = {
    ctor = voiceMsgStickBlock
    defTransform = mkRBPos([hdpx(-10), hdpx(-10)])
    editView = voiceMsgStickView
    isVisibleInBattle = isInMpSession
    priority = Z_ORDER.STICK
  }

  moveArrows = {
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
    ctor = depthControl
    defTransform = mkRBPos([0, hdpx(-500)])
    editView = depthControlEditView
    hideForDelayed = false
  }
})
