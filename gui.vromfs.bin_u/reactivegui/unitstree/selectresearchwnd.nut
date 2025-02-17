from "%globalsDarg/darg_library.nut" import *
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { curCampaign, isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { buttonsHGap, textButtonBattle } = require("%rGui/components/textButton.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { unitsResearchStatus, currentResearch, selectedCountry, nodes, mkCountries
} = require("unitsTreeNodesState.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, unitPlateTiny, mkUnitInfo
} = require("%rGui/unit/components/unitPlateComp.nut")
let { mkTreeNodesFlag } = require("unitsTreeComps.nut")
let { EMPTY_ACTION } = require("%rGui/controlsMenu/gpActBtn.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { set_research_unit, unitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { unitInfoPanel, mkPlatoonOrUnitTitle } = require("%rGui/unit/components/unitInfoPanel.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")


let WND_UID = "chooseResearch"
let minWidthWnd = hdpx(1400)
let defaultLineWidth = hdpxi(2)
let defaultMargin = hdpx(10)
let smallVertLineHeight = hdpx(20)
let bigVertLineHeight = hdpx(50)
let maxAmountOfUnitsOnScreen = (saSize[0] / (unitPlateTiny[0] + buttonsHGap)).tointeger()

let needSelectResearch = keepref(Computed(@() isCampaignWithUnitsResearch.get()
  && currentResearch.get() == null
  && null != unitsResearchStatus.get().findvalue(@(r) r.canResearch || r.isResearched)
  && null == campMyUnits.get().findindex(@(u) u.name in (serverConfigs.get()?.unitResearchExp ?? {}))))

function closeSelectResearch() {
  sendUiBqEvent("first_country_choice", { id = "finish_select_research" })
  removeModalWindow(WND_UID)
}

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
      content = unitInfoPanel({}, mkPlatoonOrUnitTitle, Watched(unit)),
      flow = FLOW_HORIZONTAL
    })
    onDetach = tooltipDetach(stateFlags)
    children = [
      mkUnitBg(unit)
      mkUnitImage(unit)
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
      mkUnitInfo(unit)
    ]
  }
}

let lineCtor = @(commands, ovr = {}) {
  size = flex()
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = defaultLineWidth
  commands
}.__update(ovr)

let verticalLine = lineCtor([[VECTOR_LINE, 0, 100, 0, 0]])
let horizontalLine = lineCtor([[VECTOR_LINE, 0, 0, 100, 0]])
let dot = lineCtor([[VECTOR_LINE, 0, 0, 0, 0]], { lineWidth = hdpxi(10) })

let mkFlowLine = @(line, size = flex()) {
  size
  children = line
}

let function unitsBlock(startUnit) {
  let childUnits = Computed(function() {
    local childUnits = {}
    foreach(key, value in nodes.get())
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
            list.append(c) // warning disable: -modified-container
          }
    }

    let resTableKeys = resTable.keys()
    let maxMRank = resTableKeys.reduce(@(prevMRank, curUnit) max(prevMRank, serverConfigs.get()?.allUnits[curUnit].mRank ?? 0), 0)

    return resTableKeys
      .filter(@(unit) (serverConfigs.get()?.allUnits[unit].mRank ?? 0) >= maxMRank - 1)
      .sort(@(a, b) serverConfigs.get()?.allUnits[b].mRank <=> serverConfigs.get()?.allUnits[a].mRank)
      .slice(0, maxAmountOfUnitsOnScreen)
      .sort(@(a, b) nodes.get()[a].y <=> nodes.get()[b].y)
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

let wndContent = @(startUnit, allCountries, curCountry) {
  padding = [0, buttonsHGap]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    @() {
      watch = allCountries
      flow = FLOW_HORIZONTAL
      children = allCountries.get()
        .map(@(country) mkTreeNodesFlag(
          country,
          curCountry,
          @() selectedCountry.set(country),
          Watched(false),
          { transform = { rotate = 90 } }
        ))
    }
    mkSmallText(loc("unitsTree/startUnit"), { color = 0xFF5CBEF7 })
    unitsBlock(startUnit)
  ]
}

function acceptChooseResearch(unitId) {
  sendUiBqEvent("first_country_choice", { id = selectedCountry.get() })
  set_research_unit(curCampaign.get(), unitId)
}

function openImpl() {
  sendUiBqEvent("first_country_choice", { id = "start_select_research" })

  let allCountries = mkCountries(nodes)
  let curCountry = Computed(@() allCountries.get().contains(selectedCountry.get())
    ? selectedCountry.get()
    : allCountries.get()?[0])
  let startUnitName = Computed(@() unitsResearchStatus.get()
    .findindex(@(r) r.canResearch && nodes.get()?[r.name].country == curCountry.get()))
  let startUnit = Computed(@() serverConfigs.get()?.allUnits[startUnitName.get()])
  return addModalWindow(bgShaded.__merge({
    key = WND_UID
    size = flex()
    onClick = EMPTY_ACTION
    children = modalWndBg.__merge({
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = hdpx(40)
      padding = [0,0,hdpx(20),0]
      minWidth = minWidthWnd
      children = [
        modalWndHeader(loc("unitsTree/chooseCountryResearch"), { padding = [0, buttonsHGap] })
        wndContent(startUnit, allCountries, curCountry)
        mkSmallText(loc("unitsTree/changeResearchHint"), {
          maxWidth = hdpx(700)
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_CENTER
        })
        mkSpinnerHideBlock(unitInProgress,
          textButtonBattle(loc("unitsTree/chooseResearch/accept"),
            @() acceptChooseResearch(startUnit.get()?.name), { childOvr = fontTiny, hotkeys = ["^J:X"] }))
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

return {
  tryOpenWnd
  needSelectResearch
}
