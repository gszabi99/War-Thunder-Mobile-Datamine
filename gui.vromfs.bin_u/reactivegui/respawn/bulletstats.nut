from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { round_by_value, roundToDigits } = require("%sqstd/math.nut")
let { getArmorPiercingByDistance, getRicochetGuaranteedAngle, getTntStrengthEquivalent
} = require("%rGui/weaponry/dmgModel.nut")

const ARMOR_PENETRATION_DIST_MIN = 100
const ARMOR_PENETRATION_DIST_MAX = 500

let getMassText = @(mass) mass < 1 ? "".concat((1000 * mass).tointeger(), loc("measureUnits/gr"))
  : "".concat(round_by_value(mass, 0.01), loc("measureUnits/kg"))

let getPenetrationDistance = @(tags, isMaxDistance) isMaxDistance
  ? (tags?.armorPenetrationDistanceMax ?? ARMOR_PENETRATION_DIST_MAX)
  : (tags?.armorPenetrationDistanceMin ?? ARMOR_PENETRATION_DIST_MIN)

function mkPenetrationStat(isMaxDistance) {
  return {
    function getName(tags) {
      let distance = getPenetrationDistance(tags, isMaxDistance)
      return loc("bullet_properties/penetration", {
        distance = "".concat(distance, loc("measureUnits/meters_alt"))
        angle = "".concat("0", loc("measureUnits/deg"))
      })
    }
    function getValue(bSet, tags, unitName) {
      let distance = getPenetrationDistance(tags, isMaxDistance)
      let { weaponBlkName, id } = bSet
      let piercing = getArmorPiercingByDistance(unitName, weaponBlkName, id, distance)
      return piercing < 0 ? null
        : "".concat(roundToDigits(round(piercing), 2), loc("measureUnits/mm"))
    }
  }
}

let stats = [
  mkPenetrationStat(false)
  mkPenetrationStat(true)
  {
    getName = @(_tags) loc("bullet_properties/ricochet/angle", { percent = 100 })
    function getValue(bSet, _tags, _unitName) {
      let angle = getRicochetGuaranteedAngle(bSet?.ricochetPreset)
      return angle < 0 ? null
        : "".concat(roundToDigits(angle, 2), loc("measureUnits/deg"))
    }
  }
  {
    locId = "bullet_properties/explosiveMassInTNTEquivalent"
    function getValue(bSet, _tags, _unitName) {
      if ("explosiveMass" not in bSet)
        return null
      let eq = (bSet?.explosiveType ?? "tnt") == "tnt" ? 1.0
        : getTntStrengthEquivalent(bSet.explosiveType)
      return eq <= 0 ? null : getMassText(bSet.explosiveMass * eq)
    }
  }
  {
    locId = "bullet_properties/explodeTreshold"
    getValue = @(bSet, _tags, _unitName) (bSet?.explodeTreshold ?? 0) <= 0 ? null
      : "".concat(roundToDigits(bSet.explodeTreshold, 2), loc("measureUnits/mm"))
  }
  {
    locId = "controls/help/reload_timer"
    getValue = @(_bSet, tags, _unitName) (tags?.shotFreq ?? 0) <= 0 ? null
      : "".concat(round(1.0 / tags.shotFreq), loc("measureUnits/seconds"))
  }
]

let getBulletStats = @(bSet, tags, unitName) bSet == null ? []
  : stats.map(@(s) { nameText = s?.getName(tags) ?? loc(s.locId), valueText = s.getValue(bSet, tags, unitName) })
      .filter(@(s) s.valueText != null)

return getBulletStats