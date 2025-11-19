from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "wt.behaviors" import HangarCameraControl
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/underscore.nut" import arrayByRows
import "%appGlobals/getTagsUnitName.nut" as getTagsUnitName
from "%appGlobals/unitPresentation.nut" import getUnitLocId
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/updater/addonsState.nut" import unitSizes
from "%appGlobals/openForeignMsgBox.nut" import subscribeFMsgBtns, openFMsgBox
from "%rGui/navState.nut" import registerScene
from "%rGui/updater/updaterState.nut" import openDownloadAddonsWnd
from "%rGui/mainMenu/gamercard.nut" import mkLeftBlockUnitCampaign
from "%rGui/style/gamercardStyle.nut" import gamercardHeight
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
import "%rGui/components/panelBg.nut" as panelBg
from "%rGui/components/textInput.nut" import textInput
from "%rGui/components/textButton.nut" import textButtonCommon, textButtonPrimary
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/closeWndBtn.nut" import closeWndBtn
from "%rGui/components/spinner.nut" import mkSpinner
from "%rGui/components/slider.nut" import sliderWithButtons, sliderH
from "%rGui/components/foldableSelector.nut" import itemGap, contentPadding, contentBgColor, headerBgColor
from "%rGui/dmViewer/protectionAnalysisState.nut" import isProtectionAnalysisActive, inspectedUnit, inspectedBaseUnit,
  isSimulationMode, protectionMapUpdate, threatUnitSearchString, threatCountry, threatMRank, threatUnit,
  threatBulletData, fireDistance, armorPiercingMm, threatCountriesList, threatMRanksList,
  threatUnitsList, threatBulletDataList, threatUnitSearchResults, selectThreatUnit,
  isProtectionMapUpdating, protectionMapUpdProgress, FIRE_DISTANCE_MAX
from "%rGui/dmViewer/protAnalysisOptionsComps.nut" import curOpenedSelector, mkSelectorCountry,
  mkSelectorMRank, mkSelectorUnit, mkSelectorBullet, mkUnitPlate

const leftPanelW = hdpx(580)
const rightPanelW = hdpx(520)

let close = @() inspectedUnit.set(null)

let sceneHeader = @() {
  watch = inspectedBaseUnit
  children = mkLeftBlockUnitCampaign(
    close,
    getCampaignPresentation(inspectedBaseUnit.get()?.campaign).levelUnitDetailsLocId,
    inspectedBaseUnit)
}

let gamercardGap = hdpx(24)
let contentHeight = saSize[1] - gamercardHeight - gamercardGap

let threatBlockTitle = {
  size = FLEX_H
  vplace = ALIGN_BOTTOM
  pos = [0, -contentHeight - hdpx(18)]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = loc("protection_analysis/attacker")
}.__update(fontSmallShaded)

let mkValText = @(text) {
  vplace = ALIGN_BOTTOM
  halign = ALIGN_RIGHT
  rendObj = ROBJ_TEXT
  text
}.__update(fontSmall)

function mkParamLine(label, val, maxLenVal, valToString) {
  let valW = calc_comp_size(mkValText(valToString(maxLenVal)))[0]
  return {
    size = FLEX_H
    valing = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    children = [
      {
        size = FLEX_H
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = label
      }.__update(fontSmall)
      @() mkValText(valToString(val.get())).__update({
        watch = val
        size = [valW, SIZE_TO_CONTENT]
      })
    ]
  }
}

let armorPiercingLine = mkParamLine(loc("bullet_properties/armorPiercing"),
  armorPiercingMm, "000", @(v) " ".concat(v, loc("measureUnits/mm")))
let fireDistanceLine = mkParamLine(loc("distance"),
  fireDistance, "0000", @(v) " ".concat(v, loc("measureUnits/meters_alt")))

let searchIconSize = hdpxi(60)
let searchIcon = {
  size = [searchIconSize, searchIconSize]
  pos = [hdpx(12), 0]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#btn_search.svg:{searchIconSize}:{searchIconSize}:P")
}

let clearSearchBtn = @() threatUnitSearchString.get() == "" ? { watch = threatUnitSearchString } : {
  watch = threatUnitSearchString
  hplace = ALIGN_RIGHT
  pos = [-hdpx(10), 0]
  children = closeWndBtn(@() threatUnitSearchString.set(""), {
  })
}

let textInputPadV = (0.3 * defButtonHeight).tointeger()
let threatUnitSearchTextInput = {
  size = FLEX_H
  valign = ALIGN_CENTER
  children = [
    textInput(threatUnitSearchString, {
      ovr = {
        size = [flex(), defButtonHeight]
        padding = [textInputPadV, hdpx(95), textInputPadV, hdpx(85)]
        fillColor = headerBgColor
      }
      placeholder = loc("unit_search")
      onChange = @(v) threatUnitSearchString.set(v)
      onEscape = @() threatUnitSearchString.get() != "" ? threatUnitSearchString.set("") : close()
      maxChars = 40
    })
    searchIcon
    clearSearchBtn
  ]
}

function selectSearchResultUnit(unit) {
  selectThreatUnit(unit)
  curOpenedSelector.set("")
  threatUnitSearchString.set("")
}

function mkSearchResultUnit(unit) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    behavior = Behaviors.Button
    onClick = @() selectSearchResultUnit(unit)
    onElemState = @(v) stateFlags.set(v)
    sound = { click  = "click" }
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
    children = mkUnitPlate(unit, Watched(false))
  }
}

