from "%globalsDarg/darg_library.nut" import *
let { SHIP } = require("%appGlobals/unitConst.nut")
let { EII_SMOKE_SCREEN, EII_TOOLKIT } = require("%rGui/hud/weaponsButtonsConfig.nut")
let cfgHudCommon = require("cfgHudCommon.nut")
let cfgHudCommonNaval = require("cfgHudCommonNaval.nut")
let { mkZoomButton, mkPlaneItem } = require("%rGui/hud/weaponsButtonsView.nut")
let { mkWeaponBtnEditView, mkNumberedWeaponEditView } = require("%rGui/hudTuning/weaponBtnEditView.nut")
let { mkRBPos, mkLBPos, weaponryButtonCtor, weaponryButtonDynamicCtor, withActionBarButtonCtor
} = require("hudTuningPkg.nut")
let shipMovementBlock = require("%rGui/hud/shipMovementBlock.nut")
let { moveArrowsViewWithMode } = require("%rGui/components/movementArrows.nut")

return cfgHudCommon.__merge(cfgHudCommonNaval, {
  zoom = weaponryButtonCtor("ID_ZOOM", mkZoomButton,
    {
      defTransform = mkRBPos([hdpx(-432), hdpx(-220)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_binoculars.svg", 1.34)
    })

  plane1 = weaponryButtonCtor("EII_SUPPORT_PLANE", mkPlaneItem,
    {
      defTransform = mkRBPos([hdpx(-108), hdpx(-330)])
      editView = mkNumberedWeaponEditView("ui/gameuiskin#hud_aircraft_fighter.svg", 1, false)
    })

  plane2 = weaponryButtonCtor("EII_SUPPORT_PLANE_2", mkPlaneItem,
    {
      defTransform = mkRBPos([0, hdpx(-222)])
      editView = mkNumberedWeaponEditView("ui/gameuiskin#hud_aircraft_fighter.svg", 2, false)
    })

  plane3 = weaponryButtonCtor("EII_SUPPORT_PLANE_3", mkPlaneItem,
    {
      defTransform = mkRBPos([hdpx(0), hdpx(-5)])
      editView = mkNumberedWeaponEditView("ui/gameuiskin#hud_aircraft_fighter.svg", 3, false)
    })

  weapon1 = weaponryButtonDynamicCtor(0,
    {
      defTransform = mkRBPos([hdpx(-216), hdpx(-220)])
    })

  weapon2 = weaponryButtonDynamicCtor(1,
    {
      defTransform = mkRBPos([hdpx(-325), hdpx(-112)])
    })

  weapon3 = weaponryButtonDynamicCtor(2,
    {
      defTransform = mkRBPos([hdpx(-216), hdpx(-4)])
    })

  weapon4 = weaponryButtonDynamicCtor(3,
    {
      defTransform = mkRBPos([hdpx(-108), hdpx(-112)])
    })

  weapon5 = weaponryButtonDynamicCtor(4,
    {
      defTransform = mkRBPos([hdpx(-326), hdpx(-328)])
    })

  abSmokeScreen = withActionBarButtonCtor(EII_SMOKE_SCREEN, SHIP,
    { defTransform = mkRBPos([hdpx(-450), hdpx(43)]) })
  abToolkit = withActionBarButtonCtor(EII_TOOLKIT, SHIP,
    { defTransform = mkRBPos([hdpx(-600), hdpx(43)]) })

  moveArrows = {
    ctor = @() shipMovementBlock(SHIP)
    defTransform = mkLBPos([0, -hdpx(54)])
    editView = moveArrowsViewWithMode
  }
})