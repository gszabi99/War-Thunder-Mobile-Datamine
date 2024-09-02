from "%globalsDarg/darg_library.nut" import *
let { loadUnitWeaponSlots } = require("%rGui/weaponry/loadUnitBullets.nut")
let { getEquippedWeapon, isBeltWeapon, mkWeaponBelts, getEquippedBelt, getEqippedWithoutOverload
} = require("%rGui/unitMods/unitModsSlotsState.nut")
let { mkWeaponPreset, mkChosenBelts } = require("%rGui/unit/unitSettings.nut")

let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { headerText, header, headerHeight, bulletsBlockMargin, unitListHeight, textColor, secondaryMenuKey,
  padding, weaponSize, weaponGroupWidth, smallGap, commonWeaponIcon,
  getWeaponTitle, caliberTitle, secondaryTitleKey, courseMenuKey, courseTitleKey, turretMenuKey, turretTitleKey,
  mkBeltImage
} = require("respawnComps.nut")
let { getBulletBeltShortName } = require("%rGui/weaponry/weaponsVisual.nut")
let { unitPlatesGap, unitPlateHeight } = require("%rGui/unit/components/unitPlateComp.nut")
let { respawnSlots, unitListScrollHandler } = require("respawnState.nut")
let { selectedBeltWeaponId } = require("respawnAirChooseState.nut")
let { showAirRespChooseSecWnd, showAirRespChooseBeltWnd } = require("respawnAirChooseWeaponWnd.nut")

let mkCardTitle = @(title) title == "" ? null
  : {
      size = [flex(), SIZE_TO_CONTENT]
      padding = [hdpx(4), 0, 0, hdpx(8)]
      rendObj = ROBJ_BOX
      fillColor = 0x44000000
      children = {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXT
        color = 0xFFFFFFFF
        text = title
        behavior = Behaviors.Marquee
        delay = defMarqueeDelay
        speed = hdpx(30)
      }.__update(fontVeryTinyShaded)
    }

let mkCard = @(iconComp, title, bottomTitle = "") {
  behavior = Behaviors.Button
  size = [weaponSize, weaponSize]
  rendObj = ROBJ_BOX
  fillColor = 0xFF45545D
  borderColor = 0xFFFFFFFF
  borderWidth = hdpx(3)
  children = [
    {
      padding
      children = iconComp
    }
    mkCardTitle(title)
    bottomTitle == "" ? null : mkCardTitle(bottomTitle).__update({ vplace = ALIGN_BOTTOM, padding = [0,0,0,hdpx(8)] })
  ]
}

let mkWeaponCard = @(w) mkCard(commonWeaponIcon(w), getWeaponTitle(w))
  .__update({ onClick = @() showAirRespChooseSecWnd(w.slotIdx) })

let mkBeltCard = @(w)
  @() mkCard(mkBeltImage(w.equipped?.bullets ?? []), caliberTitle(w), getBulletBeltShortName(w.equipped?.id)).__update({
    watch = selectedBeltWeaponId
    borderColor = w.weaponId == selectedBeltWeaponId.get() ? 0xC07BFFFF : 0xFFFFFFFF
    onClick = @() showAirRespChooseBeltWnd(w.weaponId)
  })

let mkEmptyInfo = @(text) {
  size = [flex(), weaponSize]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  text
  color = textColor
}.__update(fontTinyAccented)

let mkGroup = @(locId, children, ovr = {}, headerOvr = {}) {
  size = [weaponGroupWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = smallGap
  clipChildren = true
  children = [
    header(headerText(loc(locId))).__update(headerOvr)
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_SOLID
      color = 0x99000000
      children = {
        size = [flex(), SIZE_TO_CONTENT]
        behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ]
        scrollHandler = ScrollHandler()
        flow = FLOW_HORIZONTAL
        gap = smallGap
        halign = ALIGN_CENTER
        children
      }.__update(ovr)
    }
  ]
}

function stackSecondaryWeapons(weapons) {
  let byIcon = {}
  let res = []
  foreach(w in weapons)
    if (w.iconType not in byIcon) {
      byIcon[w.iconType] <- res.len()
      res.append(clone w)
    }
    else {
      let idx = byIcon[w.iconType]
      res[idx].count <- (res[idx]?.count ?? 1) + (w?.count ?? 1)
    }
  return res
}

let normalizeValue = @(val) (100 * val) / unitListHeight
let calcUnitToY = @(idx) normalizeValue(
  idx * headerHeight
    + idx * smallGap
    + (idx - 1) * unitPlatesGap
    + (idx - 0.5) * weaponSize)

let calcUnitFromY = @(idx, scrollOffsY) normalizeValue(
  (idx + 0.5) * unitPlateHeight
    + idx * unitPlatesGap
    - scrollOffsY)

