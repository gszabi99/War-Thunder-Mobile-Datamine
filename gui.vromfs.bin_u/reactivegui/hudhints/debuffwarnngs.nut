from "%globalsDarg/darg_library.nut" import *
let { addEvent, removeEvent } = require("%rGui/hudHints/warningHintLogState.nut")
let { hasDebuffFire, hasDebuffFlooding, hasDebuffGuns, hasDebuffEngines, hasDebuffMoveControl, hasDebuffTorpedoes
} = require("%rGui/hud/shipState.nut")
let tankState = require("%rGui/hud/tankState.nut")
let { isUnitDelayed, hudUnitType } = require("%rGui/hudState.nut")
let { SAILBOAT } = require("%appGlobals/unitConst.nut")

let excludedForSailBoat = [
  "hud_debuff_engine"
]

function subscribeDebuffWarning(watch, iconId, text) {
  let icon = $"ui/gameuiskin#{iconId}.svg"
  watch.subscribe(@(v) !v ? removeEvent({ id = iconId })
    : isUnitDelayed.get() || ((hudUnitType.get() == SAILBOAT) && excludedForSailBoat.contains(iconId)) ? null
    : addEvent({
        id = iconId,
        hType = "warningWithIcon"
        icon
        text
        ttl = 5.0
      }))
}

subscribeDebuffWarning(hasDebuffFire, "hud_debuff_fire", loc("hint/debuff/fire"))
subscribeDebuffWarning(hasDebuffFlooding, "hud_debuff_water", loc("hint/debuff/flooding"))
subscribeDebuffWarning(hasDebuffEngines, "hud_debuff_engine", loc("hint/debuff/engine"))
subscribeDebuffWarning(hasDebuffGuns, "hud_debuff_weapon", loc("hint/debuff/weapon"))
subscribeDebuffWarning(hasDebuffMoveControl, "hud_debuff_control", loc("hint/debuff/control"))
subscribeDebuffWarning(hasDebuffTorpedoes, "hud_debuff_torpedo_tubes", loc("hints/torpedo_broken"))

subscribeDebuffWarning(tankState.hasDebuffGuns, "gun_state_indicator", loc("hint/debuff/weapon"))
subscribeDebuffWarning(tankState.hasDebuffTurretDrive, "turret_gear_state_indicator", loc("hint/debuff/turretEngine"))
subscribeDebuffWarning(tankState.hasDebuffEngine, "engine_state_indicator", loc("hint/debuff/engine"))
subscribeDebuffWarning(tankState.hasDebuffTracks, "track_state_indicator", loc("hint/debuff/tracks"))
subscribeDebuffWarning(tankState.hasDebuffFire, "hud_debuff_fire", loc("hint/debuff/tank_fire"))
subscribeDebuffWarning(tankState.hasDebuffFireExternal, "hud_debuff_fire", loc("hint/debuff/tank_fire_external"))