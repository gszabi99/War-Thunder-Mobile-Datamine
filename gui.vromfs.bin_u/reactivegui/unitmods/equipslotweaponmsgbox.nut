from "%globalsDarg/darg_library.nut" import *
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { curSlotIdx, curWeapon, equippedWeaponsBySlots, equipCurWeapon, equipWeaponList
  mirrorIdx, equipCurWeaponToWings } = require("unitModsSlotsState.nut")
let { openMsgBox, msgBoxText } = require("%rGui/components/msgBox.nut")
let { getWeaponFullName } = require("%rGui/weaponry/weaponsVisual.nut")
let { markTextColor, highlightTextColor } = require("%rGui/style/stdColors.nut")


let imgSize = evenPx(70)
let borderWidth = hdpxi(3)
let iconMargin = hdpx(10)

let mkText = @(text) msgBoxText(text, { size = [flex(), SIZE_TO_CONTENT] })

function mkWeaponIcon(weapon, borderColor = highlightTextColor) {
  let { iconType = "" } = weapon
  return {
    margin = iconMargin
    padding = borderWidth
    rendObj = ROBJ_BOX
    fillColor = 0xFF45545D
    borderColor
    borderWidth
    children = iconType == "" ? null
      : {
          size = [imgSize, imgSize]
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#{iconType}.avif:{imgSize}:{imgSize}:P")
          keepAspect = true
        }
  }
}

let weaponRow = @(headerText, weapon, color) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    msgBoxText(headerText, { size = [flex(), SIZE_TO_CONTENT], halign = ALIGN_RIGHT })
    mkWeaponIcon(weapon, color)
    msgBoxText(colorize(color, getWeaponFullName(weapon.weapons[0], null)),
      { size = [flex(), SIZE_TO_CONTENT], halign = ALIGN_LEFT })
  ]
}

let vertList = @(children, ovr = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children
}.__update(ovr)

function mkConflictsMsgContent(weapon, conflicts) {
  let curWeaponName = colorize(markTextColor, getWeaponFullName(weapon.weapons[0], null)).replace(" ", nbsp)

  let curWeaponWithIcon = weaponRow("", weapon, markTextColor)

  let conflictsComp = vertList(
    conflicts.map(
      @(v) weaponRow(
        "".concat(loc("weapons/slotName/full", { slotIdx = v.slotIdx }), colon),
        v.weapon,
        highlightTextColor)),
    { margin = [0, 0, hdpx(30), 0] })

  return {
    size = flex()
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = mkTextRow(
        loc("msg/installWeaponWithConflict", { weapon = curWeaponName }),
        mkText,
        {
          ["{weaponWithImage}"] = curWeaponWithIcon,  //warning disable: -forgot-subst
          ["{conflictList}"] = conflictsComp,  //warning disable: -forgot-subst
        }
      )
        .insert(0, { size = flex() })
        .append({ size = flex(2) })
  }
}

let openConflictsMsgBox = @(slotIdx, weapon, conflicts, equipWeaponListFunc)
  openMsgBox({
    title = loc("weapons/hasConflictWeapons")
    text = mkConflictsMsgContent(weapon, conflicts)
    buttons = [
      { id = "cancel", isCancel = true }
      { text = loc("mod/enable"), styleId = "PRIMARY", isDefault = true,
        eventId = "equipWithConflictsResolve",
        cb = @() equipWeaponListFunc(conflicts
          .reduce(@(res, v) res.$rawset(v.slotIdx, ""), {})
          .__update({ [slotIdx] = weapon.name }))
      }
    ]
    wndOvr = { size = [hdpx(1200), hdpx(900)] }
  })

function customEquipCurWeaponMsg(currentSlotIdx, currentWeapon, equippedBySlots, equipCurrent, equipList) {
  let { banPresets = {} } = currentWeapon
  if (banPresets.len() == 0) {
    equipCurrent()
    return
  }

  let conflicts = []
  foreach(slotIdx, weapon in equippedBySlots)
    if (weapon != null && (banPresets?[slotIdx][weapon.name] ?? false))
      conflicts.append({ slotIdx, weapon })
  if (conflicts.len() == 0) {
    equipCurrent()
    return
  }

  openConflictsMsgBox(currentSlotIdx, currentWeapon, conflicts, equipList)
}

return {
  equipCurWeaponMsg = @() customEquipCurWeaponMsg(curSlotIdx.get(), curWeapon.get(),
    equippedWeaponsBySlots.get(), mirrorIdx.get() != -1 ? equipCurWeaponToWings : equipCurWeapon, equipWeaponList)
  customEquipCurWeaponMsg
}