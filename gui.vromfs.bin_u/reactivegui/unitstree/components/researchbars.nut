from "%globalsDarg/darg_library.nut" import *
let { mkProgressLevelBg } = require("%rGui/components/levelBlockPkg.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { curCampaignSlotUnits } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { attractColor, aTimeHint, aTimePriceScale } = require("%rGui/unitsTree/treeAnimConsts.nut")


let { unitsResearchStatus } = require("%rGui/unitsTree/unitsTreeNodesState.nut")


let barSize = [hdpx(500), hdpx(30)]

let blueprintBarColor = 0xFF3384C4
let unitResearchExpColor = 0xFFE86C00
let statsWidth = hdpx(500)

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

function blueprintBar(unit){
  let curBluebrintsCount = Computed(@() servProfile.get()?.blueprints?[unit.name] ?? 0)
  let reqBluebrintsCount = Computed(@() serverConfigs.get()?.allBlueprints?[unit.name].targetCount ?? 1)
  return  @() unit.name in serverConfigs.get()?.allBlueprints && unit.name not in myUnits.get()
    ? {
      watch = [curBluebrintsCount, reqBluebrintsCount, serverConfigs, myUnits]
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children = [
        {
          size = [statsWidth, SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_CENTER
          text = loc("blueprints/desc")
        }.__update(fontTinyAccented)
        mkLevelLine(curBluebrintsCount.get(), reqBluebrintsCount.get(), blueprintBarColor)
      ]}
    : { watch = [serverConfigs, myUnits]}
}

let unitExpBar = @(unitName, unitResearch) function() {
  let { isCurrent = false, canResearch = false, exp = 0, reqExp = 1 } = unitResearch.get()
  return {
    watch = [unitResearch, myUnits]
    children = unitName not in myUnits.get() && (isCurrent || canResearch)
      ? mkLevelLine(exp, reqExp, unitResearchExpColor)
      : null
  }
}

function unitResearchBar(unitName) {
  let unitResearch = Computed(@() unitsResearchStatus.get()?[unitName])
  let hintLocId = Computed(function() {
    if (unitName in myUnits.get())
      return curCampaignSlotUnits.get()?.findvalue(@(v) v == unitName) != null
        ? "slotbar/installedUnit"
        : null
    if (unitResearch.get() == null)
      return null
    let { isCurrent = false, canResearch = false, canBuy = false, isResearched = false } = unitResearch.get()
    return isCurrent ? "unitsTree/currentResearch"
      : canResearch ? "unitsTree/availableForResearch"
      : !isResearched ? "unitsTree/researchHint"
      : !canBuy ? "unitsTree/buyHint"
      : null
  })

  let needHint = Computed(@() hintLocId.get() != null || unitName not in myUnits.get())
  return @() !needHint.get() ? { watch = needHint }
    : {
        watch = needHint
        size = [flex(), SIZE_TO_CONTENT]
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
            halign = ALIGN_CENTER
            text = hintLocId.get() == null ? null : loc(hintLocId.get())
            transform = {}
            animations = [
              { prop = AnimProp.color, to = attractColor, duration = aTimeHint, easing = CosineFull,
                trigger = "unitInfoActionHint" }
              { prop = AnimProp.scale, to = [1.2, 1.2], duration = aTimePriceScale, easing = CosineFull,
                trigger = "unitInfoActionHint" }
            ]
          }.__update(fontTinyAccented)
          unitExpBar(unitName, unitResearch)
        ]
      }
}

let researchBlock = @(unit) {
  size = [statsWidth, SIZE_TO_CONTENT]
  padding = [hdpx(50), 0]
  children = [
    blueprintBar(unit)
    unitResearchBar(unit.name)
  ]
}

return {
  researchBlock
}
