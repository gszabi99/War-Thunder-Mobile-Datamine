from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%darg/helpers/bitmap.nut" import mkBitmapPictureLazy
from "%appGlobals/pServer/bqClient.nut" import sendUiBqEvent
from "%appGlobals/pServer/campaign.nut" import curCampaign, isAnyCampaignSelected
from "%appGlobals/pServer/pServerApi.nut" import set_research_unit, unitInProgress, registerHandler
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/squadState.nut" import isInSquad
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeader
from "%rGui/components/selectedLine.nut" import selectedLineHorSolid
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import buttonsHGap, textButtonBattle
from "%rGui/controlsMenu/gpActBtn.nut" import EMPTY_ACTION
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/gradients.nut" import gradTexSize, mkGradientCtorRadial
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import selectColor
from "%rGui/tooltip.nut" import withTooltip, tooltipDetach
from "%rGui/tutorial/tutorialMissions.nut" import rewardTutorialMission
from "%rGui/unit/components/unitInfoPanel.nut" import unitInfoPanel, mkUnitTitle
from "%rGui/unit/components/unitPlateComp.nut" import mkUnitBg, mkUnitImage, mkUnitTexts, unitPlateTiny, mkUnitInfo,
  mkFlagImage, mkFlagImageWithoutGrad
from "%rGui/unitsTree/unitsTreeNodesState.nut" import unitsResearchStatus, currentResearch, selectedCountry,
  visibleNodes, mkResearchableCountries


const WND_UID = "chooseResearch"
const minWidthWnd = hdpx(1400)
const defaultLineWidth = hdpxi(2)
const defaultMargin = hdpx(10)
const smallVertLineHeight = hdpx(20)
const bigVertLineHeight = hdpx(50)
let maxAmountOfUnitsOnScreen = (saSize[0] / (unitPlateTiny[0] + buttonsHGap)).tointeger()
let flagSize = evenPx(70)
let flagBtnWidth = evenPx(120)
const flagGap = hdpx(20)


const flagBgColor = 0xFF000000
const flagBgColorSelected = 0x99405780

let needSelectResearch = keepref(Computed(@() isAnyCampaignSelected.get()
  && currentResearch.get() == null
  && null != unitsResearchStatus.get().findvalue(@(r) r.canResearch || r.isResearched)
  && null == campMyUnits.get().findindex(@(u) u.name in (serverConfigs.get()?.unitResearchExp ?? {}))))

function closeSelectResearch() {
  sendUiBqEvent("first_country_choice", { id = "finish_select_research" })
  removeModalWindow(WND_UID)
}

let gradient = mkBitmapPictureLazy(gradTexSize / 4, gradTexSize,
  mkGradientCtorRadial(0xFFFFFFFF, 0, gradTexSize / 2, gradTexSize / 2, 0, 0))

let mkSmallText = @(text, ovr = {}) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontTiny).__update(ovr)

function mkUnitPlate(unit) {
  let stateFlags = Watched(0)
  let key = {}

  return @() {
    key
    watch = stateFlags
    size = unitPlateTiny
    behavior = Behaviors.Button
    onElemState = withTooltip(stateFlags, key, @() {
      content = unitInfoPanel({}, mkUnitTitle, Watched(unit)),
      flow = FLOW_HORIZONTAL
    })
    onDetach = tooltipDetach(stateFlags)
    children = [
      mkUnitBg(unit)
      mkUnitImage(unit)
      mkUnitTexts(unit, getUnitName(unit.name))
      mkUnitInfo(unit)
    ]
  }
}

let lineCtor = @(commands, ovr = {}) {
  size = FLEX
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = defaultLineWidth
  commands
}.__update(ovr)

let verticalLine = lineCtor([[VECTOR_LINE, 0, 100, 0, 0]])
let horizontalLine = lineCtor([[VECTOR_LINE, 0, 0, 100, 0]])
let dot = lineCtor([[VECTOR_LINE, 0, 0, 0, 0]], { lineWidth = hdpxi(10) })

let mkFlowLine = @(line, size = FLEX) {
  size
  children = line
}

function unitsBlock(startUnit) {
  let childUnits = Computed(function() {
    local childUnits = {}
    foreach(key, value in visibleNodes.get())
      foreach(unit in value.reqUnits) {
        if (unit not in childUnits)
          childUnits[unit] <- []
        childUnits[unit].append(key)
      }

    let startUnitName = startUnit.get()?.name
    if (startUnitName == null)
      return []
    let resTable = {}
    let added = { [startUnitName] = true }
    let list = [startUnitName]
    foreach(name in list) {
      let childs = childUnits?[name]
      if (!childs)
        resTable[name] <-true
      else
        foreach(c in childs)
          if (c not in added) {
            added[c] <- true
            list.append(c) 
          }
    }

    let resTableKeys = resTable.keys()
    let maxMRank = resTableKeys.reduce(@(prevMRank, curUnit) max(prevMRank, serverConfigs.get()?.allUnits[curUnit].mRank ?? 0), 0)

    return resTableKeys
      .filter(@(unit) (serverConfigs.get()?.allUnits[unit].mRank ?? 0) >= maxMRank - 1)
      .sort(@(a, b) serverConfigs.get()?.allUnits[b].mRank <=> serverConfigs.get()?.allUnits[a].mRank)
      .slice(0, maxAmountOfUnitsOnScreen)
      .sort(@(a, b) visibleNodes.get()[a].y <=> visibleNodes.get()[b].y)
  })
  return @() {
    watch = [serverConfigs, childUnits, startUnit]
    margin = defaultMargin
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      startUnit.get() ? mkUnitPlate(startUnit.get()) : null
      mkFlowLine(verticalLine, [SIZE_TO_CONTENT, smallVertLineHeight])
      {
        margin = defaultMargin
        halign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(15)
        children = childUnits.get().map(@(_) mkFlowLine(dot))
      }
      mkFlowLine(verticalLine, [SIZE_TO_CONTENT, smallVertLineHeight])
      {
        size = [(unitPlateTiny[0] + buttonsHGap) * childUnits.get().len() - 1, SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        children = childUnits.get()
          .slice(0, childUnits.get().len() - 1)
          .map(@(_) mkFlowLine(horizontalLine, [unitPlateTiny[0] + buttonsHGap, SIZE_TO_CONTENT]))
      }
      {
        flow = FLOW_HORIZONTAL
        gap = buttonsHGap
        children = childUnits.get()
          .filter(@(u) serverConfigs.get()?.allUnits?[u] != null)
          .map(@(u) {
            flow = FLOW_VERTICAL
            halign = ALIGN_CENTER
            children = [
              mkFlowLine(verticalLine, [SIZE_TO_CONTENT, bigVertLineHeight])
              mkUnitPlate(serverConfigs.get()?.allUnits[u])
            ]
          })
      }
    ]
  }
}

