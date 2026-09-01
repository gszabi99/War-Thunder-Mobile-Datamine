from "%globalsDarg/darg_library.nut" import *
from "wt.behaviors" import HangarCameraControl
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/pServer/bqClient.nut" import sendNewbieBqEvent
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/pServerApi.nut" import unitInProgress
from "%rGui/attributes/attrBlockComp.nut" import rowHeight, pageWidth
from "%rGui/attributes/attrState.nut" import lastModifiedAttr, curCategoryId, getSpCostText
from "%rGui/attributes/attrValues.nut" import defCategoryImage, categoryImages
from "%rGui/attributes/attrWndTabs.nut" import mkAttrTabs
from "%rGui/attributes/slotAttr/slotAttrState.nut" import hasUpgradedAttrUnitNotUpdatable
import "%rGui/attributes/unitAttr/buyUnitLevelWnd.nut" as buyUnitLevelWnd
from "%rGui/attributes/unitAttr/unitAttrState.nut" import isUnitAttrOpened, attrUnitData, attrUnitName,
  attrUnitLevelsToMax, curCategory, selAttrSpCost, leftUnitSp, isUnitMaxSkills, availableAttributes, resetAttrState,
  applyAttributes
from "%rGui/attributes/unitAttr/unitAttrWndPage.nut" import unitAttrPage
from "%rGui/components/backButtonBlink.nut" import backButtonBlink
from "%rGui/components/buttonStyles.nut" import defButtonHeight, defButtonMinWidth, COMMON
from "%rGui/components/msgBox.nut" import openMsgBox, closeMsgBox
import "%rGui/components/panelBg.nut" as panelBg
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonPrimary, buttonsHGap, paddingX, mkCustomButton, mergeStyles
from "%rGui/mainMenu/gamercard.nut" import mkGamercardUnitCampaign
from "%rGui/navState.nut" import registerScene
from "%rGui/notifications/logEvents.nut" import sendTelemetryEvent
from "%rGui/style/gradients.nut" import gradTranspDoubleSideX, gradDoubleTexOffset
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import textColor, badTextColor
from "%rGui/tooltip.nut" import tooltipBg
from "%rGui/unit/components/textButtonWithLevel.nut" import textButtonVehicleLevelUp


const UNIT_ATTR_WND_MSG_UID = "msgUnitAttrWnd"

unitInProgress.subscribe(@(_) closeMsgBox(UNIT_ATTR_WND_MSG_UID))
isUnitAttrOpened.subscribe(function(v) {
  resetAttrState()
  sendNewbieBqEvent(v ? "openUnitAttributesWnd" : "closeUnitAttributesWnd")
})

const attrDetailsWidth = hdpx(650)
const connectLineWidth = hdpx(50)
const tabW = hdpx(460)

const rowHighlightAnimDuration = 0.1
const attrRowHighlightColor = 0x052E2E2E

let isAttrDetailsVisible = Watched(false)
let showAttrStateFlags = Watched(0)
showAttrStateFlags.subscribe(@(sf) isAttrDetailsVisible.set(!!(sf & S_ACTIVE)))

let txt = @(ovr) {
  rendObj = ROBJ_TEXT
  size = SIZE_TO_CONTENT
  color = textColor
}.__merge(fontTinyShaded, ovr)

let mkVerticalPannableArea = @(content, override = {}) {
  size = FLEX
  flow = FLOW_VERTICAL
  clipChildren = true
  children = {
    size = FLEX
    behavior = Behaviors.Pannable
    touchMarginPriority = TOUCH_BACKGROUND
    skipDirPadNav = true
    children = content
  }
}.__update(override)

let categoriesBlock = @() {
  watch = attrUnitData
  size = FLEX_H
  flow = FLOW_VERTICAL
  children = mkAttrTabs(attrUnitData.get().preset.map(@(page, idx) {
      id = page.id
      locId = loc($"attrib_section/{page.id}")
      image = categoryImages?[page.id] ?? defCategoryImage
      statusW = Computed(@() availableAttributes.get().statusByCat?[idx])
    }),
    curCategoryId
  )
}

let connectLine = tooltipBg.__merge({
  size = const [connectLineWidth, hdpxi(4)]
  vplace = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  pos = const [connectLineWidth, 0]
  padding = 0
})

let mkAttrDetailsText = @(attrId) {
  size = FLEX
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  margin = const [0, hdpx(24)]
  text = loc($"attr_desc/{attrId}")
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
}.__update(fontTinyAccentedShaded)

