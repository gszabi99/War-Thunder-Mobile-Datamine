from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { mkCutBg } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { openMsgBox, msgBoxBg, msgBoxHeader } = require("%rGui/components/msgBox.nut")
let { getBulletBeltShortName } = require("%rGui/weaponry/weaponsVisual.nut")
let { textButtonPrimary, textButtonCommon, textButtonMultiline } = require("%rGui/components/textButton.nut")
let { mkLevelLockSmall, mkNotPurchasedShade, mkModCost } = require("%rGui/unitMods/modsComps.nut")
let { CS_TINY } = require("%rGui/components/currencyStyles.nut")
let { selectedSlotWeaponName, equippedWeaponsBySlots, wCards, beltCards,
  canShowChooseBulletWnd, curUnit, curModPresetCfg, curUnitAllModsCost,
  selectedBeltWeaponId, selectedBeltCardIdx, selectedWSlotIdx, selectedBeltCard, selectedBeltSlot,
  selectedWCardIdx, selectedWCard, selectedWCardStates, selectedBeltCardStates,
  applyBelt, closeWnd, equipSelWeapon, unequipSelWeapon, equipWeaponListWithMirrors,
  selectWeaponSlot, selectBeltSlot, selectWeaponCard, selectBeltCard,
  overloadInfo, fixCurPresetOverload, courseBeltSlots, turretBeltSlots, mirrorIdx,
  unequipSelWeaponFromWings, equipSelWeaponToWings
} = require("respawnAirChooseState.nut")
let { mkWeaponStates, getConflictsList, mkHasConflicts } = require("%rGui/unitMods/unitModsSlotsState.nut")
let { customEquipCurWeaponMsg } = require("%rGui/unitMods/equipSlotWeaponMsgBox.nut")
let { sendPlayerActivityToServer } = require("playerActivity.nut")
let { mkBeltDesc, mkSlotWeaponDesc } = require("%rGui/unitMods/unitModsSlotsDesc.nut")
let { padding, weaponSize, smallGap, commonWeaponIcon, getWeaponTitle, mkBeltImage,
  header, headerText, caliberTitle, headerHeight, defPadding, imgSize
} = require("respawnComps.nut")
let { badTextColor2, commonTextColor, warningTextColor } = require("%rGui/style/stdColors.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")


let connectingLineWidth = hdpx(4)
let cellGap = connectingLineWidth * 4
let cellSizeWithGap = weaponSize + cellGap
let SLOTS_IN_ROW = 5
let CARDS_IN_ROW = 5
let wndSize = @(cells) cellSizeWithGap * cells - cellGap
let infoBlockWidth = wndSize(CARDS_IN_ROW)
let infoBlockHeight = hdpx(700)
let paddingWnd = hdpx(10)
let contentGap = hdpx(20)
let infoDescriptionWidth = infoBlockWidth - paddingWnd * 2
let WND_UID = "respawn_choose_secondary_wnd"
let wndKey = {}

let cardBgColor = 0xFF45545D
let cardBgConflictColor = 0xFF65343D

let WEAPON = "weapon"
let BELT = "belt"
let contentType = Computed(@() selectedWSlotIdx.get() != null ? WEAPON
  : selectedBeltWeaponId.get() != null ? BELT
  : null)

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
  fillColor = cardBgColor
  borderWidth = hdpx(3)
  borderColor = 0xFFFFFFFF
}

let mkSlotBase = @(isSelected) mkCardBase.__merge({
  borderColor = isSelected ? 0xC07BFFFF : 0xFFFFFFFF
  borderWidth = isSelected ? hdpx(5) : hdpx(3)
  fillColor = cardBgColor
})

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

let mkPaddingTitleCtor = @(isSelected) array(4, isSelected ? padding : defPadding)

function getTitlePaddingTop(isSelected) {
  let res = mkPaddingTitleCtor(isSelected)
  res[2] = 0
  return res
}

function getTitlePaddingBottom(isSelected) {
  let res = mkPaddingTitleCtor(isSelected)
  res[0] = 0
  return res
}

let mkSlotTitle = @(title, isSelected, ovr = {}) title == "" ? null
  : {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_BOX
      fillColor = 0x44000000
      padding = [hdpx(1), isSelected ? padding : defPadding]
      children = {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXT
        color = 0xFFFFFFFF
        text = title
        hplace = ALIGN_CENTER
        behavior = Behaviors.Marquee
        delay = defMarqueeDelay
        speed = hdpx(30)
      }.__update(fontVeryTinyShaded)
    }.__update(ovr)

