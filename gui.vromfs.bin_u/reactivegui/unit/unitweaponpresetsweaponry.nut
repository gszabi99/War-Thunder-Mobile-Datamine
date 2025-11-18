from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("%sqstd/math.nut")
let { format } = require("string")
let { deep_clone, isEqual } = require("%sqstd/underscore.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { backButtonHeight } = require("%rGui/components/backButton.nut")
let { openEditTextWnd, closeEditTextWnd } = require("%rGui/components/editTextWnd.nut")
let { getBulletBeltShortName } = require("%rGui/weaponry/weaponsVisual.nut")
let { mkWeaponBelts, isBeltWeapon, getEquippedBelt } = require("%rGui/unitMods/unitModsSlotsState.nut")
let { sendPlayerActivityToServer } = require("%rGui/respawn/playerActivity.nut")
let { padding, weaponSize, smallGap, commonWeaponIcon, mkBeltImage,
  header, headerText, caliberTitle, defPadding
} = require("%rGui/respawn/respawnComps.nut")
let { mkBlocksContainer } = require("%rGui/components/verticalBlocks.nut")
let { loadUnitWeaponSlots } = require("%rGui/weaponry/loadUnitBullets.nut")
let { getEquippedWeapon } = require("%rGui/unitMods/equippedSecondaryWeapons.nut")
let { mkWeaponPreset, mkChosenBelts, mkSavedWeaponPresets } = require("%rGui/unit/unitSettings.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")


let MAX_PRESET_NAME_LENGTH = 32
let MAX_SAVED_PRESET = 5
let SLOTS_IN_ROW = 5
let SLOTS_IN_PRESET_ROW = 6
let activeBorderColor = selectColor
let cardBgColor = 0xFF45545D
let presetBorderWidth = hdpx(3)
let cellGap = hdpx(12)
let cellSizeWithGap = weaponSize + cellGap
let wndSize = @(cells) cellSizeWithGap * cells - cellGap
let presetBlockHeight = hdpx(180)
let paddingWnd = hdpx(10)
let wndSizeWithPadding = @(cells) wndSize(cells) + paddingWnd * 2
let containerHeight = saSize[1] - backButtonHeight - hdpx(70) - saBordersRv[0] * 2
let weaponBlockWidth = wndSizeWithPadding(SLOTS_IN_ROW)
let presetBlockWidth = wndSizeWithPadding(SLOTS_IN_PRESET_ROW)
let weaponBorderWidth = hdpx(3)
let contentGap = hdpx(20)

let activePresetIdx = Watched(-1)
let currentPresetName = Watched("")
let curUnit = Watched(null)

let unitName = Computed(@() curUnit.get()?.name)
let curMods = Computed(@() curUnit.get()?.mods)
let allWSlots = Computed(@() unitName.get() == null ? [] : loadUnitWeaponSlots(unitName.get()))

let { weaponPreset, setWeaponPreset } = mkWeaponPreset(unitName)
let { chosenBelts, setChosenBelts } = mkChosenBelts(unitName)
let { savedWeaponPresets, setSavedWeaponPresets } = mkSavedWeaponPresets(unitName)

let presets = Computed(function() {
  let savedPresets = savedWeaponPresets.get()
  let currentIdx = savedPresets.findindex(@(p) isEqual(p.weaponPreset, weaponPreset.get())
    && (isEqual(p.beltPreset.filter(@(belt) belt != ""), chosenBelts.get().filter(@(belt) belt != "")))) ?? -1
  if (currentIdx == -1)
    return [{
      name = ""
      isCurrent = true
      weaponPreset = weaponPreset.get()
      beltPreset = chosenBelts.get()
    }].extend(savedPresets)
  return savedPresets.map(@(p, idx) idx == currentIdx ? p.__merge({isCurrent = true}) : p)
})

presets.subscribe(@(v) activePresetIdx.set(v.findindex(@(p) p?.isCurrent ?? false)))

let isCurrentPreset = Computed(@() presets.get()?[activePresetIdx.get()].isCurrent ?? false)
let isNotSavedPreset = Computed(@() presets.get().len() != savedWeaponPresets.get().len() && activePresetIdx.get() == 0)
let isMaxSavedPresetAmountReached = Computed(@() presets.get().len() > MAX_SAVED_PRESET)

function closeEditNameWnd() {
  sendPlayerActivityToServer()
  closeEditTextWnd()
  currentPresetName.set("")
}

function onSave(name) {
  sendPlayerActivityToServer()
  let newPreset = {
    name
    weaponPreset = weaponPreset.get()
    beltPreset = chosenBelts.get()
  }
  setSavedWeaponPresets(deep_clone(savedWeaponPresets.get()).append(newPreset))
}

function onSetPresetName() {
  sendPlayerActivityToServer()
  let name = currentPresetName.get().strip()
  if (name.len() == 0)
    return openMsgBox({text = loc("msgbox/presets/cannot_apply/empty_name")})
  let savedPresets = savedWeaponPresets.get()
  if (savedPresets.findindex(@(p) p.name == name) != null)
    return openMsgBox({text = loc("msgbox/presets/cannot_apply/duplicated")})
  let allPresets = presets.get()
  let activeIdx = activePresetIdx.get()
  let presetIdx = allPresets.len() == savedPresets.len() ? activeIdx : activeIdx - 1
  if (presetIdx == -1)
    onSave(name)
  else
    setSavedWeaponPresets(savedPresets.map(@(p, idx) idx != presetIdx ? p : p.__merge({name})))
  closeEditNameWnd()
}

function openEditNameWnd(isNew = false) {
  sendPlayerActivityToServer()
  if (isNew) {
    if (!isNotSavedPreset.get())
      return openMsgBox({text = loc("msgbox/presets/cannot_save/already_saved")})
    if (isMaxSavedPresetAmountReached.get())
      return openMsgBox({text = loc("msgbox/presets/cannot_save/max_reached")})
  } else {
    if (isNotSavedPreset.get())
      return openMsgBox({text = loc("msgbox/presets/cannot_edit")})
  }

  openEditTextWnd(currentPresetName, onSetPresetName, MAX_PRESET_NAME_LENGTH)
  currentPresetName.set(presets.get()?[activePresetIdx.get()].name ?? "")
}

function onDelete() {
  sendPlayerActivityToServer()
  if (activePresetIdx.get() not in presets.get())
    return
  if (isNotSavedPreset.get())
    return openMsgBox({text = loc("msgbox/presets/cannot_delete")})
  let activIdx = activePresetIdx.get()
  setSavedWeaponPresets(deep_clone(savedWeaponPresets.get()).filter(@(p) p.name != presets.get()[activIdx].name))
}

function onApply() {
  sendPlayerActivityToServer()
  if (activePresetIdx.get() not in presets.get())
    return
  if (isCurrentPreset.get())
    return openMsgBox({text = loc("msgbox/presets/cannot_apply")})
  let curPreset = presets.get()[activePresetIdx.get()]
  setWeaponPreset(curPreset.weaponPreset)
  setChosenBelts(curPreset.beltPreset)
}

let slotBase = {
  size = [weaponSize, weaponSize]
  rendObj = ROBJ_BOX
  fillColor = cardBgColor
  borderWidth = weaponBorderWidth
  borderColor = 0xFFFFFFFF
}

let mkPaddingTitleCtor = @() array(4, defPadding)

function getTitlePaddingTop() {
  let res = mkPaddingTitleCtor()
  res[2] = 0
  return res
}

function getTitlePaddingBottom() {
  let res = mkPaddingTitleCtor()
  res[0] = 0
  return res
}

let mkSlotTitle = @(title, ovr = {}) title == "" ? null
  : {
      size = FLEX_H
      rendObj = ROBJ_BOX
      fillColor = 0x44000000
      padding = [hdpx(1), defPadding]
      children = {
        size = FLEX_H
        rendObj = ROBJ_TEXT
        color = 0xFFFFFFFF
        text = title
        hplace = ALIGN_CENTER
        behavior = Behaviors.Marquee
        delay = defMarqueeDelay
        threshold = hdpx(2)
        speed = hdpx(30)
      }.__update(fontVeryTinyShaded)
    }.__update(ovr)

let mkBeltSlot = @(w) slotBase.__merge({
  children = [
    mkBeltImage(w.equipped?.bullets ?? [], weaponSize - defPadding * 2)
    {
      size = FLEX_H
      padding = getTitlePaddingTop()
      vplace = ALIGN_TOP
      hplace = ALIGN_CENTER
      children = mkSlotTitle(caliberTitle(w))
    }
    {
      size = FLEX_H
      padding = getTitlePaddingBottom()
      vplace = ALIGN_BOTTOM
      hplace = ALIGN_CENTER
      children = mkSlotTitle(getBulletBeltShortName(w.equipped?.id))
    }
  ]
})

let getWeaponTitle = @(w) format(loc("weapons/counter/right/short"), (w?.count ?? 1))

let mkWeaponSlot = @(w) slotBase.__merge({
  fillColor = cardBgColor
  children = [
    {
      padding
      children = commonWeaponIcon(w)
    }
    {
      size = FLEX_H
      padding = getTitlePaddingTop()
      vplace = ALIGN_TOP
      hplace = ALIGN_CENTER
      children = mkSlotTitle(getWeaponTitle(w))
    }
  ]
})

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

function getEquippedWeaponByGroup(weapons, belts, uName, allSlots, mods) {
  let courseBeltWeapons = []
  let turretBeltWeapons = []
  let secondaryWeapons = []
  let addedBelts = {}

  let weapBySlots = allSlots.map(@(wSlot, idx) getEquippedWeapon(weapons, idx, wSlot?.wPresets ?? {}, mods))

  foreach(idx, weapon in weapBySlots) {
    if (weapon == null)
      continue
    foreach(w in weapon.weapons) {
      let { weaponId } = w
      if (weaponId in addedBelts)
        addedBelts[weaponId].count++
      else if (isBeltWeapon(w)) {
        let list = w.turrets > 0 ? turretBeltWeapons : courseBeltWeapons
        let equipped = getEquippedBelt(belts, weaponId, mkWeaponBelts(uName, w), mods)
        let beltW = w.__merge({
          count = 1
          equipped
          caliber = equipped?.caliber ?? 0
        })
        list.append(beltW)
        addedBelts[weaponId] <- beltW
      }
    }
    secondaryWeapons.append(weapon.__merge({ slotIdx = idx }))
  }

  let courseSlots = courseBeltWeapons.map(@(w) mkBeltSlot(w))
  let turretSlots = turretBeltWeapons.map(@(w) mkBeltSlot(w))
  let weaponSlots = stackSecondaryWeapons(secondaryWeapons.slice(1)) 
    .map(@(w) mkWeaponSlot(w))

  return {weaponSlots, courseSlots, turretSlots}
}

let mkRowGroup = @(children) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = cellGap
  children
}

