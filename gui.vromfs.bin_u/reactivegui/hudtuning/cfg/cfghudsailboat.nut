from "%globalsDarg/darg_library.nut" import *
let { SHIP } = require("%appGlobals/unitConst.nut")
let { isInMpSession } = require("%appGlobals/clientState/clientState.nut")
let { AB_PRIMARY_WEAPON, AB_SECONDARY_WEAPON } = require("%rGui/hud/actionBar/actionType.nut")
let cfgHudCommon = require("cfgHudCommon.nut")
let cfgHudCommonNaval = require("cfgHudCommonNaval.nut")
let { Z_ORDER, mkRBPos, mkLBPos } = require("hudTuningPkg.nut")
let { optBulletsRight } = require("cfgOptions.nut")
let shipMovementBlock = require("%rGui/hud/shipMovementBlock.nut")
let { moveArrowsViewWithMode } = require("%rGui/components/movementArrows.nut")
let { voiceMsgStickBlock, voiceMsgStickView } = require("%rGui/hud/voiceMsg/voiceMsgStick.nut")
let { mkCircleZoomCtor, mkBigCircleBtnEditView } = require("%rGui/hud/buttons/circleTouchHudButtons.nut")
let { mkBroadsideButtonCtor, mkBroadsideButtonEditView } = require("%rGui/hud/buttons/sailboatGuns.nut")
let { mkDollCtor, mkDollEditView, mkCrewHealthCtor, mkCrewHealthEditView, mkSailboatDebuffs, sailboatDebuffsEditView
} = require("%rGui/hud/shipStateModule.nut")


let debuffPosX = clamp(saSize[0] / 2 - hdpx(460), hdpx(420), hdpx(540))

let healthImageWidth = shHud(20)
let healthImageHeight = (71.0 / 200.0 * healthImageWidth).tointeger()
let healthSize = [healthImageWidth, healthImageHeight]

return cfgHudCommon.__merge(cfgHudCommonNaval, {
  zoom = {
    ctor = mkCircleZoomCtor("ui/gameuiskin#hud_consumable_pirate_zoom_out.svg",
      "ui/gameuiskin#hud_consumable_pirate_zoom.svg", 1.2)
    defTransform = mkRBPos([hdpx(-360), hdpx(-340)])
    editView = mkBigCircleBtnEditView("ui/gameuiskin#hud_consumable_pirate_zoom.svg")
    priority = Z_ORDER.BUTTON_PRIMARY
  }

  broadsideRight = {
    ctor = mkBroadsideButtonCtor(AB_PRIMARY_WEAPON, "ID_SHIP_WEAPON_PRIMARY", true)
    defTransform = mkRBPos([hdpx(0), hdpx(-250)])
    editView = mkBroadsideButtonEditView("ui/gameuiskin#hud_pirate_attack.svg", true)
    priority = Z_ORDER.BUTTON_PRIMARY
    options = [ optBulletsRight ]
  }

  broadsideLeft = {
    ctor = mkBroadsideButtonCtor(AB_SECONDARY_WEAPON, "ID_SHIP_WEAPON_SECONDARY", false)
    defTransform = mkRBPos([hdpx(-240), hdpx(-60)])
    editView = mkBroadsideButtonEditView("ui/gameuiskin#hud_pirate_attack.svg", false)
    priority = Z_ORDER.BUTTON_PRIMARY
    options = [ optBulletsRight ]
  }

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

  doll = {
    ctor = mkDollCtor(healthSize)
    defTransform = mkLBPos([debuffPosX + hdpx(30), hdpx(-38)])
    editView = mkDollEditView(healthSize)
    hideForDelayed = false
  }

  debuffs = {
    ctor = mkSailboatDebuffs
    defTransform = mkLBPos([debuffPosX, 0])
    editView = sailboatDebuffsEditView
    hideForDelayed = false
  }

  crewHealth = {
    ctor = mkCrewHealthCtor(healthSize, false)
    defTransform = mkLBPos([debuffPosX + hdpx(100), hdpx(-115)])
    editView = mkCrewHealthEditView(healthSize, false)
    hideForDelayed = false
  }
})
