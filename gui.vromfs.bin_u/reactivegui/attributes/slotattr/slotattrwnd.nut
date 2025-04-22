from "%globalsDarg/darg_library.nut" import *

let { utf8ToUpper } = require("%sqstd/string.nut")

let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { slotInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")

let { lastModifiedAttr, curCategoryId, getSpCostText } = require("%rGui/attributes/attrState.nut")
let { gamercardWithoutLevelBlock, gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let { textButtonVehicleLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { selectedSlotIdx, slots, maxSlotLevels } = require("%rGui/slotBar/slotBarState.nut")
let { defCategoryImage, categoryImages } = require("%rGui/attributes/attrValues.nut")
let { textButtonPrimary, buttonsHGap } = require("%rGui/components/textButton.nut")
let { slotAttrPage } = require("%rGui/attributes/slotAttr/slotAttrWndPage.nut")
let { doubleSideGradient } = require("%rGui/components/gradientDefComps.nut")
let { rowHeight, pageWidth } = require("%rGui/attributes/attrBlockComp.nut")
let { backButtonBlink } = require("%rGui/components/backButtonBlink.nut")
let { sendAppsFlyerEvent } = require("%rGui/notifications/logEvents.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { textColor, badTextColor } = require("%rGui/style/stdColors.nut")
let { gamercardGap } = require("%rGui/components/currencyStyles.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { isSlotAttrOpened, attrSlotData, slotUnitName, slotLevel,
  curCategory, applyAttributes, selAttrSpCost, slotLevelsToMax,
  isSlotMaxSkills, mkUnseenSlotAttrByIdx, resetAttrState, leftSlotSp,
  markSlotAttributesSeen, isSlotAttrAttached, hasUpgradedAttrUnitNotUpdatable
} = require("slotAttrState.nut")
let { mkAttrTabs } = require("%rGui/attributes/attrWndTabs.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { mkSlotLevelBlock } = require("slotLevelComp.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let panelBg = require("%rGui/components/panelBg.nut")
let { registerScene, setSceneBg } = require("%rGui/navState.nut")
let buySlotLevelWnd = require("buySlotLevelWnd.nut")
let { tooltipBg } = require("%rGui/tooltip.nut")


isSlotAttrOpened.subscribe(function(v) {
  resetAttrState()
  sendNewbieBqEvent(v ? "openSlotAttributesWnd" : "closeSlotAttributesWnd")
})

let attrDetailsWidth = hdpx(650)
let connectLineWidth = hdpx(50)
let tabW = hdpx(460)

let rowHighlightAnimDuration = 0.1
let attrRowHighlightColor = 0x052E2E2E

let isAttrDetailsVisible = Watched(false)
let showAttrStateFlags = Watched(0)
showAttrStateFlags.subscribe(@(sf) isAttrDetailsVisible(!!(sf & S_ACTIVE)))

let txt = @(ovr) {
  rendObj = ROBJ_TEXT
  size = SIZE_TO_CONTENT
  color = textColor
  fontFx = FFT_GLOW
  fontFxFactor = hdpx(64)
  fontFxColor = 0xFF000000
}.__merge(fontTiny, ovr)

let mkVerticalPannableArea = @(content, override = {}) {
  size = flex()
  flow = FLOW_VERTICAL
  clipChildren = true
  children = {
    size = flex()
    behavior = Behaviors.Pannable
    touchMarginPriority = TOUCH_BACKGROUND
    skipDirPadNav = true
    children = content
  }
}.__update(override)

function categoriesBlock() {
  let unseenSlotAttrByIdx = mkUnseenSlotAttrByIdx(selectedSlotIdx.get())
  return {
    watch = [attrSlotData, selectedSlotIdx]
    size = [ flex(), SIZE_TO_CONTENT ]
    flow = FLOW_VERTICAL
    children = mkAttrTabs(attrSlotData.get().preset.map(@(page, idx) {
        id = page.id
        locId = loc($"attrib_section/{page.id}")
        image = categoryImages?[page.id] ?? defCategoryImage
        statusW = Computed(@() unseenSlotAttrByIdx.get().statusByCat?[idx])
      }),
      curCategoryId
    )
  }
}

let connectLine = tooltipBg.__merge({
  size = [connectLineWidth, hdpxi(4)]
  vplace = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  pos = [connectLineWidth, 0]
  padding = 0
})

let mkAttrDetailsText = @(attrId) {
  size = flex()
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  margin = [0, hdpx(24)]
  text = loc($"attr_desc/{attrId}")
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
}.__update(fontTiny)

function mkAttrDetailsRow(attrId, lastModifiedAttrId) {
  let isLastModified = attrId == lastModifiedAttrId
  return {
    rendObj = ROBJ_9RECT
    size = [flex(), rowHeight]
    image = gradTranspDoubleSideX
    texOffs = [0 , gradDoubleTexOffset]
    screenOffs = [0, hdpx(80)]
    color = isLastModified ? attrRowHighlightColor : 0
    transitions = [{ prop = AnimProp.color, duration = rowHighlightAnimDuration }]
    children = [
      mkAttrDetailsText(attrId)
      isLastModified ? connectLine : null
    ]
  }
}

let attrDetails = @() {
  watch = isAttrDetailsVisible
  pos = [-(attrDetailsWidth + connectLineWidth), 0]
  children = isAttrDetailsVisible.get()
    ? @() tooltipBg.__merge({
        watch = [curCategory, lastModifiedAttr, isAttrDetailsVisible]
        size = [attrDetailsWidth, SIZE_TO_CONTENT]
        padding = 0
        margin = [hdpx(20),0,0]
        fillColor = 0xA0000000
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            children = (curCategory.get()?.attrList ?? [])
              .map(@(attr) mkAttrDetailsRow(attr.id, lastModifiedAttr.get()))
          }
        ]
      })
    : null
}

let pageBlock = {
  size = [ SIZE_TO_CONTENT, flex() ]
  hplace = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  children = [
    @() !isSlotMaxSkills.get()
      ? {
        watch = isSlotMaxSkills
        rendObj = ROBJ_SOLID
        color = 0xB0000000
        size = [flex(), SIZE_TO_CONTENT]
        padding = [hdpx(20), 0, hdpx(20), hdpx(130)]
        margin = [0, 0, hdpx(10), 0]
        flow = FLOW_HORIZONTAL
        children = [
          txt({
            key = "upgradePoints" 
            text = "".concat(loc("unit/upgradePoints"), loc("ui/colon"))
          })
          @() txt({
            watch = leftSlotSp
            key = "upgradePointsValue" 
            text = getSpCostText(leftSlotSp.get())
            color = leftSlotSp.get() > 0 ? textColor : badTextColor
          })
        ]
      }
      : { watch = isSlotMaxSkills }
    {
      size = [ pageWidth, flex() ]
      children = [
        panelBg.__merge(mkVerticalPannableArea(slotAttrPage))
        attrDetails
      ]
    }
  ]
}

let applyAction = function() {
  if (!hasUpgradedAttrUnitNotUpdatable() && slots.get().findindex(@(slot) slot.attrLevels.len() > 0 ) == null)
    sendAppsFlyerEvent("slot_upgrade_crew_1")
  applyAttributes()
  backButtonBlink("UnitAttr")
}

let actionButtons = @() {
  watch = [selAttrSpCost, slotLevelsToMax, selectedSlotIdx, attrSlotData]
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  gap = buttonsHGap * 0.5
  children = [
    textButtonPrimary(utf8ToUpper(loc("terms_wnd/more_detailed")), @() null,
      { hotkeys = ["^J:RB"], stateFlags = showAttrStateFlags, ovr = isWidescreen ? {} : { maxWidth = hdpx(510) } })
    slotLevelsToMax.get() <= 0 ? null
      : textButtonVehicleLevelUp(utf8ToUpper(loc("mainmenu/btnLevelBoost")),
        (slotLevel.get() ?? 0) + 1,
        @() buySlotLevelWnd(selectedSlotIdx.get()), { hotkeys = ["^J:Y"] })
    selAttrSpCost.get() <= 0 ? null
      : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_apply")), applyAction, {
          ovr = {
            sound = { click  = "characteristics_apply" }
            key = "slotAttrApplyBtn" 
          }.__update(isWidescreen ? {} : { minWidth = hdpx(250) })
          hotkeys = ["^J:X"]
        })
  ]
}

let navBar = mkSpinnerHideBlock(Computed(@() slotInProgress.get() != null),
  actionButtons,
  {
    size = [ flex(), defButtonHeight ]
    halign = ALIGN_RIGHT
  })

function onClose() {
  if (selAttrSpCost.get() == 0 || slotInProgress.get() != null) 
    isSlotAttrOpened.set(false)
  else
    openMsgBox({
      text = loc("unitUpgrades/apply"),
      buttons = [
        { id = "cancel", isCancel = true }
        { id = "reset", cb = @() isSlotAttrOpened.set(false), hotkeys = ["^J:X"] }
        {
          id = "apply"
          styleId = "PRIMARY"
          isDefault = true
          cb = function() {
            applyAttributes()
            isSlotAttrOpened.set(false)
          }
        }
      ]
    })
}

let mkSlotUnitName = @() @(){
  watch = slotUnitName
  maxWidth = hdpx(800)
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFE0E0E0
  text = slotUnitName.get() == ""
    ? loc("gamercard/slot/blank")
    : loc("gamercard/slot/unitName",
        { unitName = colorize(0xFFC59E49, loc(getUnitLocId(slotUnitName.get()))) })
}.__update(fontVeryTinyAccented)

let slotTitle = @(slot, text) {
  minWidth = hdpx(500)
  children = [
    {
      pos = [0, -hdpx(10)]
      rendObj = ROBJ_TEXT
      color = textColor
      fontFx = FFT_GLOW
      fontFxColor = 0xFF000000
      fontFxFactor = hdpx(64)
      text
    }.__update(fontSmall)
    mkSlotLevelBlock(slot, maxSlotLevels.get())
  ]
}

let gamercardSlotLevelLine = @(slot, keyHintText, idx, slotNameBlock){
  children = [
    slotTitle(slot, loc("gamercard/slot/title", { idx = idx + 1 }))
    doubleSideGradient.__merge({
      padding = [hdpx(5), 0]
      pos = [0, hdpx(55)]
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children = [
        {
          halign = ALIGN_LEFT
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          maxWidth = hdpx(700)
          text = (slot?.level ?? -1) == 100
            ? loc("gamercard/slot/maxLevel/description")
            : loc(keyHintText)
        }.__update(fontVeryTiny)
        slotNameBlock != null ? slotNameBlock() : null
      ]
    })
  ]
}

let mkLeftBlockSlotCampaign = @(backCb, keyHintText, slotNameBlock) @() {
  watch = [selectedSlotIdx, slots]
  size = [SIZE_TO_CONTENT, gamercardHeight]
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_LEFT
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = [
    backCb != null ? backButton(backCb, { vplace = ALIGN_CENTER }) : null
    gamercardSlotLevelLine(slots.get()[selectedSlotIdx.get()],
      keyHintText,
      selectedSlotIdx.get(),
      slotNameBlock)
  ]
}

let mkGamercardSlotCampaign = @(backCb, keyHintText, slotNameBlock = null){
  size = [ saSize[0], gamercardHeight ]
  hplace = ALIGN_CENTER
  children = [
    mkLeftBlockSlotCampaign(backCb, keyHintText, slotNameBlock)
    gamercardWithoutLevelBlock
  ]
}

let slotAttrWnd = {
  key = {}
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  onAttach = @() isSlotAttrAttached.set(true)
  function onDetach() {
    isSlotAttrAttached.set(false)
    markSlotAttributesSeen(selectedSlotIdx.get())
  }
  children = [
    mkGamercardSlotCampaign(onClose, $"gamercard/slot/level/description",  mkSlotUnitName)
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = hdpx(20)
      margin = [hdpx(25), 0, 0, 0]
      children = [
        {
          size = flex()
          flow = FLOW_VERTICAL
          children = mkVerticalPannableArea(categoriesBlock, {
            size = [ tabW, flex() ]
          })
        }
        {
          size = flex()
          flow = FLOW_VERTICAL
          gap = hdpx(20)
          children = [
            {
              size = flex()
              children = pageBlock
            }
            navBar
          ]
        }
      ]
    }
  ]
  animations = wndSwitchAnim
}

registerScene("slotAttrWnd", slotAttrWnd, @() isSlotAttrOpened.set(false), isSlotAttrOpened, false, @() selAttrSpCost.get() <= 0)
setSceneBg("slotAttrWnd", "ui/images/air_crew_bg.avif")
