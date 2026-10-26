from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/pServer/slots.nut" import curCampaignSlotUnits
from "%rGui/components/levelBlockPkg.nut" import mkProgressLevelBg
from "%rGui/rewards/rewardViewInfo.nut" import getBlueprintBarColor
from "%rGui/unit/unitAccess.nut" import byBlockedUnits
from "%rGui/unitsTree/treeAnimConsts.nut" import attractColor, aTimeHint, aTimePriceScale
from "%rGui/unitsTree/unitNodesReceiveInfo.nut" import getReceiveDesc
from "%rGui/unitsTree/unitsTreeNodesState.nut" import unitsResearchStatus


const statsWidth = hdpx(495)
let barSize = [statsWidth, hdpx(30)]

const unitResearchExpColor = 0xFFE86C00
const researchBlockWidth = statsWidth

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
          size = [ pw(100 * percent), FLEX ]
          rendObj = ROBJ_SOLID
          color
        }}.__update(ovr))
      {
        size = FLEX
        halign = ALIGN_CENTER
        rendObj = ROBJ_TEXT
        text = "/".concat(cur, req)
      }.__update(fontVeryTinyAccented)
    ]
  }
}

let mkBarText = @(text) {
  size = const [statsWidth, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  text
}.__update(fontTiny)

function blueprintBar(unit) {
  let curBluebrintsCount = Computed(@() servProfile.get()?.blueprints?[unit.name] ?? 0)
  let reqBluebrintsCount = Computed(@() serverConfigs.get()?.allBlueprints?[unit.name].targetCount ?? 1)
  let blueprintDescText = mkBarText(loc("blueprints/desc"))
  let isBlocked = Computed(@() unit.name in byBlockedUnits.get())
  return @() unit.name in serverConfigs.get()?.allBlueprints && unit.name not in campMyUnits.get() && !isBlocked.get()
    ? {
      watch = [curBluebrintsCount, reqBluebrintsCount, serverConfigs, campMyUnits, isBlocked]
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = hdpx(5)
      children = [
        blueprintDescText
        mkLevelLine(curBluebrintsCount.get(), reqBluebrintsCount.get(),
          getBlueprintBarColor(unit.name, serverConfigs.get()))
      ]}
    : { watch = [serverConfigs, campMyUnits, isBlocked] }
}

let unitExpBar = @(unitName, unitResearch) function() {
  let { isCurrent = false, canResearch = false, exp = 0, reqExp = 1, hasAccessLock = true } = unitResearch.get()
  let isBlocked = hasAccessLock && unitName in byBlockedUnits.get()
  return {
    watch = [unitResearch, campMyUnits, byBlockedUnits]
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
    let { isCurrent = false, canResearch = false, canBuy = false, isResearched = false,
      hasAccessLock = true
    } = unitResearch.get()
    if (hasAccessLock && unitName in byBlockedUnits.get())
      return null
    return isCurrent ? "unitsTree/currentResearch"
      : canResearch ? "unitsTree/availableForResearch"
      : !isResearched ? "unitsTree/researchHint"
      : !canBuy ? "unitsTree/buyHint/build"
      : null
  })

  let needHint = Computed(@() hintLocId.get() != null || unitName not in campMyUnits.get())
  let hintAnimations = [
    { prop = AnimProp.color, to = attractColor, duration = aTimeHint, easing = CosineFull,
      trigger = "unitInfoActionHint" }
    { prop = AnimProp.scale, to = const [1.2, 1.2], duration = aTimePriceScale, easing = CosineFull,
      trigger = "unitInfoActionHint" }
  ]
  let hintRow = [
    @() {
      watch = hintLocId
      key = hintLocId
      size = const [statsWidth, SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_LEFT
      text = hintLocId.get() == null ? null : loc(hintLocId.get())
      transform = {}
      animations = hintAnimations
    }.__update(fontTiny)
    unitExpBar(unitName, unitResearch)
  ]
  return @() !needHint.get() ? { watch = needHint }
    : {
        watch = needHint
        size = FLEX_H
        halign = ALIGN_RIGHT
        flow = FLOW_VERTICAL
        gap = hdpx(10)
        children = hintRow
      }
}

function mkReceiveInfoText(receiveInfo) {
  let { receiveType = null, receiveData = null } = receiveInfo
  let text = getReceiveDesc(receiveType, receiveData)
  return text == "" ? null : mkBarText(text)
}

let researchBlock = @(unit, receiveInfo = null) unit == null ? null
  : {
      size = const [researchBlockWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      valign = ALIGN_BOTTOM
      children = [
        blueprintBar(unit)
        unitResearchBar(unit.name)
        mkReceiveInfoText(receiveInfo)
      ]
    }

return {
  mkBarText
  blueprintBar
  researchBlock
}
