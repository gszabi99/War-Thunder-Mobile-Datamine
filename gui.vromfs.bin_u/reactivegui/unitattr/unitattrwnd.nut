from "%globalsDarg/darg_library.nut" import *
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkGamercardUnitCampaign } = require("%rGui/mainMenu/gamercard.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { unitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { levelHolderSize } = require("%rGui/unit/components/unitLevelComp.nut")
let { textButtonPrimary, buttonsHGap } = require("%rGui/components/textButton.nut")
let { textButtonVehicleLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { isUnitAttrOpened, attrUnitData, curCategory, curCategoryId, selAttrSpCost, leftUnitSp,
  isUnitMaxSkills, getSpCostText, resetAttrState, applyAttributes, availableAttributes,
  attrUnitLevelsToMax, attrUnitName, lastModifiedAttr
} = require("%rGui/unitAttr/unitAttrState.nut")
let { mkUnitAttrTabs, contentMargin } = require("%rGui/unitAttr/unitAttrWndTabs.nut")
let { unitAttrPage, rowsPosPadL, rowHeight } = require("%rGui/unitAttr/unitAttrWndPage.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let buyUnitLevelWnd = require("buyUnitLevelWnd.nut")
let { textColor, badTextColor } = require("%rGui/style/stdColors.nut")
let { backButtonBlink } = require("%rGui/components/backButtonBlink.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { tooltipBg } = require("%rGui/tooltip.nut")
let btnOpenUnitMods = require("%rGui/unitMods/btnOpenUnitMods.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")

isUnitAttrOpened.subscribe(function(v) {
  resetAttrState()
  sendNewbieBqEvent(v ? "openUnitAttributesWnd" : "closeUnitAttributesWnd")
})

let pageWidth = hdpx(855)
let attrDetailsWidth = hdpx(650)
let connectLineWidth = hdpx(50)
let tabW = hdpx(460)

let rowHighlightAnimDuration = 0.1
let attrRowHighlightColor = 0x052E2E2E

let isAttrDetailsVisible = Watched(false)
let showAttrStateFlags = Watched(0)
showAttrStateFlags.subscribe(@(sf) isAttrDetailsVisible(!!(sf & S_ACTIVE)))

let defCategoryImage = "ui/gameuiskin#upgrades_captain_icon.avif"
let categoryImages = {
  ship_commander = "ui/gameuiskin#upgrades_captain_icon.avif"
  ship_look_out_station = "ui/gameuiskin#upgrades_observation_icon.avif"
  ship_engine_room = "ui/gameuiskin#upgrades_mechanic_icon.avif"
  ship_artillery = "ui/gameuiskin#upgrades_artillery_icon.avif"
  ship_damage_control = "ui/gameuiskin#upgrades_torpedoes_icon.avif"
  ship_missiles = "ui/gameuiskin#upgrades_ship_rckt_weaponry_icon.avif"
  tank_fire_power = "ui/gameuiskin#upgrades_tank_firepower_icon.avif"
  tank_crew = "ui/gameuiskin#upgrades_tank_crew_icon.avif"
  tank_protection = "ui/gameuiskin#upgrades_tools_icon.avif"
}

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
    skipDirPadNav = true
    children = content
  }
}.__update(override)

let categoriesBlock = @() {
  watch = attrUnitData
  size = [ flex(), SIZE_TO_CONTENT ]
  flow = FLOW_VERTICAL
  children = mkUnitAttrTabs(attrUnitData.value.preset.map(@(page, idx) {
      id = page.id
      locId = loc($"attrib_section/{page.id}")
      image = categoryImages?[page.id] ?? defCategoryImage
      statusW = Computed(@() availableAttributes.value.statusByCat?[idx])
    }),
    curCategoryId
  )
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
  children = isAttrDetailsVisible.value
    ? @() tooltipBg.__merge({
        watch = [curCategory, lastModifiedAttr, isAttrDetailsVisible]
        size = [attrDetailsWidth, SIZE_TO_CONTENT]
        padding = 0
        fillColor = 0xA0000000
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            children = (curCategory.value?.attrList ?? [])
              .map(@(attr) mkAttrDetailsRow(attr.id, lastModifiedAttr.value))
          }
        ]
      })
    : null
}

