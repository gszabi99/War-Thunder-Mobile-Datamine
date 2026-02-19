from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
let { HangarCameraControl } = require("wt.behaviors")
let { getUnitPresentation, getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { allow_subscriptions } = require("%appGlobals/permissions.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { skinActionBtn, skinsBlockNoTags, skinsBlockWithTags } = require("%rGui/unitCustom/unitSkins/unitSkinsComps.nut")
let { decalsCollection, selectedDecalId, availableDecals, decalsSlots, selectedSlotId, isPreparingToEditDecal,
  isEditingDecal, shouldSaveDecal, isAvailableSlot, exitDecalMode, customizationDecalId, editSelectedSlot,
  isManipulatorInProgress, decalsCfg, decalsPenalty, selectedSlot
} = require("%rGui/unitCustom/unitDecals/unitDecalsState.nut")
let { mkUnitInfo, mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitSlotLockedLine, unitPlateSmall
} = require("%rGui/unit/components/unitPlateComp.nut")
let { closeUnitCustom, unitCustomOpenCount, sectionsList, selSectionId, curSelectedSectionId, SECTION_IDS
} = require("%rGui/unitCustom/unitCustomState.nut")
let { curSelectedUnitId, baseUnit, platoonUnitsList, unitToShow, isCustomizationWndAttached
} = require("%rGui/unitDetails/unitDetailsState.nut")
let { doubleSideGradient, doubleSideGradientPaddingX, doubleSideGradientPaddingY
} = require("%rGui/components/gradientDefComps.nut")
let { mkSectionTabs, sectionBtnGap, gamercardHeight } = require("%rGui/unitCustom/unitCustomComps.nut")
let { mkDecalsCollectionChoice } = require("%rGui/unitCustom/unitDecals/decalsCollectionChoice.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { selectedLineVertUnits, selLineSize } = require("%rGui/components/selectedLineUnits.nut")
let unitDecalsSlotsActions = require("%rGui/unitCustom/unitDecals/unitDecalsSlotsActions.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset, simpleHorGrad } = require("%rGui/style/gradients.nut")
let { decalsFooterHeight, getDecalTitle, getDecalDesc, mkDecalIcon } = require("%rGui/unitCustom/unitDecals/unitDecalsComps.nut")
let { unseenDecals, markDecalSeen } = require("%rGui/unitCustom/unitDecals/unseenDecals.nut")
let { decalsEditor } = require("%rGui/unitCustom/unitDecals/unitDecalsEditor.nut")
let { hasTagsChoice } = require("%rGui/unitCustom/unitSkins/unitSkinsState.nut")
let mkDecalsSlots = require("%rGui/unitCustom/unitDecals/mkDecalsSlots.nut")
let buyDecalWnd = require("%rGui/unitCustom/unitDecals/buyDecalWnd.nut")
let { openSubsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")
let { openShopWnd } = require("%rGui/shop/shopState.nut")
let { SC_PREMIUM } = require("%rGui/shop/shopCommon.nut")
let { registerScene } = require("%rGui/navState.nut")


let unitColorLine = selectColor
let sectionBlockWidth = hdpx(600)

let isExpandedCustomSection = mkWatched(persist, "isExpandedCustomSection", true)
let isDecalSelected = Computed(@() customizationDecalId.get() != null)

let hasUnseenBySection = Computed(@() {
  [SECTION_IDS.DECALS] = unseenDecals.get().len() > 0
})

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

let mkPenaltyText = @(text) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(700)
  halign = ALIGN_LEFT
  text
}.__update(fontTinyAccented)

function penaltyDescription() {
  let timeToEndDecalsPenalty = Computed(@() decalsPenalty.get() - serverTime.get())

  return @() {
    watch = timeToEndDecalsPenalty
    pos = [0, hdpx(50)]
    vplace = ALIGN_TOP
    hplace = ALIGN_LEFT
    flow = FLOW_VERTICAL
    gap = sectionBtnGap
    rendObj = ROBJ_9RECT
    image = gradTranspDoubleSideX
    texOffs = [0, gradDoubleTexOffset]
    screenOffs = [0, hdpx(50)]
    color = 0x90000000
    padding = [hdpx(10), hdpx(30)]
    children = timeToEndDecalsPenalty.get() <= 0 ? null
      : [
          mkPenaltyText(loc("msgbox/decalsPenalty"))
          mkPenaltyText($"{loc("time_to_end_penalty")} {secondsToHoursLoc(timeToEndDecalsPenalty.get())}")
        ]
    }
}

let mkDecalText = @(text, ovr = {}) text == null ? null : {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_LEFT
  maxWidth = hdpx(500)
  text
}.__update(fontSmallShadedBold, ovr)

let decalBlockGap = hdpx(10)

function decalDescriptionBlock() {
  let decalId = Computed(@() selectedDecalId.get() ?? selectedSlot.get()?.decalId ?? "")
  let decalDesc = mkDecalText(getDecalDesc(decalId.get()), fontSmallShaded)
  let decalDescHeight = min(calc_comp_size(decalDesc)[1], hdpx(500))
  return {
    watch = [decalId, curSelectedSectionId]
    vplace = ALIGN_TOP
    hplace = ALIGN_LEFT
    flow = FLOW_VERTICAL
    gap = decalBlockGap
    children = curSelectedSectionId.get() != SECTION_IDS.DECALS || decalId.get() == "" ? null : {
      padding = decalBlockGap
      rendObj = ROBJ_IMAGE
      image = simpleHorGrad
      color = 0xAA000000
      flipX = true
      flow = FLOW_VERTICAL
      gap = decalBlockGap
      children = [
        mkDecalText(getDecalTitle(decalId.get())),
        makeVertScroll(
          decalDesc,
          {
            size = [SIZE_TO_CONTENT, decalDescHeight]
            isBarOutside = true
        }),
        mkDecalIcon(decalId.get())
      ]}}}

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
      : mkDecalsCollectionChoice(decalsCollection, availableDecals, selectedDecalId, unseenDecals,
          function(id) {
            markDecalSeen(id)
            if (id in availableDecals.get()) {
              selectedDecalId.set(id)
              selectedSlotId.set(null)
            }
            else if ((decalsCfg.get()?[id].price.currencyId ?? "") != "")
              buyDecalWnd(id)
            else
              openMsgBox({ text = loc("decal/notAvailable") })
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
          openSubsPreview("vip", "unit_custom")
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
  watch = [isExpandedCustomSection, isEditingDecal, customizationDecalId, sectionsList, hasUnseenBySection]
  size = [sectionBlockWidth, SIZE_TO_CONTENT]
  vplace = isExpandedCustomSection.get() ? ALIGN_TOP : ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  children = [
    isEditingDecal.get() || isDecalSelected.get() ? null
      : mkSectionTabs(sectionsList.get(), isExpandedCustomSection, hasUnseenBySection.get(), curSelectedSectionId,
          @(id) selSectionId.set(id))
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
        decalDescriptionBlock
        platoonUnitsBlock
        penaltyDescription()
        sectionsBlock
        sectionFooter(curSelectedSectionId)
        sectionActions(curSelectedSectionId)
      ]
    }
  ]
  animations = wndSwitchAnim
}

registerScene("unitCustomWnd", unitCustomWnd, closeUnitCustom, unitCustomOpenCount)
