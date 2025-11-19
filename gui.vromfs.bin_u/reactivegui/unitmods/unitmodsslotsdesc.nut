from "%globalsDarg/darg_library.nut" import *
let { format } = require("string")
let { isEqual } = require("%sqstd/underscore.nut")
let { commonTextColor, badTextColor } = require("%rGui/style/stdColors.nut")
let { getBulletBeltFullName, getWeaponFullName, getBulletBeltDesc } = require("%rGui/weaponry/weaponsVisual.nut")
let { getTntEquivalentMass } = require("%rGui/weaponry/weaponryStatsCalculations.nut")
let { getMassText, getMassLbsText, getSpeedText, getSpeedRangeText, getHeightRangeText, getDistanceText
} = require("%rGui/measureUnits.nut")


let headerColor = 0xFFFFFFFF
let infoGap = hdpxi(10)

let rowCfgDefaults = freeze({
  getHeader = @(_w) ""
  isVisible = @(_w, _v) true
  getVal = @(_w) null
  valToStr = @(_v) null
  color = commonTextColor
})

let mkRowCfg = @(locId, getVal, valToStr = @(v) v.tostring(), isVisible = @(_w, v) v != null) {
  getHeader = @(_w) loc(locId)
  getVal
  valToStr
  isVisible
}

function getSingleBulletParamsTbl(weapon) {
  let { bulletSets } = weapon
  return (bulletSets.len() == 1 && bulletSets?[""].bullets.len() == 1) ? bulletSets[""] : null
}

let getSingleBulletParam = @(weapon, key) getSingleBulletParamsTbl(weapon)?[key]

let weaponDescRowsCfg = [
  {
    function getHeader(w) {
      let bSet = w.bulletSets?[""]
      let name = getWeaponFullName(w, bSet)
      return w.count > 1 ? $"{name} {format(loc("weapons/counter"), w.count)}" : name
    }
    color = headerColor
  }
  mkRowCfg("shop/ammo", @(w) w.totalBullets)
  mkRowCfg("stats/mass",
    function(w) {
      if (w.mass <= 0)
        return null
      return { mass = w.mass, massLbs = w?.massLbs ?? 0 }
    },
    @(v) v.massLbs <= 0 ? getMassText(v.mass)
      : $"{getMassLbsText(v.massLbs)} ({getMassText(v.mass)})")
  mkRowCfg("weapons/drop_speed_range",
    function(w) {
      let singleBulletParam = getSingleBulletParam(w, "dropSpeedRange")
      return singleBulletParam == null ? null
        : [max(0, singleBulletParam[0]), singleBulletParam[1]]
    },
    @(v) getSpeedRangeText(v[0], v[1]))
  mkRowCfg("weapons/drop_height_range",
    function(w) {
      let singleBulletParam = getSingleBulletParam(w, "dropHeightRange")
      return singleBulletParam == null ? null
        : [max(0, singleBulletParam[0]), singleBulletParam[1]]
    },
    @(v) getHeightRangeText(v[0], v[1]))
  mkRowCfg("bullet_properties/explosiveType",
    @(w) getSingleBulletParam(w, "explosiveType")
    @(v) loc($"explosiveType/{v}"))
  mkRowCfg("bullet_properties/explosiveMass",
    @(w) getSingleBulletParam(w, "explosiveMass"),
    getMassText)
  mkRowCfg("bullet_properties/explosiveMassInTNTEquivalent"
    function(w) {
      let { explosiveType = "tnt", explosiveMass = 0 } = getSingleBulletParamsTbl(w)
      let mass = getTntEquivalentMass(explosiveType, explosiveMass)
      return mass == 0 ? null : mass
    },
    getMassText)
  mkRowCfg("torpedo/maxSpeedInWater",
    @(w) getSingleBulletParam(w, "maxSpeedInWater"),
    getSpeedText)
  mkRowCfg("torpedo/distanceToLive",
    @(w) getSingleBulletParam(w, "distToLive"),
    getDistanceText)
  mkRowCfg("rocket/maxSpeed",
    @(w) getSingleBulletParam(w, "maxSpeed"),
    getSpeedText)
  mkRowCfg("rocket/warhead",
    @(w) getSingleBulletParam(w, "warhead"),
    @(v) loc($"rocket/warhead/{v}"))
]
  .map(@(r) rowCfgDefaults.__merge(r))


