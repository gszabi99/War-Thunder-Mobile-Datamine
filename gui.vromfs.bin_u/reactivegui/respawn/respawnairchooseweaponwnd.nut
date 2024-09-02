from "%globalsDarg/darg_library.nut" import *
let { ceil, round_by_value } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkCutBg } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { mkWeaponStates } = require("%rGui/unitMods/unitModsSlotsState.nut")
let { getWeaponDescList, getBulletBeltShortName, getBulletBeltFullName } = require("%rGui/weaponry/weaponsVisual.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { mkLevelLockSmall, mkNotPurchasedShade, mkModCost } = require("%rGui/unitMods/modsComps.nut")
let { CS_TINY } = require("%rGui/components/currencyStyles.nut")
let { weaponPreset, selectedSlotWeaponName, equippedWeaponsBySlots, wCards, beltCards,
  canShowChooseBulletWnd, curUnit, curModPresetCfg, curUnitAllModsCost,
  selectedBeltWeaponId, selectedBeltCardIdx, selectedWSlotIdx, selectedBeltCard, selectedBeltSlot,
  selectedWCardIdx, selectedWCard, selectedWCardStates, selectedBeltCardStates,
  applyBelt, closeWnd, equipSelWeapon, unequipSelWeapon,
  selectWeaponSlot, selectBeltSlot, selectWeaponCard, selectBeltCard,
  overloadInfo, fixCurPresetOverload
} = require("respawnAirChooseState.nut")
let { sendPlayerActivityToServer } = require("playerActivity.nut")

let { padding, weaponSize, smallGap, commonWeaponIcon, getWeaponTitle, mkBeltImage,
  secondaryMenuKey, secondaryTitleKey, turretMenuKey, turretTitleKey, courseMenuKey, courseTitleKey
} = require("respawnComps.nut")
let { badTextColor2, commonTextColor } = require("%rGui/style/stdColors.nut")

let SLOTS_IN_ROW = 5
let CARDS_IN_ROW = 6
let paddingWnd = hdpx(10)
let WND_UID = "respawn_choose_secondary_wnd"
let wndKey = {}

let showAirRespChooseSecWnd = @(wSlotIdx) selectWeaponSlot(wSlotIdx)
let showAirRespChooseBeltWnd = @(weaponId) selectBeltSlot(weaponId)

function closeWithWarning() {
  let { overloads = [] } = overloadInfo.get()
  if (overloads.len() == 0) {
    closeWnd()
    return
  }
  sendPlayerActivityToServer()
  openMsgBox({
    text = loc("weapons/pilonsRemoveWarning", {
      warnings = colorize(badTextColor2, "\n".join(overloads))
    })
    buttons = [
      { text = loc("btn/autoRemovePilons"),
        function cb() {
          fixCurPresetOverload()
          closeWnd()
        }
      }
      { text = loc("btn/fixItMyself"), styleId = "PRIMARY", isCancel = true
        cb = sendPlayerActivityToServer
      }
    ]
  })
}

let mkCardBase = {
  behavior = Behaviors.Button
  size = [weaponSize, weaponSize]
  rendObj = ROBJ_BOX
  fillColor = 0xFF45545D
  borderWidth = hdpx(3)
  borderColor = 0xFFFFFFFF
}

let mkSlotBase = @(slotIdx, ovr = {}) @() mkCardBase.__merge({
  watch = selectedWSlotIdx
  borderColor = slotIdx == selectedWSlotIdx.get() ? 0xC07BFFFF : 0xFFFFFFFF
  borderWidth = slotIdx == selectedWSlotIdx.get() ? hdpx(5) : hdpx(3)
  fillColor = 0xFF45545D
  onClick = @() selectWeaponSlot(slotIdx)
}, ovr)

let mkLevelLockInfo = @(isLocked, reqLevel) @() {
  watch = [isLocked, reqLevel]
  margin = [hdpxi(5), 0]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  children = !isLocked.get() ? null
    : reqLevel.get() > 0 ? mkLevelLockSmall(reqLevel.get())
    : {
        margin = hdpxi(10)
        size = [hdpxi(25), hdpxi(35)]
        rendObj = ROBJ_IMAGE
        color = 0xFFAA1111
        image =  Picture($"ui/gameuiskin#lock_icon.svg:{hdpxi(25)}:{hdpxi(35)}:P")
      }
}

function mkWeaponCard(w) {
  let { reqLevel, isLocked, isPurchased, mod } = mkWeaponStates(Computed(@() wCards.get()?[w.slotIdx]), curModPresetCfg, curUnit)
  return @() mkCardBase.__merge({
    watch = selectedWCardIdx
    borderColor = w.slotIdx == selectedWCardIdx.get() ? 0xC07BFFFF : 0xFFFFFFFF
    borderWidth = w.slotIdx == selectedWCardIdx.get() ? hdpx(5) : hdpx(3)
    onClick = @() selectWeaponCard(w.slotIdx)
    padding
    children = [
      commonWeaponIcon(w)
      mkNotPurchasedShade(isPurchased)
      mkLevelLockInfo(isLocked, reqLevel)
      mkModCost(isPurchased, isLocked, mod, curUnitAllModsCost, CS_TINY)
    ]
  })
}

let mkSlotText = @(text) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
  text
  behavior = Behaviors.Marquee
  delay = defMarqueeDelay
  speed = hdpx(30)
}.__update(fontVeryTinyShaded)