function mkLinks(selSlot, weaponGroupsLen) {
  let slotIdx = Computed(@() respawnSlots.get().findindex(@(rs) rs.id == selSlot.id) ?? 0)
  let unitFromYComp = Computed(function() {
    let scrollOffsY = unitListScrollHandler.elem?.getScrollOffsY() ?? 0
    let posY = calcUnitFromY(slotIdx.get(), scrollOffsY)
    return posY < 0 ? -1
      : posY > 100 ? 101
      : posY
  })
  return function() {
    let unitFromY = unitFromYComp.get()
    let unitFromLine = unitFromY < 0 || unitFromY > 100 ? null
      : [VECTOR_LINE, 0, unitFromY, 50, unitFromY]

    let unitToYArr = array(weaponGroupsLen).map(@(_, idx) calcUnitToY(idx + 1))
    let unitToLines = unitToYArr.map(@(posY) [VECTOR_LINE, 50, posY, 100, posY])

    let baseTop = max(0, min(unitToYArr[0], unitFromY))
    let baseBottom = min(100, max(unitToYArr[unitToYArr.len() - 1], unitFromY))
    let baseLine = [VECTOR_LINE, 50, baseTop, 50, baseBottom]
    return {
      watch = unitFromYComp
      size = [bulletsBlockMargin, unitListHeight]
      margin = [unitPlatesGap + headerHeight, 0, 0, 0]
      rendObj = ROBJ_VECTOR_CANVAS
      lineWidth = evenPx(4)
      color = 0xFFFFFFFF
      commands = [
        baseLine,
        unitFromLine
      ].extend(unitToLines).filter(@(l) l != null)
    }
  }
}

function respawnAirWeaponry(selSlot) {
  let wSlots = loadUnitWeaponSlots(selSlot.name)
  let unitNameW = Watched(selSlot.name)
  let { weaponPreset } = mkWeaponPreset(unitNameW)
  let { chosenBelts } = mkChosenBelts(unitNameW)
  return function() {
    let courseBeltWeapons = []
    let turretBeltWeapons = []
    let secondaryWeapons = []
    let addedBelts = {}

    let weapBySlots = getEqippedWithoutOverload(selSlot.name,
      wSlots.map(@(wSlot, idx) getEquippedWeapon(weaponPreset.get(), idx, wSlot?.wPresets ?? {}, selSlot?.mods)))

    foreach(idx, weapon in weapBySlots) {
      if (weapon == null)
        continue
      foreach(w in weapon.weapons) {
        let { weaponId } = w
        if (weaponId in addedBelts)
          addedBelts[weaponId].count++
        else if (isBeltWeapon(w)) {
          let list = w.turrets > 0 ? turretBeltWeapons : courseBeltWeapons
          let equipped = getEquippedBelt(chosenBelts.get(), weaponId, mkWeaponBelts(selSlot.name, w), selSlot?.mods)
          let beltW = w.__merge({
            count = 1
            equipped
            caliber = equipped?.caliber ?? 0
          })
          list.append(beltW)
          addedBelts[weaponId] <- beltW
        }
      }
      if (idx != 0) //idx == 0 is commonWeapons
        secondaryWeapons.append(weapon.__merge({ slotIdx = idx }))
    }

    let rows = []
    if (courseBeltWeapons.len() > 0)
      rows.append(mkGroup("weaponry/courseGunBelts",
        courseBeltWeapons.sort(@(a, b) b.caliber <=> a.caliber).map(mkBeltCard), { key = courseMenuKey }, {
          key = courseTitleKey
        }))
    if (turretBeltWeapons.len() > 0)
      rows.append(mkGroup("weaponry/turretGunBelts",
        turretBeltWeapons.sort(@(a, b) b.caliber <=> a.caliber).map(mkBeltCard), { key = turretMenuKey }, {
          key = turretTitleKey
        }))
    let secondaryStacks = stackSecondaryWeapons(secondaryWeapons)
    if (secondaryStacks.len() > 0)
      rows.append(mkGroup("weaponry/secondaryWeapons", secondaryStacks.map(mkWeaponCard), { key = secondaryMenuKey }, {
        key = secondaryTitleKey
      }))
    else if (wSlots.len() > 1)
      rows.append(mkGroup("weaponry/secondaryWeapons", mkEmptyInfo(loc("weaponry/tapToChooseSecondary")), {
        onClick = @() showAirRespChooseSecWnd("")
        behavior = Behaviors.Button
        scrollHandler = null
        key = secondaryMenuKey
      }, {
        key = secondaryTitleKey
      }))

    return {
      watch = [weaponPreset, chosenBelts]
      size = [weaponGroupWidth + bulletsBlockMargin, SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = [
        mkLinks(selSlot, rows.len())
        {
          key = selSlot.name
          margin = [0, hdpx(20), 0, 0]
          flow = FLOW_VERTICAL
          gap = unitPlatesGap
          children = [
            header(headerText(loc("respawn/select_weapon")))
          ].extend(rows)
          animations = wndSwitchAnim
        }
      ]
    }
  }
}

return respawnAirWeaponry
