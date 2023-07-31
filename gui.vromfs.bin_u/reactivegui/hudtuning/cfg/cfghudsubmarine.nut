from "%globalsDarg/darg_library.nut" import *
let { SUBMARINE } = require("%appGlobals/unitConst.nut")
let { EII_SMOKE_SCREEN, EII_TOOLKIT } = require("%rGui/hud/weaponsButtonsConfig.nut")
let cfgHudCommon = require("cfgHudCommon.nut")
let cfgHudCommonNaval = require("cfgHudCommonNaval.nut")
let { mkZoomButton, mkDivingLockButton } = require("%rGui/hud/weaponsButtonsView.nut")
let { mkWeaponBtnEditView } = require("%rGui/hudTuning/weaponBtnEditView.nut")
let { mkRBPos, mkLBPos, weaponryButtonCtor, weaponryButtonDynamicCtor, withActionBarButtonCtor
} = require("hudTuningPkg.nut")
let { depthSliderBlock, depthSliderEditView } = require("%rGui/hud/submarineDepthBlock.nut")
let shipMovementBlock = require("%rGui/hud/shipMovementBlock.nut")
let { moveArrowsViewWithMode } = require("%rGui/components/movementArrows.nut")
let { oxygenLevel, oxygenLevelEditView, depthControl, depthControlEditView
} = require("%rGui/hud/oxygenBlock.nut")

return cfgHudCommon.__merge(cfgHudCommonNaval, {
  zoom = weaponryButtonCtor("ID_ZOOM", mkZoomButton,
    {
      defTransform = mkRBPos([hdpx(-506), hdpx(-220)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_binoculars.svg", 1.34)
    })

  divingLock = weaponryButtonCtor("EII_DIVING_LOCK", mkDivingLockButton,
    {
      defTransform = mkRBPos([hdpx(-181), hdpx(-329)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_submarine_diving.svg", 1.34)
    })

  weapon1 = weaponryButtonDynamicCtor(0,
    {
      defTransform = mkRBPos([hdpx(-290), hdpx(-220)])
    })

  weapon2 = weaponryButtonDynamicCtor(1,
    {
      defTransform = mkRBPos([hdpx(-398), hdpx(-112)])
    })

  weapon3 = weaponryButtonDynamicCtor(2,
    {
      defTransform = mkRBPos([hdpx(-290), hdpx(-4)])
    })

  weapon4 = weaponryButtonDynamicCtor(3,
    {
      defTransform = mkRBPos([hdpx(-182), hdpx(-112)])
    })

  depthSLider = {
    ctor = @() depthSliderBlock
    defTransform = mkRBPos([hdpx(20), hdpx(0)])
    editView = depthSliderEditView()
  }

  abSmokeScreen = withActionBarButtonCtor(EII_SMOKE_SCREEN, SUBMARINE,
    { defTransform = mkRBPos([hdpx(-500), hdpx(43)]) })
  abToolkit = withActionBarButtonCtor(EII_TOOLKIT, SUBMARINE,
    { defTransform = mkRBPos([hdpx(-650), hdpx(43)]) })

  moveArrows = {
    ctor = @() shipMovementBlock(SUBMARINE)
    defTransform = mkLBPos([0, -hdpx(54)])
    editView = moveArrowsViewWithMode
  }

  oxygen = {
    ctor = @() oxygenLevel
    defTransform = mkLBPos([hdpx(634), hdpx(-381)])
    editView = oxygenLevelEditView
    hideForDelayed = false
  }

  depthControl = {
    ctor = @() depthControl
    defTransform = mkLBPos([hdpx(544), hdpx(-452)])
    editView = depthControlEditView
    hideForDelayed = false
  }
})
