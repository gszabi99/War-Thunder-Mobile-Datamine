from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { getBulletBeltImage } = require("%appGlobals/config/bulletsPresentation.nut")
let { loadUnitBulletsFull } = require("%rGui/weaponry/loadUnitBullets.nut")
let { getWeaponShortName } = require("%rGui/weaponry/weaponsVisual.nut")

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

function commonWeaponIcon(w, bSet) {
  let image = bSet?.weaponType == "rockets" ? "ui/gameuiskin#air_to_air_missile.avif"
    : w?.trigger == "bombs" ? "ui/gameuiskin#bomb_big_01.avif"
    : null
  return image == null ? null : mkSimpleIcon(image)
}

function mkWeaponCard(w, count = 0) {
  let bSet = w.bulletSets?[""]
  let { bullets = [], isBulletBelt = false } = bSet
  let bulletName = getWeaponShortName(w, bSet)
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
          : commonWeaponIcon(w, bSet)
      }
      {
        size = flex()
        padding
        children = {
          size = [flex(), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          color = 0xFFD0D0D0
          text = count > 1 ? $"{bulletName} x {count}" : bulletName
        }.__update(fontVeryTiny)
      }
    ]
  })
}

function mkWeaponGroup(wg, wgCfg) {
  if (wg.len() == 0)
    return null
  let columns = min(wg.len(), MAX_COLUMNS)
  let reducedWg = wg.reduce(function(acc, w) {
    let id = w.weaponId
    if(id not in acc.gunCount) {
      acc.gunCount[id] <- w.turrets
      acc.value.append(w)
    } else
      acc.gunCount[id] += w.turrets
    return acc
  }, { gunCount = {}, value = [] })

  let children = reducedWg.value.map(@(w) mkWeaponCard(w, reducedWg.gunCount[w.weaponId]))

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
  let res = groupsCfg.map(@(_) [])
  foreach(trigger, w in weapons)
    foreach(idx, group in groupsCfg)
      if (group.isFit(trigger, w)) {
        res[idx].append(w)
        break
      }
  return res
}

function respawnAirWeaponry(selSlot) {
  let bulletsFull = loadUnitBulletsFull(selSlot.name)
  let commonWeapons = (bulletsFull?.commonWeapons ?? {}).__merge(bulletsFull?[$"{selSlot.name}_default"] ?? {})
  let weaponGroups = divideWeaponryByGroups(commonWeapons)
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

return respawnAirWeaponry
