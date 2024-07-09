from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { getBulletBeltImage } = require("%appGlobals/config/bulletsPresentation.nut")
let { loadUnitWeaponSlots } = require("%rGui/weaponry/loadUnitBullets.nut")
let { getWeaponShortNameWithCount } = require("%rGui/weaponry/weaponsVisual.nut")
let { getEquippedWeapon } = require("%rGui/unitMods/unitModsSlotsState.nut")
let { mkWeaponPreset } = require("%rGui/unit/unitSettings.nut")

let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bg, bulletsBlockMargin, headerText, header, gap } = require("respawnComps.nut")


let MAX_COLUMNS = 1
let beltImgWidth = evenPx(25)
let imgSize = beltImgWidth * 4
let padding = hdpxi(5)
let weaponWidth = hdpx(400)
let weaponHeight = imgSize + 2 * padding
let smallGap = hdpx(5)


let groupsCfg = [
  {
    locId = "weaponry/courseGuns"
    isFit = @(trigger, weapon) weapon.turrets == 0 && (trigger == "machine gun" || trigger == "cannon")
  }
  {
    locId = "weaponry/turretGuns"
    isFit = @(_, weapon) weapon.turrets > 0
  }
  {
    locId = "weaponry/secondary"
    isFit = @(_, __) true
  }
]

let mkBeltImage = @(bullets) {
  size = [imgSize, imgSize]
  gap = round((imgSize - beltImgWidth * bullets.len()) / max(1, bullets.len())).tointeger()
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = bullets.map(@(name) {
    size = [beltImgWidth, imgSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"{getBulletBeltImage(name)}:{beltImgWidth}:{imgSize}:P")
    keepAspect = true
  })
}

let mkSimpleIcon = @(image) {
  size = [imgSize, imgSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"{image}:{imgSize}:{imgSize}:P")
  keepAspect = true
}

function commonWeaponIcon(w) {
  let { iconType = "" } = w
  return iconType == "" ? null : mkSimpleIcon($"ui/gameuiskin#{iconType}.avif")
}

function mkWeaponCard(w) {
  let bSet = w.bulletSets?[""]
  let { bullets = [], isBulletBelt = false } = bSet
  return bg.__merge({
    size = [weaponWidth, weaponHeight]
    flow = FLOW_HORIZONTAL
    children = [
      {
        size = [weaponHeight, weaponHeight]
        padding
        rendObj = ROBJ_SOLID
        color = 0xA02C2C2C
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
        children = isBulletBelt ? mkBeltImage(bullets)
          : commonWeaponIcon(w)
      }
      {
        size = flex()
        padding
        children = {
          size = [flex(), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          color = 0xFFD0D0D0
          text = getWeaponShortNameWithCount(w, bSet)
        }.__update(fontVeryTiny)
      }
    ]
  })
}

function mkWeaponGroup(wg, wgCfg) {
  if (wg.len() == 0)
    return null
  let columns = min(wg.len(), MAX_COLUMNS)
  let children = wg.map(mkWeaponCard)
  return {
    size = [weaponWidth * columns + gap * (columns - 1), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallGap
    children = [
      header(headerText(loc(wgCfg.locId)))
      {
        flow = FLOW_VERTICAL
        gap = smallGap
        children = arrayByRows(children, columns).map(@(row) {
          flow = FLOW_HORIZONTAL
          gap = smallGap
          children = row
        })
      }
    ]
  }
}

function divideWeaponryByGroups(weapons) {
  let groups = groupsCfg.map(@(_) [])
  foreach(w in weapons)
    foreach(idx, group in groupsCfg)
      if (group.isFit(w.trigger, w)) {
        groups[idx].append(w)
        break
      }

  return groups.map(function(group) {
    let byBlk = {}
    let res = []
    foreach(w in group)
      if (w.blk not in byBlk) {
        byBlk[w.blk] <- res.len()
        res.append(clone w)
      }
      else {
        let idx = byBlk[w.blk]
        res[idx].count <- (res[idx]?.count ?? 1) + (w?.count ?? 1)
      }
    return res
  })
}

function respawnAirWeaponry(selSlot) {
  let wSlots = loadUnitWeaponSlots(selSlot.name)
  let { weaponPreset } = mkWeaponPreset(Watched(selSlot.name))
  return function() {
    let activeWeapons = []
    foreach(idx, wSlot in wSlots) {
      let weapon = getEquippedWeapon(weaponPreset.get(), idx, wSlot?.wPresets ?? {}, selSlot?.mods)
      if (weapon == null)
        continue
      let { iconType = "", weapons } = weapon
      activeWeapons.extend(iconType == "" ? weapons : weapons.map(@(w) w.__merge({ iconType })))
    }

    let weaponGroups = divideWeaponryByGroups(activeWeapons)
    let rows = []
    local curRow = null
    local columnsLeft = MAX_COLUMNS
    foreach(idx, wg in weaponGroups) {
      if (wg.len() == 0)
        continue
      if (curRow == null || columnsLeft < wg.len()) {
        curRow = []
        rows.append(curRow)
        columnsLeft = MAX_COLUMNS
      }
      columnsLeft -= wg.len()
      curRow.append(mkWeaponGroup(wg, groupsCfg[idx]))
    }

    return {
      watch = weaponPreset
      key = selSlot.name
      size = [MAX_COLUMNS * weaponWidth + smallGap * (MAX_COLUMNS - 1), SIZE_TO_CONTENT]
      margin = [0, hdpx(20), 0, bulletsBlockMargin]
      flow = FLOW_VERTICAL
      gap
      children = rows.map(@(children) {
        flow = FLOW_HORIZONTAL
        gap = smallGap
        children
      })
      animations = wndSwitchAnim
    }
  }
}

return respawnAirWeaponry
