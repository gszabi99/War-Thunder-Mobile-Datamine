from "%globalsDarg/darg_library.nut" import *
let { mkProgressLevelBg } = require("%rGui/components/levelBlockPkg.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { curCampaignSlotUnits } = require("%appGlobals/pServer/slots.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { attractColor, aTimeHint, aTimePriceScale } = require("%rGui/unitsTree/treeAnimConsts.nut")
let { unitsResearchStatus, blockedCountries } = require("%rGui/unitsTree/unitsTreeNodesState.nut")


let statsWidth = hdpx(495)
let barSize = [statsWidth, hdpx(30)]

let blueprintBarColor = 0xFF3384C4
let unitResearchExpColor = 0xFFE86C00
let researchBlockWidth = statsWidth

function mkLevelLine(cur, req, color, ovr = {}) {
  let percent =  1.0 * clamp(cur, 0, req ) / req
  return {
    valign = ALIGN_CENTER
    children = [
      mkProgressLevelBg({
        size = barSize
        fillColor = 0xFF000000
        borderColor = 0xFFFFFFFF
        children = {
          size = [ pw(100 * percent), flex() ]
          rendObj = ROBJ_SOLID
          color
        }}.__update(ovr))
      {
        size = flex()
        halign = ALIGN_CENTER
        rendObj = ROBJ_TEXT
        text = "/".concat(cur, req)
      }.__update(fontVeryTinyAccented)
    ]
  }
}

let mkBarText = @(text) {
  size = [statsWidth, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  text
}.__update(fontTiny)

function blueprintBar(unit) {
  let curBluebrintsCount = Computed(@() servProfile.get()?.blueprints?[unit.name] ?? 0)
  let reqBluebrintsCount = Computed(@() serverConfigs.get()?.allBlueprints?[unit.name].targetCount ?? 1)
  let isBlocked = unit.country in blockedCountries.get()
  return @() unit.name in serverConfigs.get()?.allBlueprints && unit.name not in campMyUnits.get() && !isBlocked
    ? {
      watch = [curBluebrintsCount, reqBluebrintsCount, serverConfigs, campMyUnits, blockedCountries]
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = hdpx(5)
      children = [
        mkBarText(loc("blueprints/desc"))
        mkLevelLine(curBluebrintsCount.get(), reqBluebrintsCount.get(), blueprintBarColor)
      ]}
    : { watch = [serverConfigs, campMyUnits, blockedCountries]}
}

let unitExpBar = @(unitName, unitResearch) function() {
  let { isCurrent = false, canResearch = false, exp = 0, reqExp = 1, country = "" } = unitResearch.get()
  let isBlocked = country in blockedCountries.get()
  return {
    watch = [unitResearch, campMyUnits, blockedCountries]
    children = unitName not in campMyUnits.get() && (isCurrent || canResearch) && !isBlocked
      ? mkLevelLine(exp, reqExp, unitResearchExpColor)
      : null
  }
}

function unitResearchBar(unitName) {
  let unitResearch = Computed(@() unitsResearchStatus.get()?[unitName])
  let hintLocId = Computed(function() {
    if (unitName in campMyUnits.get())
      return curCampaignSlotUnits.get()?.findvalue(@(v) v == unitName) != null
        ? "slotbar/installedUnit"
        : null
    if (unitResearch.get() == null)
      return null
    let { isCurrent = false, canResearch = false, canBuy = false, isResearched = false, country = "" } = unitResearch.get()
    if (country in blockedCountries.get())
      return null
    return isCurrent ? "unitsTree/currentResearch"
      : canResearch ? "unitsTree/availableForResearch"
      : !isResearched ? "unitsTree/researchHint"
      : !canBuy ? "unitsTree/buyHint/build"
      : null
  })

  let needHint = Computed(@() hintLocId.get() != null || unitName not in campMyUnits.get())
  return @() !needHint.get() ? { watch = needHint }
    : {
        watch = needHint
        size = FLEX_H
        halign = ALIGN_RIGHT
        flow = FLOW_VERTICAL
        gap = hdpx(10)
        children = [
          @() {
            watch = hintLocId
            key = hintLocId
            size = [statsWidth, SIZE_TO_CONTENT]
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            halign = ALIGN_LEFT
            text = hintLocId.get() == null ? null : loc(hintLocId.get())
            transform = {}
            animations = [
              { prop = AnimProp.color, to = attractColor, duration = aTimeHint, easing = CosineFull,
                trigger = "unitInfoActionHint" }
              { prop = AnimProp.scale, to = [1.2, 1.2], duration = aTimePriceScale, easing = CosineFull,
                trigger = "unitInfoActionHint" }
            ]
          }.__update(fontTiny)
          unitExpBar(unitName, unitResearch)
        ]
      }
}

let researchBlock = @(unit) unit == null ? null
  : {
      size = [researchBlockWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      valign = ALIGN_BOTTOM
      children = [
        blueprintBar(unit)
        unitResearchBar(unit.name)
      ]
    }

return {
  mkBarText
  blueprintBar
  researchBlock
}
