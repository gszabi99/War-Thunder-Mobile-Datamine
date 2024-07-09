from "%globalsDarg/darg_library.nut" import *
let { allow_voice_messages, has_strategy_mode } = require("%appGlobals/permissions.nut")
let { SHIP } = require("%appGlobals/unitConst.nut")
let { isInMpSession } = require("%appGlobals/clientState/clientState.nut")
let { EII_SMOKE_SCREEN, EII_TOOLKIT, EII_IRCM } = require("%rGui/hud/weaponsButtonsConfig.nut")
let { AB_FIREWORK } = require("%rGui/hud/actionBar/actionType.nut")
let cfgHudCommon = require("cfgHudCommon.nut")
let cfgHudCommonNaval = require("cfgHudCommonNaval.nut")
let { mkZoomButton, mkPlaneItem, mkSimpleButton } = require("%rGui/hud/weaponsButtonsView.nut")
let { mkWeaponBtnEditView, mkNumberedWeaponEditView } = require("%rGui/hudTuning/weaponBtnEditView.nut")
let { Z_ORDER, mkRBPos, mkLBPos, weaponryButtonCtor, weaponryButtonDynamicCtor,
  withActionBarButtonCtor, withActionButtonCtor
} = require("hudTuningPkg.nut")
let shipMovementBlock = require("%rGui/hud/shipMovementBlock.nut")
let { moveArrowsViewWithMode } = require("%rGui/components/movementArrows.nut")
let { voiceMsgStickBlock, voiceMsgStickView } = require("%rGui/hud/voiceMsg/voiceMsgStick.nut")
let { mkRhombFireworkBtn } = require("%rGui/hud/buttons/rhombTouchHudButtons.nut")
let { fwVisibleInEditor, fwVisibleInBattle } = require("%rGui/hud/fireworkState.nut")

return cfgHudCommon.__merge(cfgHudCommonNaval, {
  zoom = weaponryButtonCtor("ID_ZOOM", mkZoomButton,
    {
      defTransform = mkRBPos([hdpx(-380), hdpx(-220)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_binoculars.svg", 1.34)
    })

  plane1 = weaponryButtonCtor("EII_SUPPORT_PLANE", mkPlaneItem,
    {
      defTransform = mkRBPos([0, hdpx(-220)])
      editView = mkNumberedWeaponEditView("ui/gameuiskin#hud_aircraft_fighter.svg", 1, false)
    })
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
    { defTransform = mkRBPos([hdpx(-450), hdpx(43)]) })

  abToolkit = withActionBarButtonCtor(EII_TOOLKIT, SHIP,
    { defTransform = mkRBPos([hdpx(-600), hdpx(43)]) })

  abIrcm = withActionBarButtonCtor(EII_IRCM, SHIP,
     { defTransform = mkRBPos([hdpx(-750), hdpx(43)]) })

  firework = withActionButtonCtor(AB_FIREWORK, mkRhombFireworkBtn,
    {
      defTransform = mkRBPos([hdpx(-216), hdpx(-436)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_ammo_fireworks.svg", 1.0)
      isVisibleInEditor = fwVisibleInEditor
      isVisibleInBattle = fwVisibleInBattle
    })

  voiceCmdStick = {
    ctor = @() voiceMsgStickBlock
    defTransform = mkRBPos([hdpx(5), 0])
    editView = voiceMsgStickView
    isVisibleInEditor = allow_voice_messages
    isVisibleInBattle = Computed(@() allow_voice_messages.get() && isInMpSession.get())
    priority = Z_ORDER.STICK
  }

  moveArrows = {
    ctor = @() shipMovementBlock(SHIP)
    defTransform = mkLBPos([0, -hdpx(54)])
    editView = moveArrowsViewWithMode
    priority = Z_ORDER.STICK
  }
})
