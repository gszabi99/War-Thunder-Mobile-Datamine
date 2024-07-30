from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkGamercardUnitCampaign } = require("%rGui/mainMenu/gamercard.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { unitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { textButtonPrimary, buttonsHGap } = require("%rGui/components/textButton.nut")
let { textButtonVehicleLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { isUnitAttrOpened, attrUnitData, curCategory, curCategoryId, selAttrSpCost, leftUnitSp,
  isUnitMaxSkills, getSpCostText, resetAttrState, applyAttributes, availableAttributes,
  attrUnitLevelsToMax, attrUnitName, lastModifiedAttr
} = require("%rGui/unitAttr/unitAttrState.nut")
let { mkUnitAttrTabs, contentMargin } = require("%rGui/unitAttr/unitAttrWndTabs.nut")
let { unitAttrPage, rowHeight } = require("%rGui/unitAttr/unitAttrWndPage.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let buyUnitLevelWnd = require("buyUnitLevelWnd.nut")
let { textColor, badTextColor } = require("%rGui/style/stdColors.nut")
let { backButtonBlink } = require("%rGui/components/backButtonBlink.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let panelBg = require("%rGui/components/panelBg.nut")
let { tooltipBg } = require("%rGui/tooltip.nut")
let btnOpenUnitMods = require("%rGui/unitMods/btnOpenUnitMods.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { sendAppsFlyerEvent } = require("%rGui/notifications/logEvents.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

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
  plane_flight_performance = "ui/gameuiskin#upgrades_flight_performance.avif"
  plane_crew = "ui/gameuiskin#upgrades_plane_crew.avif"
  plane_weapon = "ui/gameuiskin#upgrades_plane_weapon.avif"
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
        margin = [hdpx(20),0,0]
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
  size = [ SIZE_TO_CONTENT, flex() ]
  hplace = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  children = [
    @() !isUnitMaxSkills.value
      ? {
        watch = isUnitMaxSkills
        rendObj = ROBJ_SOLID
        color = 0xB0000000
        size = [flex(), SIZE_TO_CONTENT]
        padding = [hdpx(20), 0, hdpx(20), hdpx(130)]
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
    {
      size = [ pageWidth, flex() ]
      margin = [hdpx(10),0,0]
      children = [
        panelBg.__merge(mkVerticalPannableArea(unitAttrPage))
        attrDetails
      ]
    }
  ]
}

function hasUnitWithUpgradedAttribute() {
  foreach(unit in servProfile.get().units)
    if(!serverConfigs.get()?.allUnits[unit.name].isPremium && !unit.isUpgraded)
      foreach(attributes in unit.attrLevels)
        foreach(attr in attributes)
          if(attr > 0)
            return true
  return false
}

let applyAction = function() {
  if(!hasUnitWithUpgradedAttribute()) {
    sendAppsFlyerEvent("add_unit_attributes")
  }
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
  behavior = HangarCameraControl
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
