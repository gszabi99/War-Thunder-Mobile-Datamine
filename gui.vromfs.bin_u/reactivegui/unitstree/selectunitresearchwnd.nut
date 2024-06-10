from "%globalsDarg/darg_library.nut" import *
let { addModalWindow, removeModalWindow, hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { msgBoxBg, msgBoxHeaderWithClose } = require("%rGui/components/msgBox.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { buttonsHGap } = require("%rGui/components/textButton.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { unitsResearchStatus, countries, curCountry, selectedCountry
} = require("unitsTreeNodesState.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, unitPlateTiny, mkUnitRank, mkUnitSelectedGlow, mkUnitResearchPrice
} = require("%rGui/unit/components/unitPlateComp.nut")
let { set_research_unit } = require("%appGlobals/pServer/pServerApi.nut")
let { mkTreeNodesFlag } = require("unitsTreeComps.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")


let WND_UID = "chooseUnitResearch"

let needSelectUnitResearch = keepref(Computed(@() unitsResearchStatus.get().findvalue(@(v) v?.isCurrent) == null
  && unitsResearchStatus.get().findvalue(@(v) v?.isAvailable && !v?.isResearched) != null))

let close = @() removeModalWindow(WND_UID)

function mkUnitPlate(unit, researchStatus, onClick) {
  if (unit == null)
    return null
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = unitPlateTiny
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick
    sound = { click  = "choose" }
    children = [
      mkUnitBg(unit)
      mkUnitSelectedGlow(unit, Computed(@() stateFlags.get() & S_HOVER))
      mkUnitImage(unit)
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
      mkUnitRank(unit)
      mkUnitResearchPrice(researchStatus)
    ]
  }
}

let function unitsBlock() {
  let units = Computed(@() unitsResearchStatus.get()
    .filter(@(v) v.isAvailable && !v?.isResearched)
    .keys())
  return @() {
    watch = [units, serverConfigs, unitsResearchStatus]
    flow = FLOW_HORIZONTAL
    gap = buttonsHGap
    children = units.get().map(@(u) mkUnitPlate(
      serverConfigs.get()?.allUnits[u],
      unitsResearchStatus.get()?[u],
      function() {
        set_research_unit(curCampaign.get(), u)
        close()
      }
    )).append(units.get().len() > 0 ? {} : {
      rendObj = ROBJ_TEXT
      text = loc("pr_conversion/all_units_researched")
    }.__update(fontSmall))
  }
}

let wndContent = {
  padding = buttonsHGap
  gap = buttonsHGap
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    @() {
      watch = countries
      flow = FLOW_HORIZONTAL
      children = countries.get()
        .map(@(country) mkTreeNodesFlag(
          country,
          curCountry,
          @() selectedCountry.set(country),
          Watched(false),
          { transform = { rotate = 90 } }
        ))
    }
    unitsBlock()
  ]
}

let openImpl = @() addModalWindow(bgShaded.__merge({
  key = WND_UID
  size = flex()
  onClick = close
  children = msgBoxBg.__merge({
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      msgBoxHeaderWithClose(loc("unitsTree/chooseResearch"),
        close,
        {
          minWidth = SIZE_TO_CONTENT,
          padding = [0, buttonsHGap]
        })
      wndContent
    ]
  })
  animations = wndSwitchAnim
}))

function openWndIfCan() {
  if (needSelectUnitResearch.get()
      && !hasModalWindows.get()
      && !isInBattle.get()
      && curCampaign.get() in serverConfigs.get()?.unitTreeNodes)
    openImpl()
}

if (needSelectUnitResearch.get())
  openWndIfCan()
needSelectUnitResearch.subscribe(@(v) v ? openWndIfCan() : removeModalWindow(WND_UID))

return openWndIfCan