function mkBeltCard(w) {
  let { reqLevel, isLocked, isPurchased, mod } =
    mkWeaponStates(Computed(@() beltCards.get()?[w.slotIdx]), curModPresetCfg, curUnit)
  return @() mkCardBase.__merge({
    watch = selectedBeltCardIdx
    borderColor = w.slotIdx == selectedBeltCardIdx.get() ? 0xC07BFFFF : 0xFFFFFFFF
    borderWidth = w.slotIdx == selectedBeltCardIdx.get() ? hdpx(5) : hdpx(3)
    onClick = @() selectBeltCard(w.slotIdx)
    padding
    children = [
      mkBeltImage(w?.bullets ?? [])
      {
        size = [flex(), SIZE_TO_CONTENT]
        fillColor = 0x44000000
        rendObj = ROBJ_BOX
        children = mkSlotText(getBulletBeltShortName(w.id))
      }
      mkNotPurchasedShade(isPurchased)
      mkLevelLockInfo(isLocked, reqLevel)
      mkModCost(isPurchased, isLocked, mod, curUnitAllModsCost, CS_TINY)
    ]
  })
}

function mkWeaponSlot(w, slotIdx) {
  let title = getWeaponTitle(w)
  return mkSlotBase(slotIdx, {
    children = [
      {
        padding
        children = commonWeaponIcon(w)
      }
      title == "" ? null
        : {
            size = [flex(), SIZE_TO_CONTENT]
            padding = [hdpx(4), 0, 0, hdpx(8)]
            rendObj = ROBJ_BOX
            fillColor = 0x44000000
            children = {
              rendObj = ROBJ_TEXT
              color = 0xFFFFFFFF
              text = title
            }.__update(fontVeryTinyShaded)
          }
    ]
  })
}

let mkRowGroup = @(children) {
  size = flex()
  flow = FLOW_HORIZONTAL
  gap = smallGap
  children
}

function overloadInfoBlock() {
  let { massInfo = "", overloads = [] } = overloadInfo.get()
  if (massInfo == "" && overloads.len() == 0)
    return { watch = overloadInfo }
  local overText = overloads.len() == 0 ? ""
    : colorize(badTextColor2, "\n".join(overloads))
  return {
    watch = overloadInfo
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    color = commonTextColor
    text = "\n".join([massInfo, overText], true)
  }.__update(fontTiny)
}

