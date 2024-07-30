from "%globalsDarg/darg_library.nut" import *
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { msgBoxBg, msgBoxHeader } = require("%rGui/components/msgBox.nut")
let { curCampaign, isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { buttonsHGap, textButtonBattle } = require("%rGui/components/textButton.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { unitsResearchStatus, currentResearch, selectedCountry, nodes, mkCountries
} = require("unitsTreeNodesState.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, unitPlateTiny, mkUnitRank
} = require("%rGui/unit/components/unitPlateComp.nut")
let { mkTreeNodesFlag } = require("unitsTreeComps.nut")
let { EMPTY_ACTION } = require("%rGui/controlsMenu/gpActBtn.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { set_research_unit, unitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")


let WND_UID = "chooseResearch"
let minWidthWnd = hdpx(1400)
let defaultLineWidth = hdpxi(2)
let defaultMargin = hdpx(10)
let smallVertLineHeight = hdpx(20)
let bigVertLineHeight = hdpx(50)

let needSelectResearch = keepref(Computed(@() myUnits.get().len() == 0
  && isCampaignWithUnitsResearch.get()
  && currentResearch.get() == null
  && null != unitsResearchStatus.get().findvalue(@(r) r.canResearch)))

let closeSelectResearch = @() removeModalWindow(WND_UID)

let mkSmallText = @(text, ovr = {}) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontTiny).__update(ovr)

let mkUnitPlate = @(unit) {
  size = unitPlateTiny
  behavior = Behaviors.Button
  children = [
    mkUnitBg(unit)
    mkUnitImage(unit)
    mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
    mkUnitRank(unit)
  ]
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
    return resTable.keys().sort(@(a, b) nodes.get()[a].y <=> nodes.get()[b].y)
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

let acceptChooseResearch = @(unitId) set_research_unit(curCampaign.get(), unitId)

function openImpl() {
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
    children = msgBoxBg.__merge({
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = hdpx(40)
      padding = [0,0,hdpx(20),0]
      minWidth = minWidthWnd
      children = [
        msgBoxHeader(loc("unitsTree/chooseCountryResearch"), { padding = [0, buttonsHGap] })
        wndContent(startUnit, allCountries, curCountry)
        mkSmallText(loc("unitsTree/changeResearchHint"), {
          maxWidth = hdpx(700)
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_CENTER
        })
        mkSpinnerHideBlock(unitInProgress,
          textButtonBattle(loc("unitsTree/chooseResearch/accept"),
            @() acceptChooseResearch(startUnit.get()?.name), { childOvr = fontTiny }))
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
