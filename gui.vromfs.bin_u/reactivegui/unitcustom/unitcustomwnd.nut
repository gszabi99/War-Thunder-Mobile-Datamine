from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
from "math" import round
from "wt.behaviors" import HangarCameraControl
from "%appGlobals/config/decalsPresentation.nut" import getDecalDescPresentation
from "%appGlobals/currenciesState.nut" import GOLD
from "%appGlobals/permissions.nut" import allow_subscriptions
from "%appGlobals/timeToText.nut" import secondsToHoursLoc
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/gradientDefComps.nut" import headerGradientWithRightBlock
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/mainMenu/gamercard.nut" import mkCurrenciesBtns
from "%rGui/navState.nut" import registerScene
from "%rGui/shop/goodsPreviewState.nut" import openSubsPreview
from "%rGui/shop/shopCommon.nut" import SC_PREMIUM
from "%rGui/shop/shopState.nut" import openShopWnd
from "%rGui/style/gradients.nut" import gradTranspDoubleSideX, gradDoubleTexOffset, simpleHorGrad
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/unitCustom/unitCustomComps.nut" import mkSectionTabs, sectionBtnGap
from "%rGui/unitCustom/unitCustomState.nut" import closeUnitCustom, unitCustomOpenCount, sectionsList, selSectionId,
  curSelectedSectionId, SECTION_IDS
import "%rGui/unitCustom/unitDecals/buyDecalWnd.nut" as buyDecalWnd
from "%rGui/unitCustom/unitDecals/decalsCollectionChoice.nut" import mkDecalsCollectionChoice
import "%rGui/unitCustom/unitDecals/mkDecalsSlots.nut" as mkDecalsSlots
from "%rGui/unitCustom/unitDecals/unitDecalsComps.nut" import decalsFooterHeight, getDecalTitle, getDecalDesc,
  mkDecalIcon, decalIconSizeBig
from "%rGui/unitCustom/unitDecals/unitDecalsEditor.nut" import decalsEditor
import "%rGui/unitCustom/unitDecals/unitDecalsSlotsActions.nut" as unitDecalsSlotsActions
from "%rGui/unitCustom/unitDecals/unitDecalsState.nut" import decalsCollection, selectedDecalId, availableDecals,
  decalsSlots, selectedSlotId, isPreparingToEditDecal, isEditingDecal, shouldSaveDecal, isAvailableSlot, exitDecalMode,
  customizationDecalId, editSelectedSlot, isManipulatorInProgress, decalsCfg, decalsPenalty, selectedSlot
from "%rGui/unitCustom/unitDecals/unseenDecals.nut" import unseenDecals, markDecalSeen
from "%rGui/unitCustom/unitSkins/unitSkinsComps.nut" import skinActionBtn, skinsBlockNoTags, skinsBlockWithTags
from "%rGui/unitCustom/unitSkins/unitSkinsState.nut" import hasTagsChoice
from "%rGui/unitDetails/unitDetailsState.nut" import baseUnit, unitToShow, isCustomizationWndAttached


const sectionBlockWidth = hdpx(600)

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
    pos = const [0, hdpx(50)]
    vplace = ALIGN_TOP
    hplace = ALIGN_LEFT
    flow = FLOW_VERTICAL
    gap = sectionBtnGap
    rendObj = ROBJ_9RECT
    image = gradTranspDoubleSideX
    texOffs = [0, gradDoubleTexOffset]
    screenOffs = [0, hdpx(50)]
    color = 0x90000000
    padding = const [hdpx(10), hdpx(30)]
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
}.__update(fontBoldSmallShaded, ovr)

function decalDescriptionBlock() {
  let decalId = Computed(@() selectedDecalId.get() ?? selectedSlot.get()?.decalId ?? "")
  let decalDesc = mkDecalText(getDecalDesc(decalId.get()), fontSmallShaded)
  let decalDescHeight = min(calc_comp_size(decalDesc)[1], hdpx(500))
  return {
    watch = [decalId, curSelectedSectionId]
    vplace = ALIGN_TOP
    hplace = ALIGN_LEFT
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    children = curSelectedSectionId.get() != SECTION_IDS.DECALS || decalId.get() == "" ? null
      : [
          {
            pos = [-saBorders[0], 0]
            rendObj = ROBJ_IMAGE
            image = simpleHorGrad
            color = 0x80000000
            flipX = true
            padding = [hdpx(10), saBorders[0], hdpx(20), saBorders[0]]
            flow = FLOW_VERTICAL
            gap = sectionBtnGap
            children = [
              mkDecalText(getDecalTitle(decalId.get()))
              makeVertScroll(
                decalDesc,
                {
                  size = [SIZE_TO_CONTENT, decalDescHeight]
                  isBarOutside = true
              })
            ]
          }
          mkDecalIcon(decalId.get(), round(decalIconSizeBig * getDecalDescPresentation(decalId.get()).scale).tointeger())
        ]
  }
}

let header = headerGradientWithRightBlock(
  [
    backButton(@() !isEditingDecal.get() ? closeUnitCustom()
      : shouldSaveDecal.get() ? askSaveAndChangeToSlot()
      : exitDecalMode())
    @() {
      watch = baseUnit
      rendObj = ROBJ_TEXT
      text = getUnitName(baseUnit.get())
    }.__update(fontSmall)
  ],
  mkCurrenciesBtns([GOLD]))

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
      size = const [pw(100), SIZE_TO_CONTENT]
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
  size = const [sectionBlockWidth, SIZE_TO_CONTENT]
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
  size = const [sectionBlockWidth, SIZE_TO_CONTENT]
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
  size = FLEX
  padding = saBordersRv
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
  flow = FLOW_VERTICAL
  onAttach = @() isCustomizationWndAttached.set(true)
  onDetach = @() isCustomizationWndAttached.set(false)
  children = [
    header
    {
      size = FLEX
      children = [
        decalDescriptionBlock
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
