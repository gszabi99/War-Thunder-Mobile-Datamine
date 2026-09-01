from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.workcycle" import deferOnce
from "wt.behaviors" import HangarCameraControl
from "%sqstd/underscore.nut" import arrayByRows
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/gameModes/gameModes.nut" import allGameModes
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/profile.nut" import campUnitsCfg, curUnit
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%appGlobals/unitTags.nut" import getUnitTagsCfg
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/buttonStyles.nut" import defButtonMinWidth
from "%rGui/components/closeWndBtn.nut" import closeWndBtn
from "%rGui/components/foldableSelector.nut" import mkFoldableSelector, mkListItem, headerBgColor, itemGap,
  contentPadding, contentBgColor, headerH, mkFoldableList
from "%rGui/components/gradTexts.nut" import mkGradRank, mkGradRankLarge
from "%rGui/components/gradientDefComps.nut" import headerGradientBg
from "%rGui/components/modalWindows.nut" import addModalWindowWithHeader, removeModalWindow
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/components/slider.nut" import sliderWithButtons
from "%rGui/components/textButton.nut" import buttonsVGap
from "%rGui/components/textInput.nut" import textInput
from "%rGui/components/toggle.nut" import horizontalToggleWithLabel
from "%rGui/gameModes/offlineBattlesState.nut" import offlineBattlesCfg, openOfflineBattleMenu,
  isOfflineBattlesActive, unitSearchName, unitSearchResults, isDebugListMapsActive, canAccessForDebug, runOfflineBattle,
  initOfflineBattlesData, selectedMission, skipMissionSettings, unitPresetsLevelList, getMissionName, missionsList,
  getOfflineBattleGameMode, savedBotsCount, savedBotsRank, defMaxBotsCount, defMaxBotsRank, NUMBER_OF_PLAYERS,
  savedUnitPresetLevel, countriesList, mRanksList, unitsList, selectedCountry, selectedMRank, selectedUnit,
  savedUnitForReturn
from "%rGui/mainMenu/toBattleButton.nut" import mkToBattleButtonWithSquadManagement
from "%rGui/navState.nut" import registerScene
import "%rGui/options/mkOption.nut" as mkOption
from "%rGui/options/optCtrlType.nut" import OCT_LIST
from "%rGui/style/gradients.nut" import gradTranspDoubleSideX, gradDoubleTexOffset
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/unit/components/unitPlateComp.nut" import mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitInfo
from "%rGui/unit/hangarUnit.nut" import setHangarUnitWithSkin
import "%rGui/unit/mkUnitPkgDownloadInfo.nut" as mkUnitPkgDownloadInfo
from "%rGui/unitDetails/unitDetailsState.nut" import openUnitDetailsWnd


const SET_MIS_BLK_PARAMS_WND = "setMisBlkParamsWnd"
let curOpenedSelector = Watched("")
let needShowBattleSettingsWnd = mkWatched(persist, "needShowBattleSettingsWnd", false)
const rightPanelWidth = hdpx(520)
const itemSize = hdpx(120)
const unitPlateW = hdpx(248)
const textItemH = hdpx(70)
const labelIconGap = hdpx(20)
const maxTextWidth = hdpx(400)
const flagSizeHeader = hdpx(54)
const searchIconSize = hdpxi(50)

function close() {
  isOfflineBattlesActive.set(false)
  savedUnitForReturn.set(null)
}

function setHangarUnit() {
  let curUnitName = curUnit.get()?.name
  let unit = offlineBattlesCfg.get()?[curUnitName]
    ?? campUnitsCfg.get()?[curUnitName]

  let { operatorCountry = null } = getUnitTagsCfg(curUnitName)
  let { country = "" } = unit

  if (unit != null)
    selectedUnit.set(unit.__merge({ country = operatorCountry ?? country }))
}

function mkSliderOpt(opt) {
  let { value = null, ctrlOverride = {}, locId = "" } = opt
  if (value == null) {
    logerr($"Options: Missing value for option {opt?.locId}")
    return null
  }
  return sliderWithButtons(value, loc(locId), ctrlOverride)
}

let mkBotOpt = @(value, locId, maxValue) {
  locId
  value
  ctrlOverride = {
    min = 1
    max = maxValue
    unit = 1
  }
}

let mkText = @(text, ovr = {}) {
  padding = const [0, hdpx(10)]
  rendObj = ROBJ_TEXT
  behavior = Behaviors.Marquee
  halign = ALIGN_LEFT
  valign = ALIGN_CENTER
  text
}.__update(fontSmall, ovr)