let threatSearchResultsContent = @() {
  watch = threatUnitSearchResults
  rendObj = ROBJ_SOLID
  color = contentBgColor
  padding = contentPadding
  gap = itemGap
  flow = FLOW_VERTICAL
  children = arrayByRows(threatUnitSearchResults.get()
    .map(@(unit) { unit, mRank = unit.mRank, locName = loc(getUnitLocId(unit)) })
    .sort(@(a, b) a.mRank <=> b.mRank || a.locName <=> b.locName)
    .map(@(v) mkSearchResultUnit(v.unit)), 2)
      .map(@(children) {
        flow = FLOW_HORIZONTAL
        gap = itemGap
        children
      })
}

let threatOprtionsContent = [
  mkSelectorCountry(threatCountriesList, threatCountry)
  mkSelectorMRank(threatMRanksList, threatMRank)
  mkSelectorUnit(threatUnitsList, threatUnit)
  mkSelectorBullet(threatBulletDataList, threatBulletData)
]

let fireDistanceSlider = sliderWithButtons(
  fireDistance,
  null,
  {
    size = [leftPanelW - hdpx(360), sliderH]
    min = 0
    max = FIRE_DISTANCE_MAX
    unit = 100
  }
)

let protMapBtn = textButtonCommon(utf8ToUpper(loc("mainmenu/protectionMap")), @() protectionMapUpdate())
let protMapWaiting = {
  size = calc_comp_size(protMapBtn)
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    mkSpinner(hdpx(80), { margin = [0, hdpx(15), 0, 0] })
    @() {
      watch = protectionMapUpdProgress
      rendObj = ROBJ_TEXT
      text = protectionMapUpdProgress.get()
    }.__update(fontMonoSmall)
    {
      rendObj = ROBJ_TEXT
      text = "%"
    }.__update(fontSmall)
  ]
}

let protectionMapBtnPlace = @() {
  watch = isProtectionMapUpdating
  children = isProtectionMapUpdating.get()
    ? protMapWaiting
    : protMapBtn
}

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

let paramsLeft = panelBg.__merge({
  size = const [leftPanelW, SIZE_TO_CONTENT]
  gap = hdpx(24)
  children = [
    fireDistanceLine
    fireDistanceSlider
    armorPiercingLine
    protectionMapBtnPlace
  ]
})

let paramsRight = {
  hplace = ALIGN_RIGHT
  size = const [rightPanelW, flex()]
  flow = null
  children = [
    threatBlockTitle
    mkVerticalPannableArea({
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = hdpx(24)
      children = [
        threatUnitSearchTextInput
        @() {
          watch = threatUnitSearchString
          gap = hdpx(12)
          flow = FLOW_VERTICAL
          children = threatUnitSearchString.get() == ""
            ? threatOprtionsContent
            : threatSearchResultsContent
        }
      ]
    })
  ]
}

function openSimulation() {
  let tagsUnitName = getTagsUnitName(threatUnit.get().name)
  if ((unitSizes.get()?[tagsUnitName] ?? 0) == 0) {
    isSimulationMode.set(true)
    return
  }

  let addonsToDownload = []
  let unitsToDownload = [ tagsUnitName ]
  openFMsgBox({
    viewType = "downloadMsg"
    addons = addonsToDownload
    units = unitsToDownload
    bqAction = "msg_download_addons_for_protection_analysis"
    bqData = { source = "protection_analysis", unit = ";".join(unitsToDownload) }

    text = loc("msg/needAddonToProceed",
      { count = unitsToDownload.len(),
        addon = comma.join(unitsToDownload.map(@(unitName) colorize("@mark", loc(getUnitLocId(unitName)))))
      })
    buttons = [
      { id = "cancel", isCancel = true }
      { text = loc("msgbox/btn_download")
        eventId = "downloadThreatUnitForSimulation"
        context = { addons = addonsToDownload, units = unitsToDownload }
        styleId = "PRIMARY"
        isDefault = true
      }
    ]
  })
}

subscribeFMsgBtns({
  downloadThreatUnitForSimulation = @(evt) openDownloadAddonsWnd(evt.addons, evt.units, "protectionAnalysis", {},
    "onThreatUnitDownloaded", { unitName = evt.units[0] })
})
eventbus_subscribe("onThreatUnitDownloaded", function(p) {
  if (isProtectionAnalysisActive.get() && p.unitName == getTagsUnitName(threatUnit.get()?.name ?? ""))
    openSimulation()
})

let similationBtn = {
  vplace = ALIGN_BOTTOM
  children = textButtonPrimary(utf8ToUpper(loc("mainmenu/btnSimulation")),
    openSimulation, { hotkeys = ["^J:X | Enter"] })
}

let mkScene = @() {
  key = {}
  size = flex()
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
  animations = wndSwitchAnim
  children = [
    {
      size = flex()
      margin = saBordersRv
      flow = FLOW_VERTICAL
      gap = gamercardGap
      children = [
        sceneHeader
        {
          size = flex()
          children = [
            paramsLeft
            paramsRight
            similationBtn
          ]
        }
      ]
    }
  ]
}

registerScene("protAnalysisOptionsWnd", mkScene, close, isProtectionAnalysisActive)