let ignoreFields = ["blk", "weaponId", "bulletSets", "weaponBlkName"].totable()
function isWeaponsCanCountAsSame(w1, w2) {
  foreach (k, v in w1)
    if (k not in ignoreFields && !isEqual(v, w2?[k]))
      return false
  foreach (id, bSet in w1.bulletSets)
    foreach (k, v in bSet)
      if (k not in ignoreFields && !isEqual(v, w2.bulletSets?[id][k]))
        return false
  return getWeaponFullName(w1, w1.bulletSets?[""]) == getWeaponFullName(w2, w2.bulletSets?[""])
}

function getDescRowsCfg(slotWeapon, conflictSlots) {
  let resArr = []
  let { weapons, mass, massLbs = 0 } = slotWeapon
  if (weapons.len() == 0)
    return resArr

  let wId = weapons[0].weaponId 
  local totalCount = 0
  local totalBulletsCount = 0
  local totalTurrets = 0
  let fullList = { [wId]  = true }
  foreach(w in weapons) {
    let { weaponId, turrets, totalBullets, count = 1 } = w
    if (wId != weaponId && !isWeaponsCanCountAsSame(weapons[0], w)) {
      fullList[weaponId] <- true
      continue
    }
    totalCount += max(turrets, 1) * count
    totalBulletsCount += totalBullets
    totalTurrets += turrets
  }

  if (fullList.len() > 1) {
    log("slotWeapon for desc: ", slotWeapon)
    log("weapnId list: ", fullList.keys())
    logerr("SlotWeaponPreset has more than 1 different weaponId")
  }

  let weapon = weapons[0].__merge({
    count = totalCount
    totalBullets = totalBulletsCount
    turrets = totalTurrets
    mass
    massLbs
  })

  foreach(r in weaponDescRowsCfg) {
    let val = r.getVal(weapon)
    if (!r.isVisible(weapon, val))
      continue
    resArr.append({ header = r.getHeader(weapon), valueText = r.valToStr(val), color = r.color })
  }

  if ((conflictSlots?.len() ?? 0) != 0)
    resArr.append({
      header = loc("weapons/conflictSlotsHint",
        {
          count = conflictSlots.len()
          slots = comma.join(conflictSlots.map(@(v) $"#{v}"))
        })
      color = badTextColor
      valueText = null
    })

  return resArr
}

let mkDesc = @(width, text, color = commonTextColor) {
  size = [width, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color
}.__update(fontTiny)

let mkRows = @(rowsCfg, width) {
  size = [width, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = rowsCfg.map(function(r) {
    let { header, valueText, color } = r
    return valueText == null ? mkDesc(width, header, color)
      : {
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          gap = infoGap
          children = [
            mkDesc(flex(), header, color)
            {
              maxWidth = width / 2 - infoGap
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              text = valueText
              color
              halign = ALIGN_RIGHT
            }.__update(fontTiny)
          ]
        }
  })
}

function getBeltBulletsInfoText(belt) {
  let { caliber, bullets } = belt
  if (bullets.len() < 1)
    return ""

  let used = {}
  let annotationList = []
  let nameList = []
  foreach (b in bullets) {
    if (b in used) {
      nameList.append(used[b])
      continue
    }
    let splittedBullet = b.split("@")
    let shortName = "".join(splittedBullet.map(@(v) loc($"{v}/name/short")))
    let fullName = "".join(splittedBullet.map(@(v) loc($"{v}/name")))
    nameList.append(shortName)
    annotationList.append($"{shortName} - {fullName}")
    used[b] <- shortName
  }

  return "\n\n".concat(
    format(loc($"caliber_{caliber}/desc"), loc("bullet_type_separator/name").join(nameList)),
    "\n".join(annotationList))
}

let mkBeltDesc = @(belt, width) {
  size = [width, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    mkDesc(width, getBulletBeltFullName(belt.id, belt.caliber), headerColor)
    mkDesc(width, getBulletBeltDesc(belt.id))
    mkDesc(width, getBeltBulletsInfoText(belt))
  ]
}

return {
  mkBeltDesc
  mkSlotWeaponDesc = @(slotWeapon, width, conflictSlots = null) mkRows(getDescRowsCfg(slotWeapon, conflictSlots), width)
}