let mkIconWithLabel = @(iconComp, text) {
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = labelIconGap
  children = [
    iconComp
    mkText(text, { size = const [maxTextWidth - (flagSizeHeader + labelIconGap), SIZE_TO_CONTENT] })
  ]
}

let mkImage = @(w, h, imgPath, ovr = {}) {
  size = [w, h]
  rendObj = ROBJ_IMAGE
  image = Picture(imgPath)
  keepAspect = true
}.__update(ovr)

let mkUnitPlate = @(unit, isSelected = Watched(false)) {
  size = const [unitPlateW, itemSize]
  children = [
    mkUnitBg(unit)
    mkUnitSelectedGlow(unit, isSelected)
    mkUnitImage(unit)
    mkUnitTexts(unit, getUnitName(unit))
    mkUnitInfo(unit)
  ]
}

let searchIcon = {
  size = searchIconSize
  pos = const [hdpx(30), 0]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#btn_search.svg:{searchIconSize}:{searchIconSize}:P")
}

let resetBtn = {
  size = headerH
  rendObj = ROBJ_SOLID
  color = headerBgColor
  children = closeWndBtn(@() unitSearchName.get() == "" ? setHangarUnit() : unitSearchName.set(""),
    { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER })
}

let unitSearchTextInput = {
  size = FLEX_H
  valign = ALIGN_CENTER
  children = [
    textInput(unitSearchName, {
      ovr = {
        size = [FLEX, headerH]
        padding = const [hdpx(50), hdpx(85)]
        fillColor = headerBgColor
      }
      placeholder = loc("unit_search")
      onEscape = @() unitSearchName.get() != "" ? unitSearchName.set("") : close()
      maxChars = 40
    })
    searchIcon
  ]
}

function selectSearchResultUnit(unit) {
  selectedUnit.set(unit)
  curOpenedSelector.set("")
  unitSearchName.set("")
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
    children = mkUnitPlate(unit)
  }
}

let searchUnitResults = @() {
  watch = unitSearchResults
  rendObj = ROBJ_SOLID
  color = contentBgColor
  padding = contentPadding
  gap = itemGap
  flow = FLOW_VERTICAL
  children = arrayByRows(unitSearchResults.get()
    .map(@(v) mkSearchResultUnit(v)), 2)
      .map(@(children) {
        flow = FLOW_HORIZONTAL
        gap = itemGap
        children
      })
}

