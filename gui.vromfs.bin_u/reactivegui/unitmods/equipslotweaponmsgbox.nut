from "%globalsDarg/darg_library.nut" import *
let { format } = require("string")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { curSlotIdx, curWeapon, equippedWeaponsBySlots, equipCurWeapon, equipWeaponListWithMirrors
  mirrorIdx, equipCurWeaponToWings, curUnit } = require("unitModsSlotsState.nut")
let { openMsgBox, msgBoxText } = require("%rGui/components/msgBox.nut")
let { getWeaponFullName } = require("%rGui/weaponry/weaponsVisual.nut")
let { mkSlotWeaponDesc } = require("unitModsSlotsDesc.nut")
let { markTextColor, warningTextColor, textColor } = require("%rGui/style/stdColors.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")
let { weaponSize, imgSize} = require("%rGui/respawn/respawnComps.nut")


let weaponCardsGap = evenPx(60)
let borderWidth = hdpxi(3)
let cardTextMargin = hdpx(6)
let cardMargin = [hdpx(10), 0]
let tooltipWidth = hdpx(600)
let caliberTriggers = ["additional gun", "machine gun", "cannon", "gunner"]

let mkText = @(text) msgBoxText(text, { size = [flex(), SIZE_TO_CONTENT], color = textColor })

function mkWeaponIcon(weapon) {
  let { iconType = "" } = weapon
  return @() {
    margin = borderWidth
    children = iconType == "" ? null
      : {
          size = [imgSize, imgSize]
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#{iconType}.avif:{imgSize}:{imgSize}:P")
          keepAspect = true
        }
  }
}

function mkWeaponCard(headerText, weapon, borderColor, txtColor) {
  let stateFlags = Watched(0)
  let key = {}
  let { guns = 1, totalBullets = 1, bulletSets, trigger} = weapon.weapons[0]
  let { mass = 0, caliber = 0 } = bulletSets?[""]
  let isCaliberTitle = caliberTriggers.contains(trigger)
  let wText = isCaliberTitle
    ? format(loc("caliber/mm"), caliber)
    : format(loc("mass/kg"), mass)

  let wCount = isCaliberTitle && guns > 1 ? format(loc("weapons/counter/right/short"), guns)
    : !isCaliberTitle && totalBullets > 1 ? format(loc("weapons/counter/right/short"), totalBullets)
    : null

  return {
    size = [SIZE_TO_CONTENT, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    margin = cardMargin
    padding = borderWidth
    gap = hdpx(5)
    children = [
      @(){
        key
        watch = stateFlags
        size = [weaponSize, weaponSize]
        rendObj = ROBJ_BOX
        fillColor = 0xFF45545D
        borderColor
        borderWidth
        behavior = Behaviors.Button
        onElemState = withTooltip(stateFlags, key, @() {
          content = mkSlotWeaponDesc(weapon, tooltipWidth),
          flow = FLOW_HORIZONTAL
        })
        onDetach = tooltipDetach(stateFlags)
        children = [
          mkWeaponIcon(weapon)
          msgBoxText(colorize(txtColor ?? borderColor, wText),
              { size = [flex(), SIZE_TO_CONTENT],
                halign = ALIGN_LEFT,
                valign = ALIGN_TOP,
                margin = [0, 0, 0, cardTextMargin]
              }).__update(fontVeryTinyShaded)
          !wCount ? null : msgBoxText(colorize(txtColor ?? borderColor, wCount),
            { size = flex(),
              halign = ALIGN_RIGHT,
              valign = ALIGN_BOTTOM,
              margin = [0, cardTextMargin, 0, 0]
            }).__update(fontVeryTinyShaded)
        ]
      }
      msgBoxText(headerText, {
        size = [flex(), SIZE_TO_CONTENT],
        halign = ALIGN_CENTER,
        color = textColor
      }).__update(fontTinyAccented)
    ]
  }
}

let vertList = @(children, ovr = {}) {
  size = [SIZE_TO_CONTENT, SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  gap = weaponCardsGap
  children
}.__update(ovr)

function mkConflictsMsgContent(weapon, conflicts) {
  let curWeaponName = colorize(markTextColor, getWeaponFullName(weapon.weapons[0], null)).replace(" ", nbsp)

  let curWeaponWithIcon = mkWeaponCard("", weapon, markTextColor, null)

  let conflictsComp = vertList(
    conflicts.map(
      @(v) mkWeaponCard(
        "".concat(loc("weapons/slotName/full", { slotIdx = v.slotIdx })),
        v.weapon,
        warningTextColor,
        textColor)))

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
      { id = "cancel", isCancel = true, styleId = "BRIGHT" }
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
    equippedWeaponsBySlots.get(), mirrorIdx.get() != -1 ? equipCurWeaponToWings : equipCurWeapon, @(list) equipWeaponListWithMirrors(list, curUnit.get().name))
  customEquipCurWeaponMsg
}