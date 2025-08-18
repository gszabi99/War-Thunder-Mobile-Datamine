from "%globalsDarg/darg_library.nut" import *
let { format } = require("string")
let { isBattleDataFake } = require("%appGlobals/clientState/respawnStateBase.nut")
let { loadUnitWeaponSlots } = require("%rGui/weaponry/loadUnitBullets.nut")
let { isBeltWeapon, mkWeaponBelts, getEquippedBelt } = require("%rGui/unitMods/unitModsSlotsState.nut")
let { getEquippedWeapon, getEqippedWithoutOverload } = require("%rGui/unitMods/equippedSecondaryWeapons.nut")
let { mkWeaponPreset, mkChosenBelts } = require("%rGui/unit/unitSettings.nut")

let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { headerText, header, headerHeight, bulletsBlockMargin, unitListHeight, textColor, secondaryMenuKey,
  weaponSize, weaponGroupWidth, smallGap, commonWeaponIcon,
  caliberTitle, secondaryTitleKey, courseMenuKey, courseTitleKey, turretMenuKey, turretTitleKey,
  mkBeltImage
} = require("%rGui/respawn/respawnComps.nut")
let { getBulletBeltShortName } = require("%rGui/weaponry/weaponsVisual.nut")
let { unitPlatesGap, unitPlateHeight } = require("%rGui/unit/components/unitPlateComp.nut")
let { respawnSlots, unitListScrollHandler } = require("%rGui/respawn/respawnState.nut")
let { selectedBeltWeaponId } = require("%rGui/respawn/respawnAirChooseState.nut")
let { showAirRespChooseSecWnd, showAirRespChooseBeltWnd } = require("%rGui/respawn/respawnAirChooseWeaponWnd.nut")

let mkCardTitle = @(title) title == "" ? null
  : {
      size = FLEX_H
      padding = const [hdpx(4), 0, 0, hdpx(8)]
      rendObj = ROBJ_BOX
      fillColor = 0x44000000
      children = {
        size = FLEX_H
        rendObj = ROBJ_TEXT
        color = 0xFFFFFFFF
        text = title
        behavior = Behaviors.Marquee
        delay = defMarqueeDelay
        threshold = hdpx(2)
        speed = hdpx(30)
      }.__update(fontVeryTinyShaded)
    }

let mkCard = @(iconComp, title, bottomTitle = "", isSelectedStyle = false) {
  behavior = Behaviors.Button
  size = [weaponSize, weaponSize]
  rendObj = ROBJ_BOX
  fillColor = 0xFF45545D
  borderColor = 0xFFFFFFFF
  borderWidth = hdpx(3)
  children = [
    iconComp
    mkCardTitle(title).__update({
      borderWidth = const [hdpx(3), hdpx(3), 0, hdpx(3)]
      borderColor = isSelectedStyle ? 0xC07BFFFF : 0xFFFFFFFF
    })
    bottomTitle == "" ? null : mkCardTitle(bottomTitle).__update({
      borderWidth = const [0, hdpx(3), hdpx(3), hdpx(3)]
      borderColor = isSelectedStyle ? 0xC07BFFFF : 0xFFFFFFFF
      vplace = ALIGN_BOTTOM
      padding = const [0, hdpx(4), hdpx(4), hdpx(6)]
    })
  ]
}

let weaponTitle = @(w) format(loc("weapons/counter/right/short"), (w?.count ?? 1))
let mkWeaponCard = @(w, canClick) mkCard(commonWeaponIcon(w).__update({vplace = ALIGN_BOTTOM, hplace = ALIGN_CENTER}),
  weaponTitle(w)).__update({
    onClick = canClick ? @() showAirRespChooseSecWnd(w.slotIdx) : null
    sound = canClick ? { click = "click" } : null
  })

let mkBeltCard = @(w, canClick)
  @() mkCard(
    mkBeltImage(w.equipped?.bullets ?? []),
    caliberTitle(w),
    getBulletBeltShortName(w.equipped?.id),
    w.weaponId == selectedBeltWeaponId.get()
  ).__update({
    watch = selectedBeltWeaponId
    borderColor = w.weaponId == selectedBeltWeaponId.get() ? 0xC07BFFFF : 0xFFFFFFFF
    onClick = canClick ? @() showAirRespChooseBeltWnd(w.weaponId) : null
    sound = canClick ? { click = "click" } : null
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
      size = FLEX_H
      rendObj = ROBJ_SOLID
      color = 0x99000000
      children = {
        size = FLEX_H
        behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ]
        touchMarginPriority = TOUCH_BACKGROUND
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
  foreach(w in weapons) {
    if (w.iconType not in byIcon) {
      byIcon[w.iconType] <- res.len()
      res.append(clone w)
    }
    let idx = byIcon[w.iconType]
    res[idx].count <- (res[idx]?.count ?? 0) + ((w?.count ?? 1) * (w?.weapons[0].totalBullets ?? 1))
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
      if (idx != 0) 
        secondaryWeapons.append(weapon.__merge({ slotIdx = idx }))
    }

    let rows = []
    if (courseBeltWeapons.len() > 0)
      rows.append(mkGroup("weaponry/courseGunBelts",
        courseBeltWeapons.sort(@(a, b) b.caliber <=> a.caliber).map(@(w) mkBeltCard(w, !isBattleDataFake.get())), { key = courseMenuKey }, {
          key = courseTitleKey
        }))
    if (turretBeltWeapons.len() > 0)
      rows.append(mkGroup("weaponry/turretGunBelts",
        turretBeltWeapons.sort(@(a, b) b.caliber <=> a.caliber).map(@(w) mkBeltCard(w, !isBattleDataFake.get())), { key = turretMenuKey }, {
          key = turretTitleKey
        }))
    let secondaryStacks = stackSecondaryWeapons(secondaryWeapons)
    if (secondaryStacks.len() > 0)
      rows.append(mkGroup("weaponry/secondaryWeapons", secondaryStacks.map(@(w) mkWeaponCard(w, !isBattleDataFake.get())), { key = secondaryMenuKey }, {
        key = secondaryTitleKey
      }))
    else if (wSlots.len() > 1 && !isBattleDataFake.get())
      rows.append(mkGroup("weaponry/secondaryWeapons", mkEmptyInfo(loc("weaponry/tapToChooseSecondary")), {
        onClick = @() showAirRespChooseSecWnd(1)
        sound = { click = "click" }
        behavior = Behaviors.Button
        scrollHandler = null
        key = secondaryMenuKey
      }, {
        key = secondaryTitleKey
      }))

    return {
      watch = [weaponPreset, chosenBelts, isBattleDataFake]
      size = [weaponGroupWidth + bulletsBlockMargin, SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = [
        mkLinks(selSlot, rows.len())
        {
          key = selSlot.name
          margin = const [0, hdpx(20), 0, 0]
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