let mkUnitHeadItem = @(v) {
  size = const [FLEX, SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  padding = [0, itemGap, 0, 0]
  gap = itemGap
  children = [
    {
      size = textItemH
      behavior = Behaviors.Button
      function onClick() {
        savedUnitForReturn.set(selectedUnit.get()?.name ?? "")
        openUnitDetailsWnd({ name = selectedUnit.get().name })
      }
      rendObj = ROBJ_BOX
      borderWidth = hdpx(2)
      borderColor = 0xFFA0A0A0
      children = {
        rendObj = ROBJ_TEXT
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
        text = "i"
      }.__update(fontSmallShaded)
    }
    mkText(getUnitName(v ?? ""), { size = [maxTextWidth - (textItemH + itemGap), SIZE_TO_CONTENT] })
  ]
}

let mkUnitFoldableContent = @(listValues, columns, curValue, curOpenedSel) @() {
  watch = listValues
  flow = FLOW_VERTICAL
  gap = itemGap
  children = arrayByRows(listValues.get().map(function(value) {
    let isSelected = Computed(@() curValue.get()?.name == value?.name)

    function onSelect() {
      curValue.set(value)
      curOpenedSel?.set("")
    }

    return mkListItem(value, isSelected, onSelect, unitPlateW, itemSize, mkUnitPlate(value, isSelected))
  }), columns)
    .map(@(children) {
      flow = FLOW_HORIZONTAL
      gap = itemGap
      children
    })
}

let mkUnitFoldableHeader = @(curValue) @() {
  watch = curValue
  size = FLEX_H
  children = mkUnitHeadItem(curValue.get())
}

let mkFlagImage = @(countryId, sz) mkImage(sz, sz, $"ui/gameuiskin#{countryId}.svg:{sz}:{sz}:P")

let mkCountryHeadItem = @(v) v == "" ? null
  : mkIconWithLabel(mkFlagImage(v, flagSizeHeader), loc(v))
let mkCountryListItem = @(v, isSelected, onClick) v == "" ? null
  : mkListItem(v, isSelected, onClick, itemSize, itemSize, mkFlagImage(v, textItemH))
let mkSelectorCountry = @(list, country) mkFoldableSelector(list, country, 4,
  mkCountryListItem, mkCountryHeadItem, curOpenedSelector, "country")

let mkMRankHeadItem = mkGradRank
let mkMRankListItem = @(v, isSelected, onClick)
  mkListItem(v, isSelected, onClick, itemSize, itemSize, mkGradRankLarge(v))
let mkSelectorMRank = @(list, mRank) mkFoldableSelector(list, mRank, 4,
  mkMRankListItem, mkMRankHeadItem, curOpenedSelector, "mRank")

let mkUnitFoldableSelector = @(listValues, curValue, columns, curOpenedSel, selectorId) mkFoldableList(
  mkUnitFoldableContent(listValues, columns, curValue, curOpenedSel),
  mkUnitFoldableHeader(curValue),
  curOpenedSel,
  selectorId
)
let mkSelectorUnit = @(list, unit) mkUnitFoldableSelector(list, unit, 2, curOpenedSelector, "unit")

let mkMissionHeadItem = @(v) mkText(loc(getMissionName(v)), { size = const [maxTextWidth, SIZE_TO_CONTENT] })
let mkMissionListItem = @(v, isSelected, onClick)
  mkListItem(v, isSelected, onClick, rightPanelWidth, textItemH, mkText(loc(getMissionName(v)), { size = FLEX_H }))
let mkSelectorMission = @(list, mission) mkFoldableSelector(list, mission, 1,
  mkMissionListItem, mkMissionHeadItem, curOpenedSelector, "mission")

function misParamsContent() {
  let gmCfg = Computed(@() getOfflineBattleGameMode(curCampaign.get(), allGameModes.get()))
  let isCommonUnit = Computed(function() {
    let { isPremium = false, isHidden = false } = selectedUnit.get()
    return !isPremium && !isHidden
  })

  let maxBotsCount = Computed(function() {
    let maxBotsByCfg = gmCfg.get()?.mission_decl.maxBots
    let maxBotSlots = maxBotsByCfg != null ? maxBotsByCfg : defMaxBotsCount
    return maxBotSlots - NUMBER_OF_PLAYERS
  })

  let maxBotsRank = Computed(function() {
    let globalCampaign = getCampaignPresentation(curCampaign.get()).campaign
    local res = 1
    foreach (unit in campUnitsCfg.get())
      if (getCampaignPresentation(unit.campaign).campaign == globalCampaign)
        res = max(unit.mRank, res)
    return res
  })

  let optMaxBotsCount = mkBotOpt(savedBotsCount, "mainmenu/offlineBattles/settings/botsCount", maxBotsCount.get())
  let optMaxBotsRank = mkBotOpt(savedBotsRank, "mainmenu/offlineBattles/settings/botsRank", maxBotsRank.get())
  let optUnitPresetLevel = {
    locId = "mainmenu/offlineBattles/settings/unitLevel"
    ctrlType = OCT_LIST
    value = savedUnitPresetLevel
    list = unitPresetsLevelList
    visible = isCommonUnit
    valToString = @(v) loc($"mainmenu/offlineBattles/unitPreset/{v}")
  }

  return {
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    padding = hdpx(40)
    gap = hdpx(40)
    function onAttach() {
      savedBotsCount.set(maxBotsCount.get())
      savedBotsRank.set(selectedUnit.get()?.mRank ?? defMaxBotsRank)
    }
    onDetach = @() needShowBattleSettingsWnd.set(false)
    children = [
      mkSliderOpt(optMaxBotsCount)
      mkSliderOpt(optMaxBotsRank)
      mkOption(optUnitPresetLevel)
      mkToBattleButtonWithSquadManagement(function() {
        needShowBattleSettingsWnd.set(false)
        runOfflineBattle()
      })
    ]
  }
}

let openBattleSettingsModal = @() addModalWindowWithHeader(SET_MIS_BLK_PARAMS_WND,
  loc("mainmenu/offlineBattles/settings/modalTitle"),
  misParamsContent)

needShowBattleSettingsWnd.subscribe(@(v) v
  ? openBattleSettingsModal()
  : removeModalWindow(SET_MIS_BLK_PARAMS_WND))
if (needShowBattleSettingsWnd.get())
  openBattleSettingsModal()

let setParamsAndRunBattle = @() skipMissionSettings.get()
  ? runOfflineBattle()
  : needShowBattleSettingsWnd.set(true)

let toBattleHint = @(text) {
  hplace = ALIGN_RIGHT
  pos = [saBorders[0] * 0.5, 0]
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  padding = [saBorders[0] * 0.2, saBorders[0] * 0.5]
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, saBorders[0]]
  color = 0x70000000
  children = {
    size = [defButtonMinWidth, SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text
  }.__update(fontTinyAccented)
}

let searchBlock = {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  children = [
    unitSearchTextInput
    resetBtn
  ]
}

let wndHeader = headerGradientBg(
  [
    backButton(close)
     {
       rendObj = ROBJ_TEXT
       text = loc("mainmenu/offlineBattles")
     }.__update(fontBig)
  ], { vplace = ALIGN_TOP })

let rightContent = {
  size = [rightPanelWidth, FLEX]
  minHeight = hdpx(700)
  halign = ALIGN_RIGHT
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  flow = FLOW_VERTICAL
  gap = buttonsVGap
  children = [
    makeVertScroll({
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = buttonsVGap
      children = [
        searchBlock
        @() {
          watch = [unitSearchName, missionsList]
          size = FLEX_H
          gap = buttonsVGap
          flow = FLOW_VERTICAL
          children = unitSearchName.get() == ""
            ? [
                mkSelectorCountry(countriesList, selectedCountry)
                mkSelectorMRank(mRanksList, selectedMRank)
                mkSelectorUnit(unitsList, selectedUnit)
                missionsList.get().len() > 0 ? mkSelectorMission(missionsList, selectedMission) : null
              ]
            : searchUnitResults
        }
      ]
    }, { isBarOutside = true })
    toBattleHint(loc("mainmenu/btnSingleLocalMission"))
    mkToBattleButtonWithSquadManagement(setParamsAndRunBattle)
  ]
}

let bottomLeftContent = @() {
  watch = canAccessForDebug
  size = FLEX
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  gap = buttonsVGap
  children = [
    mkUnitPkgDownloadInfo(selectedUnit, true, { halign = ALIGN_LEFT, hplace = ALIGN_LEFT })
    !canAccessForDebug.get() ? null
      : {
          flow = FLOW_VERTICAL
          gap = buttonsVGap
          children = [
            horizontalToggleWithLabel(skipMissionSettings, loc("mainmenu/offlineBattles/settings/skipMissionSettings"),
              { behavior = Behaviors.Marquee })
            horizontalToggleWithLabel(isDebugListMapsActive, loc("mainmenu/offlineBattles/debug/maps"),
              { behavior = Behaviors.Marquee })
          ]
        }
  ]
}

function onUnitChange(unit) {
  if (unit == null)
    return
  let { name = "", country = "", mRank = 0 } = unit
  setHangarUnitWithSkin(name, "")
  selectedCountry.set(country)
  selectedMRank.set(mRank)
}

let content = {
  key = {}
  size = FLEX
  function onAttach() {
    if (initOfflineBattlesData.get() != null) {
      let { unitName, missionName } = initOfflineBattlesData.get()
      if (unitName in offlineBattlesCfg.get())
        selectedUnit.set(offlineBattlesCfg.get()[unitName])
      else
        setHangarUnit()
      selectedMission.set(missionName)
    } else {
      if (savedUnitForReturn.get() != null && savedUnitForReturn.get() in offlineBattlesCfg.get())
        selectedUnit.set(offlineBattlesCfg.get()[savedUnitForReturn.get()])
      else
        setHangarUnit()
      selectedMission.set(missionsList.get()?.findvalue(@(_) true) ?? "")
    }

    selectedUnit.subscribe(onUnitChange)
    deferOnce(@() onUnitChange(selectedUnit.get()))
  }
  onDetach = @() selectedUnit.unsubscribe(onUnitChange)
  children = [
    wndHeader
    rightContent
    bottomLeftContent
  ]
}

let offlineBattlesWnd = {
  key = {}
  size = FLEX
  padding = saBordersRv
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
  animations = wndSwitchAnim
  children = content
}

registerScene("offlineBattlesWnd", offlineBattlesWnd, close, isOfflineBattlesActive)

register_command(openOfflineBattleMenu, "ui.debug.offlineBattlesWnd")
