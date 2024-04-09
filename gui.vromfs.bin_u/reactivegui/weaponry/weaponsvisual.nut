from "%globalsDarg/darg_library.nut" import *
let { format } = require("string")
let { doesLocTextExist } = require("dagor.localize")
let { getWeaponId } = require("%rGui/weaponry/loadUnitBullets.nut")

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

function getWeaponShortName(weapon, bSet) {
  let { isBulletBelt = false, caliber = 0, bullets = null, bulletDataByType = null,
    weaponType = null, proximityFuseRadius = 0
  } = bSet
  if (isBulletBelt)
    return loc(isCaliberCannon(caliber) ? "weapons/cannon" : "weapons/minigun", { caliber })

  let { total } = weapon
  let { mass = 0 } = bulletDataByType?[bullets?[0]]
  if (weaponType != null) {
    let locId = proximityFuseRadius > 0 ? $"weapons/{weaponType}_with_fuse" : $"weapons/{weaponType}"
    return withCount(loc(locId, { caliber, mass }), total)
  }

  return weapon.weaponId
}

return {
  getAmmoNameText
  getAmmoNameShortText
  getAmmoTypeShortText
  getAmmoTypeText
  getAmmoAdviceText
  getWeaponShortName
}
