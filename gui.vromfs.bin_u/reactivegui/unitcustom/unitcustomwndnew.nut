from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
let { HangarCameraControl } = require("wt.behaviors")
let { getUnitPresentation, getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { has_decals, allow_subscriptions } = require("%appGlobals/permissions.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { skinActionBtn, skinsBlockNoTags, skinsBlockWithTags } = require("%rGui/unitCustom/unitSkins/unitSkinsCompsNew.nut")
let { decalsCollection, selectedDecalId, availableDecals, decalsSlots, selectedSlotId, isPreparingToEditDecal,
  isEditingDecal, shouldSaveDecal, isAvailableSlot, exitDecalMode, customizationDecalId, editSelectedSlot,
  isManipulatorInProgress
} = require("%rGui/unitCustom/unitDecals/unitDecalsState.nut")
let { mkUnitInfo, mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitSlotLockedLine, unitPlateSmall
} = require("%rGui/unit/components/unitPlateComp.nut")
let { closeUnitCustom, unitCustomOpenCount, sectionsList, selSectionId, curSelectedSectionId, SECTION_IDS
} = require("%rGui/unitCustom/unitCustomState.nut")
let { curSelectedUnitId, baseUnit, platoonUnitsList, unitToShow, isCustomizationWndAttached
} = require("%rGui/unitDetails/unitDetailsState.nut")
let { doubleSideGradient, doubleSideGradientPaddingX, doubleSideGradientPaddingY
} = require("%rGui/components/gradientDefComps.nut")
let { mkSectionTabs, sectionBtnGap, gamercardHeight } = require("%rGui/unitCustom/unitCustomCompsNew.nut")
let { mkDecalsCollectionChoice } = require("%rGui/unitCustom/unitDecals/decalsCollectionChoice.nut")
let { selectedLineVertUnits, selLineSize } = require("%rGui/components/selectedLineUnits.nut")
let unitDecalsSlotsActions = require("%rGui/unitCustom/unitDecals/unitDecalsSlotsActions.nut")
let { decalsFooterHeight } = require("%rGui/unitCustom/unitDecals/unitDecalsComps.nut")
let mkDecalsSlots = require("%rGui/unitCustom/unitDecals/mkDecalsSlots.nut")
let { decalsEditor } = require("%rGui/unitCustom/unitDecals/unitDecalsEditor.nut")
let { hasTagsChoice } = require("%rGui/unitCustom/unitSkins/unitSkinsState.nut")
let buyDecalWnd = require("%rGui/unitCustom/unitDecals/buyDecalWnd.nut")
let { openSubsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { openShopWnd } = require("%rGui/shop/shopState.nut")
let { SC_PREMIUM } = require("%rGui/shop/shopCommon.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { registerScene } = require("%rGui/navState.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")


let unitColorLine = selectColor
let sectionBlockWidth = hdpx(600)

let isExpandedCustomSection = mkWatched(persist, "isExpandedCustomSection", true)
let openCount = Computed(@() has_decals.get() ? unitCustomOpenCount.get() : 0)
let isDecalSelected = Computed(@() customizationDecalId.get() != null)

function saveAndChangeTo(needSave, slotIdxToChange) {
  exitDecalMode(needSave)
  isPreparingToEditDecal.set(true)
  resetTimeout(0.1, function() {
    if (slotIdxToChange != null) {
      selectedSlotId.set(slotIdxToChange)
      editSelectedSlot()
    } else
      isPreparingToEditDecal.set(false)
    selectedDecalId.set(null)
  })
}

let askSaveAndChangeToSlot = @(slotIdxToChange = null) openMsgBox({
  text = loc("hudTuning/apply"),
  buttons = [
    {
      id = "reset"
      cb = @() saveAndChangeTo(false, slotIdxToChange)
    }
    {
      text = loc("filesystem/btnSave")
      styleId = "PRIMARY"
      isDefault = true
      cb = @() saveAndChangeTo(true, slotIdxToChange)
    }
  ]
})

function mkUnitPlate(unit, platoonUnit, onClick) {
  let p = getUnitPresentation(platoonUnit)
  let platoonUnitFull = unit.__merge(platoonUnit)
  let isPremium = !!(unit?.isPremium || unit?.isUpgraded)
  let isSelected = Computed(@() unitToShow.get()?.name == platoonUnit.name)
  let isLocked = Computed(@() !isPremium && platoonUnit.reqLevel > (campMyUnits.get()?[unit.name].level ?? 0))

  return {
    behavior = Behaviors.Button
    onClick
    sound = { click  = "choose" }
    margin = [0, 0, 0, selLineSize]
    children = [
      {
        watched = isLocked
        size = unitPlateSmall
        children = [
          mkUnitBg(unit, isLocked.get())
          mkUnitSelectedGlow(unit, isSelected)
          mkUnitImage(platoonUnitFull, isLocked.get())
          mkUnitTexts(platoonUnitFull, loc(p.locId), isLocked.get())
          !isLocked.get() ? mkUnitInfo(unit, { pos = [-hdpx(30), 0] }) : null
          mkUnitSlotLockedLine(platoonUnit, isLocked.get())
        ]
      }
      {
        size = [selLineSize, flex()]
        pos = [-selLineSize, 0]
        children = selectedLineVertUnits(isSelected, !!(unit?.isUpgraded || unit?.isPremium),
          unit?.isCollectible, { color = unitColorLine })
      }
    ]
  }
}

let platoonUnitsBlock = @() {
  watch = [baseUnit, platoonUnitsList, isEditingDecal, isDecalSelected]
  vplace = ALIGN_TOP
  hplace = ALIGN_LEFT
  flow = FLOW_VERTICAL
  clipChildren = true
  gap = sectionBtnGap
  minWidth = unitPlateSmall[0] + selLineSize
  children = platoonUnitsList.get().len() == 0 || isEditingDecal.get() || isDecalSelected.get() ? null
    : platoonUnitsList.get()
        .map(@(pu) mkUnitPlate(baseUnit.get(), pu, @() curSelectedUnitId.set(pu.name)))
}

let unitCustomizationGamercard = {
  size = [flex(), gamercardHeight]
  padding = saBordersRv
  flow = FLOW_HORIZONTAL
  children = [
    doubleSideGradient.__merge({
      size = [SIZE_TO_CONTENT, gamercardHeight]
      padding = [doubleSideGradientPaddingY, doubleSideGradientPaddingX, doubleSideGradientPaddingY, 0]
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = hdpx(50)
      children = [
        backButton(@() !isEditingDecal.get() ? closeUnitCustom()
          : shouldSaveDecal.get() ? askSaveAndChangeToSlot()
          : exitDecalMode())
        @() {
          watch = baseUnit
          rendObj = ROBJ_TEXT
          text = getPlatoonOrUnitName(baseUnit.get(), loc)
        }.__update(fontSmall)
      ]
    })
    { size = flex() }
    mkCurrenciesBtns([GOLD])
  ]
}

let sectionContentById = {
  [SECTION_IDS.SKINS] = @() {
    watch = [hasTagsChoice, unitToShow]
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = hdpx(50)
    children = !unitToShow.get() ? null
      : hasTagsChoice.get() ? skinsBlockWithTags
        : skinsBlockNoTags
    },
  [SECTION_IDS.DECALS] = @() {
    watch = [isEditingDecal, isDecalSelected]
    size = FLEX_H
    children = isEditingDecal.get() || isDecalSelected.get() ? null
      : mkDecalsCollectionChoice(decalsCollection, availableDecals, selectedDecalId,
          function(id) {
            if (id not in availableDecals.get())
              buyDecalWnd(id)
            else {
              selectedDecalId.set(id)
              selectedSlotId.set(null)
            }
          })
  }
}

let sectionFooterById = {
  [SECTION_IDS.SKINS] = {
    children = @() {
      watch = isExpandedCustomSection
      size = [pw(100), SIZE_TO_CONTENT]
      children = isExpandedCustomSection.get() ? skinActionBtn : null
    }
  },
  [SECTION_IDS.DECALS] = {
    footerHeight = decalsFooterHeight
    children = mkDecalsSlots(decalsSlots, selectedSlotId, customizationDecalId, function(id) {
      if (isAvailableSlot(id)) {
        if (id == selectedSlotId.get() || isPreparingToEditDecal.get())
          return
        let isSlotEmpty = decalsSlots.get()?[id].isEmpty ?? false
        if (isEditingDecal.get() && isSlotEmpty)
          return
        if (isEditingDecal.get() && !isSlotEmpty) {
          if (shouldSaveDecal.get())
            askSaveAndChangeToSlot(id)
          else
            saveAndChangeTo(false, id)
        }
        else {
          selectedSlotId.set(id)
          selectedDecalId.set(null)
        }
      }
      else {
        if (allow_subscriptions.get())
          openSubsPreview("vip")
        else
          openShopWnd(SC_PREMIUM)
      }
    })
  }
}

let sectionActionsById = {
  [SECTION_IDS.SKINS] = null,
  [SECTION_IDS.DECALS] = @() {
    watch = [isEditingDecal, customizationDecalId]
    children = customizationDecalId.get() == null
      ? unitDecalsSlotsActions
      : isEditingDecal.get() ? decalsEditor : null
  }
}

let sectionContent = @(curSectionId, isExpanded) @() {
  watch = curSectionId
  size = FLEX_H
  margin = [0, 0, sectionFooterById?[curSectionId.get()].footerHeight ?? 0, 0]
  animations = wndSwitchAnim
  children = isExpanded ? sectionContentById[curSectionId.get()] : null
  transform = { translate = [0, !isExpanded ? hdpx(200) : 0] }
  transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
}

let sectionFooter = @(curSectionId) @() {
  watch = [curSectionId, isManipulatorInProgress]
  size = [sectionBlockWidth, SIZE_TO_CONTENT]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  animations = wndSwitchAnim
  children = isManipulatorInProgress.get() ? null : sectionFooterById?[curSectionId.get()].children
}

let sectionActions = @(curSectionId) @() {
  watch = curSectionId
  hplace = ALIGN_LEFT
  vplace = ALIGN_BOTTOM
  animations = wndSwitchAnim
  children = sectionActionsById?[curSectionId.get()]
}

let sectionsBlock = @() {
  watch = [isExpandedCustomSection, isEditingDecal, customizationDecalId, sectionsList]
  size = [sectionBlockWidth, SIZE_TO_CONTENT]
  vplace = isExpandedCustomSection.get() ? ALIGN_TOP : ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  children = [
    isEditingDecal.get() || isDecalSelected.get() ? null
      : mkSectionTabs(sectionsList.get(), isExpandedCustomSection, curSelectedSectionId, @(id) selSectionId.set(id))
    sectionContent(curSelectedSectionId, isExpandedCustomSection.get())
  ]
}

let unitCustomWnd = {
  key = {}
  size = flex()
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  onAttach = @() isCustomizationWndAttached.set(true)
  onDetach = @() isCustomizationWndAttached.set(false)
  children = [
    unitCustomizationGamercard
    {
      size = flex()
      padding = saBordersRv
      children = [
        platoonUnitsBlock
        sectionsBlock
        sectionFooter(curSelectedSectionId)
        sectionActions(curSelectedSectionId)
      ]
    }
  ]
  animations = wndSwitchAnim
}

registerScene("unitCustomWndNew", unitCustomWnd, closeUnitCustom, openCount)
