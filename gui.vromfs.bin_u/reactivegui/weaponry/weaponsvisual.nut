from "%globalsDarg/darg_library.nut" import *
let { format } = require("string")
let { doesLocTextExist } = require("dagor.localize")
let { getWeaponId } = require("%rGui/weaponry/loadUnitBullets.nut")
let { getLocIdPrefixByCaliber } = require("%appGlobals/config/bulletsPresentation.nut")

function getAmmoNameForLoc(bSet) {
  let { isBulletBelt = false } = bSet
  if (isBulletBelt)
    return bSet?.id == "" ? "default" : (bSet?.id ?? "")
  return bSet?.bulletNames[0] ?? ""
}

// Returns the full name for a shell or machinegun belt
function getAmmoNameText(bSet) {
  let { isBulletBelt = false, weaponBlkName = "" } = bSet
  let name = getAmmoNameForLoc(bSet)
  if (isBulletBelt && name == "default") {
    let customLocId = "".concat(getWeaponId(weaponBlkName), "/default/name/short")
    if (doesLocTextExist(customLocId))
      return loc(customLocId)
  }
  return name == "" ? "" : loc(isBulletBelt ? $"{name}/name" : name)
}

// Returns the short name for a shell or machinegun belt
function getAmmoNameShortText(bSet) {
  let { isBulletBelt = false } = bSet
  let name = getAmmoNameForLoc(bSet)
  if (isBulletBelt && name == "default")
    return getAmmoNameText(bSet)
  local locId = isBulletBelt ? $"{name}/name/short" : $"{name}/short"
  if (!doesLocTextExist(locId))
    locId = $"{name}/name"
  return name == "" ? "" : loc(doesLocTextExist(locId) ? locId : name)
}

let getBulletTypeForLoc = @(bTypeFull) bTypeFull.split("@")[0]

// Returns bullet type(s) desc string for a shell or machinegun belt
function getAmmoTypeText(bSet) {
  let { isBulletBelt = false, bullets = [] } = bSet
  if (isBulletBelt) {
    let list = ndash.join(bullets.map(@(v) loc($"{getBulletTypeForLoc(v)}/name/short")))
    return "".concat(loc("machinegun_belt"), colon, list)
  }
  let btype = getBulletTypeForLoc(bullets?[0] ?? "")
  return btype == "" ? ""
    : " ".concat(loc($"{btype}/name/short"), loc("ui/mdash"), loc($"{btype}/name"))
}

function getAmmoTypeShortText(name) {
  local locId = $"{name}/short"
  if (!doesLocTextExist(locId))
    locId = $"{name}/name/short"
  return (name == null) ? "" : loc(doesLocTextExist(locId) ? locId : name)
}

// Returns usage advice for a shell or machinegun belt
function getAmmoAdviceText(bSet) {
  let { isBulletBelt = false, bullets = [] } = bSet
  let id = isBulletBelt
    ? getAmmoNameForLoc(bSet)
    : getBulletTypeForLoc(bullets?[0] ?? "")
  let locId = id == "" ? "" : $"{id}/desc"
  return (locId == "" || !doesLocTextExist(locId)) ? "" : loc(locId)
}

let isCaliberCannon = @(caliberMm) caliberMm > 15

let withCount = @(text, count) count <= 1 ? text
  : "".concat(text, format(loc("weapons/counter"), count)) //todo: separate lang instead of WT one

function getWeaponNameImpl(weapon, bSet, isShort) {
  let { total, weaponId = "" } = weapon
  if (weaponId != "") {
    if (!isShort)
      return loc($"weapons/{weaponId}")
    let locId = $"weapons/{weaponId}/short"
    return doesLocTextExist(locId) ? loc(locId) : loc($"weapons/{weaponId}")
  }

  let { isBulletBelt = false, caliber = 0, mass = 0, weaponType = null, proximityFuseRadius = 0
  } = bSet
  if (isBulletBelt)
    return loc(isCaliberCannon(caliber) ? "weapons/cannon" : "weapons/minigun", { caliber })

  if (weaponType != null) {
    let locId = proximityFuseRadius > 0 ? $"weapons/{weaponType}_with_fuse" : $"weapons/{weaponType}"
    return withCount(loc(locId, { caliber, mass }), total)
  }

  return weaponId
}