function chooseSecondarySlotWnd() {
  let watchList = [equippedWeaponsBySlots, selectedWSlotIdx]
  if (selectedWSlotIdx.get() == null)
    return { watch = watchList }

  let weaponSlots = equippedWeaponsBySlots.get()
    .slice(1) //0 slot is not secondary weapons
    .map(@(w, idx) w == null ? mkSlotBase(idx + 1)
      : mkWeaponSlot(w, idx + 1))
  let rows = ceil(1.0 * weaponSlots.len() / SLOTS_IN_ROW)

  return {
    watch = watchList
    size = [
      flex(),
      weaponSize * rows + smallGap * (rows - 1) + paddingWnd * 2
    ]
    flow = FLOW_VERTICAL
    gap = smallGap
    children = selectedWSlotIdx.get() == null ? null : array(rows)
      .map(@(_, idx) mkRowGroup(weaponSlots.slice(idx * SLOTS_IN_ROW, (idx + 1) * SLOTS_IN_ROW)))
  }
}

let mkLeftBlock = @(pos) {
  size = [weaponSize * SLOTS_IN_ROW + smallGap * (SLOTS_IN_ROW - 1) + paddingWnd * 2, SIZE_TO_CONTENT]
  pos = [pos.l, pos.t]
  padding = paddingWnd
  stopMouse = true
  rendObj = ROBJ_SOLID
  color = 0xA0000000
  flow = FLOW_VERTICAL
  gap = smallGap
  children = [
    chooseSecondarySlotWnd
    overloadInfoBlock
  ]
}

function weaponCardsContent() {
  let weaponCards = wCards.get().len() > 0 ? wCards.get().map(@(w) mkWeaponCard(w))
    : beltCards.get().len() > 0 ? beltCards.get().map(@(w) mkBeltCard(w))
    : []

  let rows = ceil(1.0 * weaponCards.len() / CARDS_IN_ROW)
  return {
    watch = [wCards, beltCards]
    size = [
      SIZE_TO_CONTENT,
      weaponSize * rows + smallGap * (rows - 1)
    ]
    flow = FLOW_VERTICAL
    gap = smallGap
    children = array(rows)
      .map(@(_, idx) mkRowGroup(weaponCards.slice(idx * CARDS_IN_ROW, (idx + 1) * CARDS_IN_ROW)))
  }
}

function getWeaponDescription(weapon) {
  if (weapon == null)
    return ""
  let { weapons, mass } = weapon
  let resArr = getWeaponDescList(weapons)
  if (mass > 0)
    resArr.append("".concat(loc("stats/mass"), colon, round_by_value(mass, 0.1), loc("measureUnits/kg")))
  return "\n".join(resArr)
}

function getWeaponInfo(isLocked, isPurchased, reqLevel, mod) {
  if (isLocked)
    return reqLevel > 0 ? loc("respawn/need_to_unlock_weapon") : loc("respawn/locked_weapon")
  return !isPurchased && mod != null ? loc("respawn/need_to_buy_weapon") : ""
}

let mkWeaponTitle = @(weaponTitle) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFFFFFFF
  text = weaponTitle != "" ? weaponTitle : loc("respawn/select_weapon")
}.__update(fontTiny)

let mkInfoContentBase = @(weaponTitle, infoTitle) {
  size = [flex(), SIZE_TO_CONTENT]
  margin = [0, 0, hdpx(10), 0]
  flow = FLOW_VERTICAL
  children = [
    mkWeaponTitle(weaponTitle)
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = 0xFFFFFFFF
      text = infoTitle
    }.__update(fontTiny)
  ]
}

function mkWeaponInfoContent() {
  let { isLocked, isPurchased, mod, reqLevel } = selectedWCardStates
  return function() {
    let weaponDesc = getWeaponDescription(selectedWCard.get())
    let infoTitle = getWeaponInfo(isLocked.get(), isPurchased.get(), reqLevel.get(), mod.get())
    return mkInfoContentBase(weaponDesc, infoTitle).__update({
      watch = [selectedWCard, isLocked, isPurchased, reqLevel, mod]
    })
  }
}

function mkBeltInfoContent() {
  let { isLocked, isPurchased, mod, reqLevel } = selectedBeltCardStates
  return function() {
    let { id = null, caliber = null } = selectedBeltCard.get()
    let weaponTitle = id == null ? "" : getBulletBeltFullName(id, caliber)
    let infoTitle = getWeaponInfo(isLocked.get(), isPurchased.get(), reqLevel.get(), mod.get())
    return mkInfoContentBase(weaponTitle, infoTitle).__update({
      watch = [selectedBeltCard, isLocked, isPurchased, reqLevel, mod]
    })
  }
}