let calcRowsByElems = @(elems, elemsInRow) ceil(1.0 * elems.len() / elemsInRow).tointeger()
let arrayToRows = @(elems, elemsInRow, ovr = {}) array(calcRowsByElems(elems, elemsInRow))
  .map(@(_, idx) mkRowGroup(elems.slice(idx * elemsInRow, (idx + 1) * elemsInRow)).__update(ovr))

let mkGroup = @(children) {
  rendObj = ROBJ_BOX
  size = FLEX_H
  flow = FLOW_VERTICAL
  fillColor = 0xFF383B3E
  children
}

function mkChooseWeaponSlotWnd() {
  let res = {watch = [activePresetIdx, presets, allWSlots, unitName, curMods]}
  if (activePresetIdx.get() not in presets.get())
    return res

  let {weaponSlots, courseSlots, turretSlots} = getEquippedWeaponByGroup(
    presets.get()[activePresetIdx.get()].weaponPreset,
    presets.get()[activePresetIdx.get()].beltPreset,
    unitName.get(),
    allWSlots.get(),
    curMods.get()
  )
  let courseSlotsRows = arrayToRows(courseSlots, SLOTS_IN_ROW, { halign = ALIGN_CENTER, padding = paddingWnd })
  let turretSlotsRows = arrayToRows(turretSlots, SLOTS_IN_ROW, { halign = ALIGN_CENTER, padding = paddingWnd })
  let weaponSlotsRows = arrayToRows(weaponSlots, SLOTS_IN_ROW, { halign = ALIGN_CENTER, padding = paddingWnd })

  return res.__merge({
    size = [weaponBlockWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = contentGap
    children = [
      courseSlotsRows.len() <= 0 ? null
        : mkGroup([header(headerText(loc("weaponry/courseGunBelts")))].extend(courseSlotsRows))
      turretSlotsRows.len() <= 0 ? null
        : mkGroup([header(headerText(loc("weaponry/turretGunBelts")))].extend(turretSlotsRows))
      weaponSlotsRows.len() <= 0 ? null
        : mkGroup([header(headerText(loc("weaponry/secondaryWeapons")))].extend(weaponSlotsRows))
    ]
  })
}

let mkWeaponBlock = {
  size = FLEX_V
  padding = paddingWnd
  rendObj = ROBJ_SOLID
  color = 0x50000000
  stopMouse = true
  flow = FLOW_VERTICAL
  gap = smallGap
  children = mkChooseWeaponSlotWnd
}

let centralBlock = {
  size = FLEX_V
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = mkWeaponBlock
}

function mkPresetSlots(preset) {
  let {weaponSlots, courseSlots, turretSlots} = getEquippedWeaponByGroup(
    preset.weaponPreset,
    preset.beltPreset,
    unitName.get(),
    allWSlots.get(),
    curMods.get()
  )

  return {
    watch = [unitName, allWSlots, curMods]
    flow = FLOW_HORIZONTAL
    gap = cellGap
    children = arrayToRows(weaponSlots.extend(courseSlots, turretSlots).slice(0, SLOTS_IN_PRESET_ROW),
      SLOTS_IN_PRESET_ROW,
      { halign = ALIGN_LEFT }
    )
  }
}

let mkBlockContent = @(preset, idx) @(){
  watch = activePresetIdx
  size = [presetBlockWidth, presetBlockHeight]
  flow = FLOW_VERTICAL
  padding = paddingWnd
  gap = cellGap
  rendObj = ROBJ_BOX
  borderColor = activePresetIdx.get() == idx ? activeBorderColor : 0x00000000
  borderWidth = presetBorderWidth
  children = [
    {
      rendObj = ROBJ_TEXT
      behavior = Behaviors.Marquee
      delay = defMarqueeDelay
      speed = hdpx(30)
      maxWidth = pw(100)
      text = $"{preset.name}{!(preset?.isCurrent ?? false) ? "" : $" ({loc("presets/current")})"}"
    }.__update(fontTinyShaded)
    @() mkPresetSlots(preset)
  ]
}

let unitWeaponPresetWeaponry = {
  size = flex()
  padding = const [0, 0, hdpx(40), 0]
  children = {
    flow = FLOW_HORIZONTAL
    gap = contentGap
    size = flex()
    onDetach = @() activePresetIdx.set(-1)
    children = [
      mkBlocksContainer(
        presets,
        activePresetIdx,
        mkBlockContent,
        function(idx) {
          sendPlayerActivityToServer()
          activePresetIdx.set(idx)
        },
        presetBlockWidth,
        presetBlockHeight,
        containerHeight,
        {scrollAlign = ALIGN_LEFT}
      )
      centralBlock
    ]
  }
}

return {
  unitWeaponPresetWeaponry,
  curUnit,
  onDelete,
  onApply,
  openEditNameWnd,
  isCurrentPreset,
  isNotSavedPreset,
  isMaxSavedPresetAmountReached
}