let getWeaponShortName = @(weapon, bSet) getWeaponNameImpl(weapon, bSet, true)
let getWeaponFullName  = @(weapon, bSet) getWeaponNameImpl(weapon, bSet, false)
let getTotalWeaponAmount = @(weapon) max(weapon.turrets, 1) * (weapon?.count ?? 1) * (weapon?.guns ?? 1)

function getWeaponShortNameWithCount(weapon, bSet = null, withAnyCount = false, counterLang = "weapons/counter") {
  let total = getTotalWeaponAmount(weapon)
  let res = getWeaponShortName(weapon, bSet)
  return !withAnyCount && total == 1 ? res : $"{res} {format(loc(counterLang), total)}"
}

function getWeaponCaliber(weapon, bSet) {
  let total = getTotalWeaponAmount(weapon)
  return $"{format(loc("caliber/mm"), bSet.caliber)} {format(loc("weapons/counter/right/short"), total)}"
}

function getWeaponNamesListImpl(weapons, isShort) {
  let counts = {}
  let order = []
  foreach(w in weapons) {
    let { weaponId, turrets, count = 1 } = w
    if(weaponId not in counts)
      order.append(w)
    counts[weaponId] <- (counts?[weaponId] ?? 0) + max(turrets, 1) * count
  }
  return order.map(function(w) {
    let bSet = w.bulletSets?[""]
    let bulletName = getWeaponNameImpl(w, bSet, isShort)
    let count = counts[w.weaponId]
    return count > 1 ? $"{bulletName} {format(loc("weapons/counter"), count)}" : bulletName
  })
}

let getWeaponShortNamesList = @(weapons) getWeaponNamesListImpl(weapons, true)
let getWeaponFullNamesList  = @(weapons) getWeaponNamesListImpl(weapons, false)

function getWeaponDescList(weapons, separator = "\n") {
  let counts = {}
  let bullets = {}
  let order = []
  foreach(w in weapons) {
    let { weaponId, turrets, totalBullets, count = 1 } = w
    if(weaponId not in counts)
      order.append(w)
    counts[weaponId] <- (counts?[weaponId] ?? 0) + max(turrets, 1) * count
    bullets[weaponId] <- (bullets?[weaponId] ?? 0) + totalBullets
  }
  return order.map(function(w) {
    let bSet = w.bulletSets?[""]
    let bulletName = getWeaponNameImpl(w, bSet, false)
    let count = counts[w.weaponId]
    return separator.concat(
      count > 1 ? $"{bulletName} {format(loc("weapons/counter"), count)}" : bulletName,
      "".concat(loc("shop/ammo"), colon, bullets[w.weaponId])
    )
  })
}

let bombLoc = ["bombs", "bombIcon"]
let torpedoLoc = ["torpedoes", "torpedoIcon"]
let rocketLoc = ["rockets", "rocketIcon"]
let additionalGunLoc = ["additional gun", "additionalGunsIcon"]
let weaponTypesLoc = {
  ["additional gun"] = additionalGunLoc
  bomb = bombLoc
  bombs = bombLoc
  torpedo = torpedoLoc
  torpedoes = torpedoLoc
  rocket = rocketLoc
  rockets = rocketLoc
}

let getBulletBeltDesc = @(id) id == "" ? null : loc($"modification/air/machinegun_belt_{getLocIdPrefixByCaliber(id)}/desc")

let getWeaponTypeName = @(id) $"{loc($"weapon/{weaponTypesLoc[id][1]}")} {loc($"weapons_types/{weaponTypesLoc[id][0]}")}"

let getBulletBeltShortName = @(id) id == "" ? loc("default/name")
  : loc($"{getLocIdPrefixByCaliber(id)}/name/short")
let getBulletBeltFullName = @(id, caliber) id == "" ? loc("default/name")
  : format(loc($"{getLocIdPrefixByCaliber(id)}/name"), caliber.tostring())

return {
  getAmmoNameText
  getAmmoNameShortText
  getAmmoTypeShortText
  getAmmoTypeText
  getAmmoAdviceText
  getWeaponShortName
  getWeaponFullName
  getWeaponShortNameWithCount
  getWeaponShortNamesList
  getWeaponFullNamesList
  getWeaponDescList
  getWeaponTypeName
  getWeaponCaliber
  getBulletBeltShortName
  getBulletBeltFullName
  getBulletBeltDesc
}