let mkContentByType = @(weaponContent, beltContent) @() {
  watch = [selectedWSlotIdx, selectedBeltWeaponId]
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = selectedWSlotIdx.get() != null ? weaponContent
    : selectedBeltWeaponId.get() != null ? beltContent
    : null
}

let mkInfoContent = mkContentByType(mkWeaponInfoContent(), mkBeltInfoContent())

let btnOvrStyle = { ovr = { minWidth = weaponSize * (CARDS_IN_ROW / 2) + smallGap * (CARDS_IN_ROW / 2 - 1) } }
function mkSecondaryButtons() {
  let { isPurchased } = selectedWCardStates
  return @() {
    watch = [selectedSlotWeaponName, selectedWCard, isPurchased]
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = smallGap
    children = [
      selectedWCard.get() == null || !isPurchased.get()
          ? null
        : selectedWCard.get().name == selectedSlotWeaponName.get()
          ? textButtonPrimary(utf8ToUpper(loc("msgbox/btn_remove")), unequipSelWeapon, btnOvrStyle)
        : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_choose")), equipSelWeapon, btnOvrStyle)
    ]
  }
}

let mkBeltButtons = @() {
  watch = selectedBeltCard
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = selectedBeltCard.get() == null ? null
    : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_choose")),
      @() applyBelt(selectedBeltSlot.get().weaponId, selectedBeltCard.get().id), btnOvrStyle)
}

let mkButtonsContent = mkContentByType(mkSecondaryButtons(), mkBeltButtons)

let chooseSecondaryWeaponWnd = @(pos, titleRect) {
  pos = [0, pos.t - 2 * (titleRect.b - titleRect.t + smallGap)]
  size = [
    weaponSize * CARDS_IN_ROW + smallGap * (CARDS_IN_ROW - 1) + paddingWnd * 2,
    SIZE_TO_CONTENT
  ]
  stopMouse = true
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_SOLID
  color = 0xA0000000
  flow = FLOW_VERTICAL
  padding = paddingWnd
  maxHeight = saSize[1]
  gap = smallGap
  children = [
    weaponCardsContent
    mkInfoContent
    mkButtonsContent
  ]
}

function getRectsToCut() {
  let res = []
  if (selectedWSlotIdx.get() != null)
    res.append(gui_scene.getCompAABBbyKey(secondaryTitleKey))
  if (selectedBeltWeaponId.get() != null)
    res.extend([courseTitleKey, courseMenuKey, turretTitleKey, turretMenuKey].map(gui_scene.getCompAABBbyKey))
  return res
}
let getMenuPos = @() selectedWSlotIdx.get() != null ? gui_scene.getCompAABBbyKey(secondaryMenuKey) : null

function content() {
  if (weaponPreset.get() == null || !canShowChooseBulletWnd.get())
    return { watch = [weaponPreset, canShowChooseBulletWnd]}

  let rects = getRectsToCut()
  let menuRectIdx = 1
  let pos = rects?[menuRectIdx] ?? getMenuPos()
  if (rects.len() == 0 || pos == null)
    return { watch = [weaponPreset, canShowChooseBulletWnd] }

  let titleRectIdx = 0
  return {
    key = wndKey
    watch = [weaponPreset, canShowChooseBulletWnd]
    size = flex()
    children = [
      mkCutBg(rects)
      mkLeftBlock(pos)
      chooseSecondaryWeaponWnd(pos, rects[titleRectIdx])
    ]
    onDetach = closeWnd
  }
}

let openImpl = @() addModalWindow({
  key = WND_UID
  size = flex()
  children = content
  onClick = closeWithWarning
  stopMouse = true
})

if (canShowChooseBulletWnd.get())
  openImpl()
canShowChooseBulletWnd.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))

return {
  showAirRespChooseSecWnd
  showAirRespChooseBeltWnd
}