let flagBg = @(isSelected) @() {
  watch = isSelected
  key = {}
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = gradient()
  color = isSelected.get() ? flagBgColorSelected : flagBgColor
  transform = {}
  transitions = [{ prop = AnimProp.color, duration = 0.3, easing = InOutQuad }]
}

function mkFlag(country, curCountry) {
  let isSelected = Computed(@() curCountry.get() == country)
  return {
    size = [flagBtnWidth, flagBtnWidth]
    behavior = Behaviors.Button
    onClick = @() selectedCountry.set(country)
    sound = { click = "choose" }
    children = [
      flagBg(isSelected)
      selectedLineHorSolid(isSelected)
      mkFlagImage(country, flagSize, { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER })
    ]
  }
}

let mkResearchHint = @(laterCountries) @() {
  watch = laterCountries
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    {
      maxWidth = hdpx(laterCountries.get().len() == 0 ? 700 : 900)
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc(laterCountries.get().len() == 0 ? "unitsTree/changeResearchHint"
        : "unitsTree/changeResearchHint/laterCountries"),
      halign = ALIGN_CENTER
    }.__update(fontTiny)
    {
      flow = FLOW_HORIZONTAL
      gap = flagGap
      children = laterCountries.get().map(@(c) mkFlagImageWithoutGrad(c, flagSize))
    }
  ]
}


let wndContent = @(startUnit, allCountries, curCountry, laterCountries) {
  padding = [0, buttonsHGap]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    @() {
      watch = allCountries
      flow = FLOW_HORIZONTAL
      gap = flagGap
      children = allCountries.get()
        .map(@(country) mkFlag(country, curCountry))
    }
    mkSmallText(loc("unitsTree/startUnit"), { color = selectColor })
    unitsBlock(startUnit)
    { size = flagGap }
    mkResearchHint(laterCountries)
  ]
}

function acceptChooseResearch(unitId, country) {
  sendUiBqEvent("first_country_choice", { id = country })
  set_research_unit(curCampaign.get(), unitId, isInSquad.get() ? "onSetResearchUnitInSquad"  : null)
}

function openImpl() {
  let allCountriesRaw = mkResearchableCountries(visibleNodes)
  let countriesInfo = Computed(function() {
    let res = { allowedNow = [], allowedLater = [] }
    let first = serverConfigs.get()?.firstChoiceResearch[curCampaign.get()]
    if (first != null)
      foreach (c in allCountriesRaw.get())
        if (first.contains(c))
          res.allowedNow.append(c)
        else
          res.allowedLater.append(c)

    if (res.allowedNow.len() == 0) {
      res.allowedNow = allCountriesRaw.get()
      res.allowedLater.clear()
    }
    return res
  })
  let allCountries = Computed(@() countriesInfo.get().allowedNow)

  let curCountry = Computed(@() allCountries.get().contains(selectedCountry.get())
    ? selectedCountry.get()
    : allCountries.get()?[0])
  let startUnitName = Computed(@() unitsResearchStatus.get()
    .findindex(@(r) r.canResearch && visibleNodes.get()?[r.name].country == curCountry.get()))
  let startUnit = Computed(@() serverConfigs.get()?.allUnits[startUnitName.get()])

  if (allCountries.get().len() == 1) {
    acceptChooseResearch(startUnit.get()?.name, curCountry.get())
    return
  }

  sendUiBqEvent("first_country_choice", { id = "start_select_research" })
  return addModalWindow(bgShaded.__merge({
    key = WND_UID
    size = FLEX
    onClick = EMPTY_ACTION
    children = modalWndBg.__merge({
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = hdpx(40)
      padding = const [0,0,hdpx(20),0]
      minWidth = minWidthWnd
      children = [
        modalWndHeader(loc("unitsTree/chooseCountryResearch"), { padding = [0, buttonsHGap] })
        wndContent(startUnit, allCountries, curCountry, Computed(@() countriesInfo.get().allowedLater))
        mkSpinnerHideBlock(unitInProgress,
          textButtonBattle(utf8ToUpper(loc("unitsTree/chooseResearch/accept")),
            @() acceptChooseResearch(startUnit.get()?.name, curCountry.get()), { childOvr = fontBoldTinyAccentedShaded, hotkeys = ["^J:X"] }))
      ]
    })
    animations = wndSwitchAnim
  }))
}

function tryOpenWnd() {
  if (needSelectResearch.get())
    openImpl()
}

tryOpenWnd()
needSelectResearch.subscribe(@(v) v ? tryOpenWnd() : closeSelectResearch())

registerHandler("onSetResearchUnitInSquad", @(_) rewardTutorialMission(curCampaign.get()))

return {
  needSelectResearch
}