let pageBlock = {
  rendObj = ROBJ_IMAGE
  size = [ SIZE_TO_CONTENT, flex() ]
  maxHeight = ph(100)
  pos = [ saBorders[0], 0 ]
  hplace = ALIGN_RIGHT
  image = Picture("ui/gameuiskin#debriefing_bg_grad@@ss.avif:0:P")
  color = Color(9, 15, 22, 96)
  padding = [ hdpx(15), saBorders[0] ]
  flow = FLOW_VERTICAL
  children = [
    @() !isUnitMaxSkills.value
      ? {
        watch = isUnitMaxSkills
        padding = [ 0, 0, 0, rowsPosPadL + levelHolderSize ]
        flow = FLOW_HORIZONTAL
        children = [
          txt({ text = "".concat(loc("unit/upgradePoints"), loc("ui/colon")) })
          @() txt({
            watch = leftUnitSp
            text = getSpCostText(leftUnitSp.value)
            color = leftUnitSp.value > 0 ? textColor : badTextColor
          })
        ]
      }
      : { watch = isUnitMaxSkills }
    { size = [ flex(), hdpx(60) ] }
    {
      size = [ pageWidth, flex() ]
      children = [
        mkVerticalPannableArea(unitAttrPage)
        attrDetails
      ]
    }
  ]
}

let applyAction = function() {
  applyAttributes()
  backButtonBlink("UnitAttr")
}

let actionButtons = @() {
  watch = [selAttrSpCost, attrUnitLevelsToMax, attrUnitName, attrUnitData]
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  gap = buttonsHGap * 0.5
  children = [
    textButtonPrimary(utf8ToUpper(loc("terms_wnd/more_detailed")), @() null,
      { hotkeys = ["^J:RB"], stateFlags = showAttrStateFlags, ovr = isWidescreen ? {} : { maxWidth = hdpx(510) } })
    attrUnitLevelsToMax.value <= 0 ? null
      : textButtonVehicleLevelUp(utf8ToUpper(loc("mainmenu/btnLevelBoost")),
        (attrUnitData.value?.unit.level ?? 0) + 1,
        @() buyUnitLevelWnd(attrUnitName.value), { hotkeys = ["^J:Y"] })
    selAttrSpCost.value <= 0 ? null
      : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_apply")), applyAction, {
          ovr = { sound = { click  = "characteristics_apply" } }.__update(isWidescreen ? {} : { minWidth = hdpx(250) })
          hotkeys = ["^J:X"]
        })
  ]
}

let navBar = mkSpinnerHideBlock(Computed(@() unitInProgress.value != null),
  actionButtons,
  {
    size = [ flex(), defButtonHeight ]
    halign = ALIGN_RIGHT
  })

function onClose() {
  if (selAttrSpCost.value == 0 || unitInProgress.value != null) //no need this message when apply unit stats is already in progress
    isUnitAttrOpened(false)
  else
    openMsgBox({
      text = loc("unitUpgrades/apply"),
      buttons = [
        { id = "cancel", isCancel = true }
        { id = "reset", cb = @() isUnitAttrOpened(false), hotkeys = ["^J:X"] }
        {
          id = "apply"
          styleId = "PRIMARY"
          isDefault = true
          cb = function() {
            applyAttributes()
            isUnitAttrOpened(false)
          }
        }
      ]
    })
}

let unitAttrWnd = {
  key = {}
  size = flex()
  padding = saBordersRv
  behavior = Behaviors.HangarCameraControl
  flow = FLOW_VERTICAL
  children = [
    @(){
      watch = curCampaign
      children = mkGamercardUnitCampaign(onClose, $"gamercard/levelUnitAttr/desc/{curCampaign.value}")
    }
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = hdpx(20)
      children = [
        {
          size = flex()
          flow = FLOW_VERTICAL
          children = [
            mkVerticalPannableArea(categoriesBlock, {
              size = [ tabW, flex() ]
              margin = [ hdpx(24), 0, 0, 0 ]
            })
            btnOpenUnitMods({
              hotkeys = ["^J:X"],
              ovr = {
                margin = [0, 0, 0, contentMargin]
                size = [isWidescreen ? (tabW - contentMargin) : SIZE_TO_CONTENT, defButtonHeight]
              },
            })
          ]
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

registerScene("unitAttrWnd", unitAttrWnd, @() isUnitAttrOpened(false), isUnitAttrOpened, false, @() selAttrSpCost.value <= 0)