function mkAttrDetailsRow(attrId, lastModifiedAttrId) {
  let isLastModified = attrId == lastModifiedAttrId
  return {
    rendObj = ROBJ_9RECT
    size = [FLEX, rowHeight]
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
  pos = const [-(attrDetailsWidth + connectLineWidth), 0]
  children = isAttrDetailsVisible.get()
    ? @() tooltipBg.__merge({
        watch = [curCategory, lastModifiedAttr, isAttrDetailsVisible]
        size = const [attrDetailsWidth, SIZE_TO_CONTENT]
        padding = 0
        margin = const [hdpx(20),0,0]
        fillColor = 0xA0000000
        children = [
          {
            size = FLEX_H
            flow = FLOW_VERTICAL
            children = (curCategory.get()?.attrList ?? [])
              .map(@(attr) mkAttrDetailsRow(attr.id, lastModifiedAttr.get()))
          }
        ]
      })
    : null
}

let pageBlock = {
  size = FLEX_V
  hplace = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  children = [
    @() !isUnitMaxSkills.get()
      ? {
        watch = isUnitMaxSkills
        rendObj = ROBJ_SOLID
        color = 0xB0000000
        size = FLEX_H
        padding = const [hdpx(20), 0, hdpx(20), hdpx(130)]
        flow = FLOW_HORIZONTAL
        children = [
          txt({
            key = "unitUpgradePoints" 
            text = "".concat(loc("unit/upgradePoints"), loc("ui/colon"))
          })
          @() txt({
            watch = leftUnitSp
            key = "unitUpgradePointsValue" 
            text = getSpCostText(leftUnitSp.get())
            color = leftUnitSp.get() > 0 ? textColor : badTextColor
          })
        ]
      }
      : { watch = isUnitMaxSkills }
    {
      size = [ pageWidth, FLEX ]
      margin = const [hdpx(10),0,0]
      children = [
        panelBg.__merge(mkVerticalPannableArea(unitAttrPage))
        attrDetails
      ]
    }
  ]
}

let applyAction = function() {
  if(!hasUpgradedAttrUnitNotUpdatable()) {
    sendTelemetryEvent("add_unit_attributes")
  }
  applyAttributes()
  backButtonBlink("UnitAttr")
}

let mkMoreDetailBtn = @(text) {
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = hdpx(10)
  children = {
    maxWidth = defButtonMinWidth - 2 * paddingX
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    text
  }.__update(fontTinyAccentedShaded)
}

let actionButtons = @() {
  watch = [selAttrSpCost, attrUnitLevelsToMax, attrUnitName, attrUnitData]
  flow = FLOW_HORIZONTAL
  gap = buttonsHGap * 0.5
  children = [
    mkCustomButton(mkMoreDetailBtn(utf8ToUpper(loc("terms_wnd/more_detailed"))), @() null,
      mergeStyles(COMMON, { hotkeys = ["^J:RB"], stateFlags = showAttrStateFlags}))
    attrUnitLevelsToMax.get() <= 0 ? null
      : textButtonVehicleLevelUp(utf8ToUpper(loc("mainmenu/btnLevelBoost")),
          (attrUnitData.get()?.unit.level ?? 0) + 1,
          @() buyUnitLevelWnd(attrUnitName.get()),
          { hotkeys = ["^J:Y"], ovr = { key = "attrLevelBoostBtn" }}) 
    selAttrSpCost.get() <= 0 ? null
      : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_apply")), applyAction, {
          ovr = { sound = { click  = "characteristics_apply" } }.__update(isWidescreen ? {} : { minWidth = hdpx(250) })
          hotkeys = ["^J:X"]
        })
  ]
}

let navBar = mkSpinnerHideBlock(Computed(@() unitInProgress.get() != null),
  actionButtons,
  {
    size = [ FLEX, defButtonHeight ]
    halign = ALIGN_RIGHT
  })

function onClose() {
  if (selAttrSpCost.get() == 0 || unitInProgress.get() != null) 
    isUnitAttrOpened.set(false)
  else
    openMsgBox({
      uid = UNIT_ATTR_WND_MSG_UID
      text = loc("unitUpgrades/apply"),
      buttons = [
        { id = "cancel", isCancel = true }
        { id = "reset", cb = @() isUnitAttrOpened.set(false), hotkeys = ["^J:X"] }
        {
          id = "apply"
          styleId = "PRIMARY"
          isDefault = true
          cb = function() {
            applyAttributes()
            isUnitAttrOpened.set(false)
          }
        }
      ]
    })
}

let unitAttrWnd = {
  key = {}
  size = FLEX
  padding = saBordersRv
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
  flow = FLOW_VERTICAL
  children = [
    @(){
      watch = curCampaign
      children = mkGamercardUnitCampaign(onClose, getCampaignPresentation(curCampaign.get()).levelUnitAttrLocId)
    }
    {
      size = FLEX
      flow = FLOW_HORIZONTAL
      gap = hdpx(20)
      children = [
        mkVerticalPannableArea(categoriesBlock, {
          size = const [ tabW, FLEX ]
          margin = const [ hdpx(24), 0, 0, 0 ]
        })
        {
          size = FLEX
          flow = FLOW_VERTICAL
          gap = hdpx(20)
          children = [
            {
              size = FLEX
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

registerScene("unitAttrWnd", unitAttrWnd, @() isUnitAttrOpened.set(false), isUnitAttrOpened, false, @() selAttrSpCost.get() <= 0)
