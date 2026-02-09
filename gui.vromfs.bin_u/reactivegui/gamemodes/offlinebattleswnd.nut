from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { deferOnce } = require("dagor.workcycle")
let { register_command } = require("console")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { mkGameModeByCampaign } = require("%appGlobals/gameModes/gameModes.nut")
let { getUnitLocId, getUnitName } = require("%appGlobals/unitPresentation.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { campUnitsCfg, curUnit } = require("%appGlobals/pServer/profile.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { mkToBattleButtonWithSquadManagement } = require("%rGui/mainMenu/toBattleButton.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { setHangarUnitWithSkin } = require("%rGui/unit/hangarUnit.nut")
let { defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { buttonsHGap, buttonsVGap } = require("%rGui/components/textButton.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { offlineBattlesCfg, openOfflineBattleMenu, isOfflineBattlesActive, unitSearchName, unitSearchResults,
  isDebugListMapsActive, canAccessForDebug, runOfflineBattle, initOfflineBattlesData, selectedMission,
  refreshOfflineMissionsList, skipMissionSettings, unitPresetsLevelList, getMissionName, missionsList,
  savedBotsCount, savedBotsRank, defMaxBotsCount, defMaxBotsRank, NUMBER_OF_PLAYERS, savedUnitPresetLevel,
  countriesList, mRanksList, unitsList, selectedCountry, selectedMRank, selectedUnit
} = require("%rGui/gameModes/offlineBattlesState.nut")
let { registerScene } = require("%rGui/navState.nut")
let { horizontalToggleWithLabel } = require("%rGui/components/toggle.nut")
let { addModalWindowWithHeader, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { sliderWithButtons } = require("%rGui/components/slider.nut")
let { OCT_LIST } = require("%rGui/options/optCtrlType.nut")
let mkOption = require("%rGui/options/mkOption.nut")
let mkUnitPkgDownloadInfo = require("%rGui/unit/mkUnitPkgDownloadInfo.nut")
let { mkFoldableSelector, mkListItem, headerBgColor, itemGap, contentPadding, contentBgColor,
  headerH } = require("%rGui/components/foldableSelector.nut")
let { mkGradRank, mkGradRankLarge } = require("%rGui/components/gradTexts.nut")
let { mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitInfo
} = require("%rGui/unit/components/unitPlateComp.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { closeWndBtn } = require("%rGui/components/closeWndBtn.nut")
let { textInput } = require("%rGui/components/textInput.nut")


let SET_MIS_BLK_PARAMS_WND = "setMisBlkParamsWnd"
let curOpenedSelector = Watched("")
let needShowBattleSettingsWnd = mkWatched(persist, "needShowBattleSettingsWnd", false)
let rightPanelWidth = hdpx(520)
let itemSize = hdpx(120)
let unitPlateW = hdpx(248)
let textItemH = hdpx(70)
let labelIconGap = hdpx(20)
let maxTextWidth = hdpx(400)
let flagSizeHeader = hdpx(54)
let searchIconSize = hdpxi(50)

let close = @() isOfflineBattlesActive.set(false)
function setHangarUnit() {
  let curUnitName = curUnit.get()?.name
  let realUnitName = $"{getTagsUnitName(curUnitName)}_nc"

  let unit = offlineBattlesCfg.get()?[getTagsUnitName(curUnitName)]
    ?? campUnitsCfg.get()?[curUnitName]
    ?? campUnitsCfg.get()?[realUnitName]

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
  padding = [0, hdpx(10)]
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
    mkText(text, { size = [maxTextWidth - (flagSizeHeader + labelIconGap), SIZE_TO_CONTENT] })
  ]
}

let mkImage = @(w, h, imgPath, ovr = {}) {
  size = [w, h]
  rendObj = ROBJ_IMAGE
  image = Picture(imgPath)
  keepAspect = true
}.__update(ovr)

let mkUnitPlate = @(unit, isSelected = Watched(false)) {
  size = [unitPlateW, itemSize]
  children = [
    mkUnitBg(unit)
    mkUnitSelectedGlow(unit, isSelected)
    mkUnitImage(unit)
    mkUnitTexts(unit, getUnitName(unit, loc))
    mkUnitInfo(unit)
  ]
}

let searchIcon = {
  size = searchIconSize
  pos = [hdpx(30), 0]
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
        size = [flex(), headerH]
        padding = [hdpx(50), hdpx(85)]
        fillColor = headerBgColor
      }
      placeholder = loc("unit_search")
      onChange = @(v) unitSearchName.set(v)
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

let mkUnitHeadItem = @(v) mkText(loc(getUnitLocId(v ?? "")))
let mkUnitListItem = @(v, isSelected, onClick)
  mkListItem(v, isSelected, onClick, unitPlateW, itemSize, mkUnitPlate(v, isSelected))
let mkSelectorUnit = @(list, unit) mkFoldableSelector(list, unit, 2,
  mkUnitListItem, mkUnitHeadItem, curOpenedSelector, "unit")

let mkMissionHeadItem = @(v) mkText(loc(getMissionName(v)), { size = [maxTextWidth, SIZE_TO_CONTENT] })
let mkMissionListItem = @(v, isSelected, onClick)
  mkListItem(v, isSelected, onClick, rightPanelWidth, textItemH, mkText(loc(getMissionName(v)), { size = FLEX_H }))
let mkSelectorMission = @(list, mission) mkFoldableSelector(list, mission, 1,
  mkMissionListItem, mkMissionHeadItem, curOpenedSelector, "mission")

function misParamsContent() {
  let gmCfg = mkGameModeByCampaign(getCampaignPresentation(curCampaign.get()).campaign)
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

let wndHeader = {
  size = flex()
  valign = ALIGN_TOP
  flow = FLOW_HORIZONTAL
  gap = buttonsVGap
  minHeight = hdpx(700)
  children = [
    backButton(close)
    {
      rendObj = ROBJ_TEXT
      size = FLEX_H
      text = loc("mainmenu/offlineBattles")
    }.__update(fontBig)
    {
      size = [rightPanelWidth, flex()]
      hplace = ALIGN_RIGHT
      vplace = ALIGN_TOP
      children = makeVertScroll({
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
    }
  ]
}

let wndFooter = @() {
  watch = canAccessForDebug
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  valign = ALIGN_BOTTOM
  gap = buttonsHGap
  children = [
    !canAccessForDebug.get() ? null
      : {
          valign = ALIGN_BOTTOM
          flow = FLOW_VERTICAL
          gap = buttonsVGap
          children = [
            horizontalToggleWithLabel(skipMissionSettings, loc("mainmenu/offlineBattles/settings/skipMissionSettings"),
              { behavior = Behaviors.Marquee })
            horizontalToggleWithLabel(isDebugListMapsActive, loc("mainmenu/offlineBattles/debug/maps"),
              { behavior = Behaviors.Marquee })
          ]
        }
    {
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = buttonsVGap
      halign = ALIGN_RIGHT
      children = [
        toBattleHint(loc("mainmenu/btnSingleLocalMission"))
        mkToBattleButtonWithSquadManagement(setParamsAndRunBattle)
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
  size = flex()
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  function onAttach() {
    refreshOfflineMissionsList()

    if (initOfflineBattlesData.get() != null) {
      let { unitName, missionName } = initOfflineBattlesData.get()
      if (unitName in offlineBattlesCfg.get())
        selectedUnit.set(offlineBattlesCfg.get()?[unitName])
      else
        setHangarUnit()
      selectedMission.set(missionName)
    } else {
      setHangarUnit()
      selectedMission.set(missionsList.get()?.findvalue(@(_) true) ?? "")
    }

    selectedUnit.subscribe(onUnitChange)
    deferOnce(@() onUnitChange(selectedUnit.get()))
  }
  onDetach = @() selectedUnit.unsubscribe(onUnitChange)
  children = [
    wndHeader
    { size = flex() }
    mkUnitPkgDownloadInfo(selectedUnit, true, { halign = ALIGN_LEFT, hplace = ALIGN_LEFT })
    wndFooter
  ]
}

let offlineBattlesWnd = {
  key = {}
  size = flex()
  padding = saBordersRv
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
  animations = wndSwitchAnim
  children = content
}

registerScene("offlineBattlesWnd", offlineBattlesWnd, close, isOfflineBattlesActive)

register_command(openOfflineBattleMenu, "ui.debug.offlineBattlesWnd")