function mkWeaponCard(w) {
  let { reqLevel, isLocked, isPurchased, mod } = mkWeaponStates(Computed(@() wCards.get()?[w.slotIdx]), curModPresetCfg, curUnit)
  let hasConflicts = mkHasConflicts(Watched(w), equippedWeaponsBySlots)
  return @() mkCardBase.__merge({
    watch = [selectedWCardIdx, hasConflicts]
    fillColor = hasConflicts.get() ? cardBgConflictColor : cardBgColor
    borderColor = w.slotIdx == selectedWCardIdx.get() ? 0xC07BFFFF : 0xFFFFFFFF
    borderWidth = w.slotIdx == selectedWCardIdx.get() ? hdpx(5) : hdpx(3)
    onClick = @() selectWeaponCard(w.slotIdx)
    sound = { click = "choose" }
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        padding
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
        children = commonWeaponIcon(w)
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        padding = getTitlePaddingTop(w.slotIdx == selectedWCardIdx.get())
        vplace = ALIGN_TOP
        hplace = ALIGN_CENTER
        children = mkSlotTitle(getWeaponTitle(w), w.slotIdx == selectedWCardIdx.get())
      }
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
  hplace = ALIGN_CENTER
  behavior = Behaviors.Marquee
  delay = defMarqueeDelay
  speed = hdpx(30)
}.__update(fontVeryTinyShaded)

function mkBeltCard(w) {
  let { reqLevel, isLocked, isPurchased, mod } =
    mkWeaponStates(Computed(@() beltCards.get()?[w.slotIdx]), curModPresetCfg, curUnit)
  let isSelected = Computed(@() w.slotIdx == selectedBeltCardIdx.get())
  return @() mkCardBase.__merge({
    watch = isSelected
    borderColor = isSelected.get() ? 0xC07BFFFF : 0xFFFFFFFF
    borderWidth = isSelected.get() ? padding : defPadding
    onClick = @() selectBeltCard(w.slotIdx)
    sound = { click = "choose" }
    children = [
      mkBeltImage(w?.bullets ?? [], isSelected.get() ? imgSize : weaponSize - defPadding * 2)
      {
        size = [flex(), SIZE_TO_CONTENT]
        padding = getTitlePaddingTop(isSelected.get())
        children = {
          size = [flex(), SIZE_TO_CONTENT]
          fillColor = 0x44000000
          rendObj = ROBJ_BOX
          padding = [hdpx(2), isSelected.get() ? padding : defPadding]
          children = mkSlotText(getBulletBeltShortName(w.id))
        }
      }
      mkNotPurchasedShade(isPurchased)
      mkLevelLockInfo(isLocked, reqLevel)
      mkModCost(isPurchased, isLocked, mod, curUnitAllModsCost, CS_TINY)
    ]
  })
}

let mkBeltSlot = @(w, slotIdx, isSelected) mkSlotBase(isSelected).__update({
  onClick = @() selectBeltSlot(slotIdx)
  sound = { click = "choose" }
  children = [
    mkBeltImage(w.equipped?.bullets ?? [], isSelected ? imgSize : weaponSize - defPadding * 2)
    {
      size = [flex(), SIZE_TO_CONTENT]
      padding = getTitlePaddingTop(isSelected)
      vplace = ALIGN_TOP
      hplace = ALIGN_CENTER
      children = mkSlotTitle(caliberTitle(w), isSelected)
    }
    {
      size = [flex(), SIZE_TO_CONTENT]
      padding = getTitlePaddingBottom(isSelected)
      vplace = ALIGN_BOTTOM
      hplace = ALIGN_CENTER
      children = mkSlotTitle(getBulletBeltShortName(w.equipped?.id), isSelected)
    }
  ]
})
let mkEmptyWeaponSlot = @(slotIdx, isSelected)
  mkSlotBase(isSelected).__update({ onClick = @() selectWeaponSlot(slotIdx), sound = { click = "choose" } })
function mkWeaponSlot(w, slotIdx, isSelected) {
  let hasConflicts = Computed(@() selectedWCard.get()?.banPresets[slotIdx][w?.name] ?? false)
  return @() mkEmptyWeaponSlot(slotIdx, isSelected).__update({
    watch = hasConflicts
    fillColor = hasConflicts.get() ? cardBgConflictColor : cardBgColor
    children = [
      {
        padding
        children = commonWeaponIcon(w)
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        padding = getTitlePaddingTop(isSelected)
        vplace = ALIGN_TOP
        hplace = ALIGN_CENTER
        children = mkSlotTitle(getWeaponTitle(w), isSelected)
      }
    ]
  })
}

let mkRowGroup = @(children) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = cellGap
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

let calcRowsByElems = @(elems, elemsInRow) ceil(1.0 * elems.len() / elemsInRow)
let arrayToRows = @(elems, elemsInRow, ovr = {}) array(calcRowsByElems(elems, elemsInRow))
  .map(@(_, idx) mkRowGroup(elems.slice(idx * elemsInRow, (idx + 1) * elemsInRow)).__update(ovr))

let mkGroup = @(children) {
  rendObj = ROBJ_BOX
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  fillColor = 0xA0000000
  children
}

function mkChooseBeltSlotWnd() {
  let watchList = [courseBeltSlots, turretBeltSlots, selectedBeltWeaponId]
  let selectedWeaponId = selectedBeltWeaponId.get()
  if (selectedWeaponId == null)
    return { watch = watchList }

  let courseSlots = courseBeltSlots.get().map(@(w) mkBeltSlot(w, w.weaponId, w.weaponId == selectedWeaponId))
  let turretSlots = turretBeltSlots.get().map(@(w) mkBeltSlot(w, w.weaponId, w.weaponId == selectedWeaponId))
  let courseSlotsRows = arrayToRows(courseSlots, SLOTS_IN_ROW, { halign = ALIGN_CENTER, padding = paddingWnd })
  let turretSlotsRows = arrayToRows(turretSlots, SLOTS_IN_ROW, { halign = ALIGN_CENTER, padding = paddingWnd })
  return {
    watch = watchList
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = contentGap
    children = [
      courseSlotsRows.len() <= 0 ? null
        : mkGroup([header(headerText(loc("weaponry/courseGunBelts")))].extend(courseSlotsRows))
      turretSlotsRows.len() <= 0 ? null
        : mkGroup([header(headerText(loc("weaponry/turretGunBelts")))].extend(turretSlotsRows))
    ]
  }
}

function mkChooseSecondarySlotWnd() {
  let watchList = [equippedWeaponsBySlots, selectedWSlotIdx]
  let selectedIdx = selectedWSlotIdx.get()
  if (selectedIdx == null)
    return { watch = watchList }

  let weaponSlots = equippedWeaponsBySlots.get()
    .slice(1) //0 slot is not secondary weapons
    .map(@(w, idx) w == null ? mkEmptyWeaponSlot(idx + 1, idx + 1 == selectedIdx)
      : mkWeaponSlot(w, idx + 1, idx + 1 == selectedIdx))

  return {
    watch = watchList
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = cellGap
    children = arrayToRows(weaponSlots, SLOTS_IN_ROW)
  }
}

let mkContentByType = @(weaponContentCtor, beltContentCtor, size = [flex(), SIZE_TO_CONTENT]) @() {
  watch = contentType
  size
  halign = ALIGN_CENTER
  children = contentType.get() == WEAPON ? weaponContentCtor()
    : contentType.get() == BELT ? beltContentCtor()
    : null
}

let wndSizeWithPadding = @(cells) wndSize(cells) + paddingWnd * 2
let leftBlockWidth = wndSizeWithPadding(SLOTS_IN_ROW)
let mkWeaponLeftBlock = {
  size = [leftBlockWidth, SIZE_TO_CONTENT]
  padding = paddingWnd
  stopMouse = true
  rendObj = ROBJ_SOLID
  color = 0xA0000000
  flow = FLOW_VERTICAL
  gap = smallGap
  children = [
    mkChooseSecondarySlotWnd
    overloadInfoBlock
  ]
}

let mkBeltLeftBlock = {
  size = [leftBlockWidth, SIZE_TO_CONTENT]
  stopMouse = true
  flow = FLOW_VERTICAL
  children = mkChooseBeltSlotWnd
}

let mkLeftBlock = mkContentByType(@() mkWeaponLeftBlock, @() mkBeltLeftBlock, null)

function mkCardsContent() {
  let weaponCards = wCards.get().len() > 0 ? wCards.get().map(@(w) mkWeaponCard(w))
    : beltCards.get().len() > 0 ? beltCards.get().map(@(w) mkBeltCard(w))
    : []

  let rows = calcRowsByElems(weaponCards, CARDS_IN_ROW)
  return {
    watch = [wCards, beltCards]
    size = [SIZE_TO_CONTENT, wndSize(rows)]
    flow = FLOW_VERTICAL
    gap = cellGap
    children = arrayToRows(weaponCards, CARDS_IN_ROW)
  }
}

function getRequirementsText(isLocked, isPurchased, reqLevel, mod) {
  if (isLocked)
    return reqLevel > 0 ? loc("respawn/need_to_unlock_weapon") : loc("respawn/locked_weapon")
  return !isPurchased && mod != null ? loc("respawn/need_to_buy_weapon") : ""
}

let mkRequirementsTextComp = @(isLocked, isPurchased, reqLevel, mod) {
  size = [infoBlockWidth, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = warningTextColor
  text = getRequirementsText(isLocked, isPurchased, reqLevel, mod)
}.__update(fontTiny)

let selectInfo = {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = commonTextColor
  text = loc("respawn/select_weapon")
}.__update(fontTiny)

function mkWeaponInfoContent() {
  let { isLocked, isPurchased, mod, reqLevel } = selectedWCardStates
  return @() {
    watch = [selectedWCard, isLocked, isPurchased, reqLevel, mod, equippedWeaponsBySlots]
    size = [infoDescriptionWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = selectedWCard.get() == null ? selectInfo
      : [
        mkSlotWeaponDesc(selectedWCard.get(), infoDescriptionWidth, getConflictsList(selectedWCard.get(), equippedWeaponsBySlots.get()))
          mkRequirementsTextComp(isLocked.get(), isPurchased.get(), reqLevel.get(), mod.get())
        ]
  }
}

function mkBeltInfoContent() {
  let { isLocked, isPurchased, mod, reqLevel } = selectedBeltCardStates
  return @() {
    watch = [selectedBeltCard, isLocked, isPurchased, reqLevel, mod]
    size = [infoDescriptionWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = selectedBeltCard.get() == null ? selectInfo
      : [
          mkBeltDesc(selectedBeltCard.get(), infoDescriptionWidth)
          mkRequirementsTextComp(isLocked.get(), isPurchased.get(), reqLevel.get(), mod.get())
        ]
  }
}

let mkInfoContent = mkContentByType(mkWeaponInfoContent, mkBeltInfoContent)

let getUninstallWeaponBtn = @() mirrorIdx.get() != -1
  ? textButtonMultiline(utf8ToUpper(loc("mod/disable/both_wings")), unequipSelWeaponFromWings, buttonStyles.PRIMARY)
  : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_remove")), unequipSelWeapon)

let getInstallWeaponBtn = @() mirrorIdx.get() != -1
  ? textButtonMultiline(utf8ToUpper(loc("mod/enable/both_wings")),
    @() customEquipCurWeaponMsg(selectedWSlotIdx.get(), selectedWCard.get(),
      equippedWeaponsBySlots.get(), equipSelWeaponToWings, equipWeaponListWithMirrors), buttonStyles.PRIMARY)
  : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_choose")),
    @() customEquipCurWeaponMsg(selectedWSlotIdx.get(), selectedWCard.get(),
      equippedWeaponsBySlots.get(), equipSelWeapon, equipWeaponListWithMirrors))


function mkSecondaryButtons() {
  let { isPurchased } = selectedWCardStates
  return @() {
    watch = [selectedSlotWeaponName, selectedWCard, isPurchased]
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = smallGap
    children = selectedWCard.get() == null || !isPurchased.get()
        ? null
      : selectedWCard.get().name == selectedSlotWeaponName.get()
        ? getUninstallWeaponBtn()
        : getInstallWeaponBtn()
  }
}

function mkBeltButtons() {
  let { isLocked, isPurchased, mod, reqLevel } = selectedBeltCardStates
  return @(){
    watch = [selectedBeltCard , selectedBeltSlot, isLocked, isPurchased]
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = selectedBeltCard.get() == null || selectedBeltSlot.get()?.equipped.id == selectedBeltCard.get().id ? null
      : isLocked.get() || !isPurchased.get()
    ? textButtonCommon(utf8ToUpper(loc("msgbox/btn_choose")),
        @() openMsgBox({ text = getRequirementsText(isLocked.get(), isPurchased.get(), reqLevel.get(), mod.get()) }))
      : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_choose")),
          @() applyBelt(selectedBeltSlot.get().weaponId, selectedBeltCard.get().id))

  }
}

let mkButtonsContent = mkContentByType(mkSecondaryButtons, mkBeltButtons)

let chooseCardWnd = {
  size = [wndSizeWithPadding(CARDS_IN_ROW), infoBlockHeight]
  borderColor = 0xC07BFFFF
  borderWidth = hdpx(6)
  stopMouse = true
  rendObj = ROBJ_BOX
  fillColor = 0xA0000000
  flow = FLOW_VERTICAL
  padding = paddingWnd
  gap = smallGap
  children = [
    mkCardsContent
    makeVertScroll(mkInfoContent)
    mkButtonsContent
  ]
}

let linesBase = {
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = connectingLineWidth
  color = 0xC07BFFFF
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  commands = [
    [VECTOR_LINE, 0, 0, 0, 50],
    [VECTOR_LINE, 0, 50, 100, 50]
  ]
}

let lineWidthByXPos = @(x) wndSize(x) + paddingWnd - weaponSize / 2
let mkWeaponLines = @() function() {
  let idx = selectedWSlotIdx.get()
  if (idx == null)
    return { watch = selectedWSlotIdx }
  let x = (idx - 1) % SLOTS_IN_ROW + 1
  let y = (idx - 1) / SLOTS_IN_ROW + 1
  return linesBase.__merge({
    watch = selectedWSlotIdx
    pos = [lineWidthByXPos(x), wndSize(y) + paddingWnd]
    size = [lineWidthByXPos(SLOTS_IN_ROW - x + 1) + contentGap, cellGap]
  })
}

let mkBeltLines = @() function() {
  let cBeltSlots = courseBeltSlots.get()
  let tBeltSlots = turretBeltSlots.get()
  let beltWeaponId = selectedBeltWeaponId.get()
  let courseBeltSlotIdx = cBeltSlots.findindex(@(s) s.weaponId == beltWeaponId)
  let turretBeltSlotIdx = courseBeltSlotIdx == null ? tBeltSlots.findindex(@(s) s.weaponId == beltWeaponId) : null
  let idx = courseBeltSlotIdx ?? turretBeltSlotIdx
  if (idx == null)
    return { watch = [selectedBeltWeaponId, courseBeltSlots, turretBeltSlots] }

  let beltsLength = courseBeltSlotIdx != null ? cBeltSlots.len() : tBeltSlots.len()
  let isCenteredLine = beltsLength % 2 != 0
  let xShift = (idx - beltsLength / 2) * cellSizeWithGap + (isCenteredLine ? 0 : (cellSizeWithGap / 2))
  let yBlockShift = headerHeight + paddingWnd + weaponSize
  let yShift = cBeltSlots.len() == 0 || tBeltSlots.len() == 0 || turretBeltSlotIdx == null ? 0
    : paddingWnd + contentGap + yBlockShift
  return linesBase.__merge({
    watch = [selectedBeltWeaponId, courseBeltSlots, turretBeltSlots]
    pos = [leftBlockWidth / 2 + xShift, yBlockShift + yShift]
    size = [lineWidthByXPos((SLOTS_IN_ROW + 1) / 2) + contentGap - xShift, cellGap]
  })
}

let mkLines = mkContentByType(mkWeaponLines, mkBeltLines, null)
let contentHeader = mkContentByType(
  @() msgBoxHeader(loc("weaponry/secondaryWeapons")),
  @() msgBoxHeader(loc("weaponry/gunBelts")))

let mainContent = msgBoxBg.__merge({
  flow = FLOW_VERTICAL
  children = [
    contentHeader
    {
      padding = contentGap
      children = [
        {
          minHeight = wndSize(3)
          flow = FLOW_HORIZONTAL
          gap = contentGap
          children = [
            mkLeftBlock
            chooseCardWnd
          ]
        }
        mkLines
      ]
    }
  ]
})

function content() {
  let res = { watch = canShowChooseBulletWnd }
  if (!canShowChooseBulletWnd.get())
    return res

  return res.__update({
    key = wndKey
    size = flex()
    children = [
      mkCutBg([])
      mainContent
    ]
    onDetach = closeWnd
  })
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