from "%globalsDarg/darg_library.nut" import *
let { has_strategy_mode } = require("%appGlobals/permissions.nut")
let { SHIP } = require("%appGlobals/unitConst.nut")
let { isInMpSession } = require("%appGlobals/clientState/clientState.nut")
let { EII_SMOKE_SCREEN, EII_TOOLKIT,
  //


  EII_IRCM } = require("%rGui/hud/weaponsButtonsConfig.nut")
let { AB_FIREWORK, AB_SUPPORT_PLANE, AB_SUPPORT_PLANE_2, AB_SUPPORT_PLANE_3,
//


} = require("%rGui/hud/actionBar/actionType.nut")
let cfgHudCommon = require("cfgHudCommon.nut")
let cfgHudCommonNaval = require("cfgHudCommonNaval.nut")
let { mkWeaponBtnEditView, mkNumberedWeaponEditView } = require("%rGui/hudTuning/weaponBtnEditView.nut")
let { Z_ORDER, mkRBPos, mkLBPos, weaponryButtonDynamicCtor,
  withActionBarButtonCtor, withActionButtonScaleCtor
} = require("hudTuningPkg.nut")
let shipMovementBlock = require("%rGui/hud/shipMovementBlock.nut")
let { moveArrowsViewWithMode } = require("%rGui/components/movementArrows.nut")
let { voiceMsgStickBlock, voiceMsgStickView } = require("%rGui/hud/voiceMsg/voiceMsgStick.nut")
let { mkRhombFireworkBtn, mkRhombZoomButton, mkSupportPlaneBtn, mkAntiairButton, mkRhombSimpleActionBtn
} = require("%rGui/hud/buttons/rhombTouchHudButtons.nut")
let { fwVisibleInEditor, fwVisibleInBattle } = require("%rGui/hud/fireworkState.nut")
let supportPlaneConfig = require("%rGui/hud/supportPlaneConfig.nut")

let consumableStart = hdpx(-372)
let consumableGap = isWidescreen ? hdpx(-150) : hdpx(-128)
return cfgHudCommon.__merge(cfgHudCommonNaval, {
  zoom = {
    ctor = mkRhombZoomButton
    defTransform = mkRBPos([hdpx(-380), hdpx(-220)])
    editView = mkWeaponBtnEditView("ui/gameuiskin#hud_binoculars.svg", 1.34)
  }

  plane1 = {
    ctor = @(scale) mkSupportPlaneBtn(AB_SUPPORT_PLANE, supportPlaneConfig[0], scale)
    defTransform = mkRBPos([0, hdpx(-220)])
    editView = mkNumberedWeaponEditView(supportPlaneConfig[0].image, 1, false)
  }
//




















  weapon1 = weaponryButtonDynamicCtor(0,
    {
      defTransform = mkRBPos([hdpx(-190), hdpx(-220)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon2 = weaponryButtonDynamicCtor(1,
    {
      defTransform = mkRBPos([hdpx(-285), hdpx(-125)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon3 = weaponryButtonDynamicCtor(2,
    {
      defTransform = mkRBPos([hdpx(-190), hdpx(-30)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon4 = weaponryButtonDynamicCtor(3,
    {
      defTransform = mkRBPos([hdpx(-95), hdpx(-125)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon5 = weaponryButtonDynamicCtor(4,
    {
      defTransform = mkRBPos([hdpx(-285), hdpx(-315)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  weapon6 = weaponryButtonDynamicCtor(5,
    {
      defTransform = mkRBPos([hdpx(-95), hdpx(-315)])
      priority = Z_ORDER.BUTTON_PRIMARY
    })

//







  abSmokeScreen = withActionBarButtonCtor(EII_SMOKE_SCREEN, SHIP,
    { defTransform = mkRBPos([consumableStart, hdpx(43)]) })

  abToolkit = withActionBarButtonCtor(EII_TOOLKIT, SHIP,
    { defTransform = mkRBPos([consumableStart + consumableGap, hdpx(43)]) })

  abIrcm = withActionBarButtonCtor(EII_IRCM, SHIP,
     { defTransform = mkRBPos([consumableStart + consumableGap * 2, hdpx(43)]) })

//




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
    isVisibleInBattle = isInMpSession
    priority = Z_ORDER.STICK
  }

  moveArrows = {
    ctor = @(scale) shipMovementBlock(SHIP, scale)
    defTransform = mkLBPos([0, -hdpx(54)])
    editView = moveArrowsViewWithMode
    priority = Z_ORDER.STICK
  }
})
