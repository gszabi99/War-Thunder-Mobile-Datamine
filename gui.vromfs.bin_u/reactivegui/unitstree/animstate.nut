from "%globalsDarg/darg_library.nut" import *
let { playSound } = require("sound_wt")
let { resetTimeout } = require("dagor.workcycle")
let { unitsResearchStatus, blueprintUnitsStatus, setUnitToScroll } = require("unitsTreeNodesState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { needSelectResearch } = require("selectResearchWnd.nut")
let { isUnitsTreeOpen } = require("%rGui/unitsTree/unitsTreeState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { maxBuyRequirementsAnimTime, maxResearchRequirementsAnimTime } = require("%rGui/unitsTree/treeAnimConsts.nut")

let animExpPartDelay = 0.3

let animNewUnitsAfterResearchTrigger = "animNewUnitsAfterResearchTrigger"

let isBuyUnitWndOpened = mkWatched(persist, "isBuyUnitWndOpened", false)
let animUnitAfterResearch = mkWatched(persist, "animUnitAfterResearch", null)
let canPlayAnimUnitWithLink = mkWatched(persist, "canPlayAnimUnitWithLink", false)
let animUnitWithLink = mkWatched(persist, "animUnitWithLink", null)
let animNewUnitsAfterResearch = mkWatched(persist, "animNewUnitsAfterResearch", {})
let needShowPriceUnit = mkWatched(persist, "needShowPriceUnit", false)
let hasAnimDarkScreen = mkWatched(persist, "hasAnimDarkScreen", false)
let animBuyRequirementsUnitId = mkWatched(persist, "animBuyRequirementsUnitId", null)
let animResearchRequirementsUnitId = mkWatched(persist, "animResearchRequirementsUnitId", null)
let needDelayAnimation = mkWatched(persist, "needDelayAnimation", false)

let animExpPart = mkWatched(persist, "animExpPart", 0)
local expPartValue = 0

animUnitAfterResearch.subscribe(function(v) {
  if(v) {
    anim_start($"anim_{v}")
    resetTimeout(animExpPartDelay, @() animExpPart(1))
  }
})

isUnitsTreeOpen.subscribe(function(v){
  if(v && animUnitAfterResearch.get()) {
    if (animUnitAfterResearch.get() in blueprintUnitsStatus.get())
      setUnitToScroll(animUnitAfterResearch.get())
    animExpPart(expPartValue)
    resetTimeout(animExpPartDelay, @() animExpPart(1))
  }
})

let canPlayAnimUnitAfterResearch = Computed(@() animUnitAfterResearch.get() != null && !needDelayAnimation.get())
needDelayAnimation.subscribe(function(v) {
  if(!v) {
    animExpPart(expPartValue)
    resetTimeout(animExpPartDelay, @() animExpPart(1))
  }
})

function resetAnim() {
  animUnitAfterResearch.set(null)
  canPlayAnimUnitWithLink.set(false)
  animUnitWithLink.set(null)
  animNewUnitsAfterResearch.set({})
  needShowPriceUnit.set(false)
  hasAnimDarkScreen.set(false)
}

let unitsForExpAnim = mkWatched(persist, "unitsForExpAnim", {})

function loadStatusesAnimUnits(){
  let list = {}.__merge(unitsResearchStatus.get(), blueprintUnitsStatus.get())
  let res = {}
  foreach(unitName, unit in list){
    res[unitName] <- {
      expStart = unit.exp
    }
  }
  unitsForExpAnim.set(res)
}

isLoggedIn.subscribe(@(v) v ? loadStatusesAnimUnits() : null)
needSelectResearch.subscribe(@(v) v ? loadStatusesAnimUnits() : null)

function updateUnitsResearchProgress(v) {
  if (!v)
    return

  let list = unitsForExpAnim.get()
  let addList = {}
  foreach(key, value in list)
    if(v?[key].exp != value?.expStart){
      if(v?[key].isResearched){
        expPartValue = (1.0 * (value?.expStart ?? 0))/(v?[key].reqExp ?? 1)
        animUnitAfterResearch(key)
      }
      addList.__update({ [key] = { expStart = v?[key].exp } })
    }
  if (addList.len() > 0)
    unitsForExpAnim.set(unitsForExpAnim.get().__merge(addList))
}

unitsResearchStatus.subscribe(updateUnitsResearchProgress)
blueprintUnitsStatus.subscribe(updateUnitsResearchProgress)

function mkAnimRequirements(unitId, allNodes, isUnlock = @(_) true) {
  let res = {}
  let ancestors = {}
  if (unitId == null)
    return { res, ancestors }
  let list = [unitId]
  foreach(name in list) {
    let node = allNodes?[name]
    if (!node)
      continue
    local last = node.reqUnits.len() == 0
      || null != node.reqUnits.findvalue(isUnlock)
    if (last)
      ancestors[name] <- true
    else {
      list.extend(node.reqUnits) 
      foreach(n in node.reqUnits)
        res[n] <- true
    }
  }
  return { res, ancestors }
}

let allNodes = Computed(@() serverConfigs.get()?.unitTreeNodes[curCampaign.get()])
let animBuyRequirementsInfo = Computed(function() {
  let my = campMyUnits.get()
  return mkAnimRequirements(animBuyRequirementsUnitId.get(), allNodes.get(), @(name) name in my)
})
let animBuyRequirements = Computed(@() animBuyRequirementsInfo.get().res)

let animResearchRequirementsInfo = Computed(function() {
  let status = unitsResearchStatus.get()
  let my = campMyUnits.get()
  return mkAnimRequirements(
    animResearchRequirementsUnitId.get(),
    allNodes.get(),
    @(name) (name in my) || (status?[name].isResearched ?? false))
})
let animResearchRequirements = Computed(@() animResearchRequirementsInfo.get().res)
let animResearchRequirementsAncestors = Computed(@() animResearchRequirementsInfo.get().ancestors)

let clearBuyRequirementsAnim = @() animBuyRequirementsUnitId.set(null)
let clearResearchRequirementsAnim = @() animResearchRequirementsUnitId.set(null)
animBuyRequirementsUnitId.subscribe(@(v) v == null ? null : resetTimeout(maxBuyRequirementsAnimTime, clearBuyRequirementsAnim))
animResearchRequirementsUnitId.subscribe(@(v) v == null ? null
  : resetTimeout(maxResearchRequirementsAnimTime, clearResearchRequirementsAnim))
animBuyRequirements.subscribe(@(v) v.each(@(_, id) anim_start($"unit_price_{id}")))
animResearchRequirements.subscribe(@(v) v.each(@(_, id) anim_start($"unit_exp_{id}")))
needShowPriceUnit.subscribe(@(v) v ? playSound("meta_research_complete") : null)

return {
  animUnitAfterResearch
  animUnitWithLink
  animNewUnitsAfterResearch
  needShowPriceUnit
  hasAnimDarkScreen
  animExpPart
  animBuyRequirementsUnitId
  animBuyRequirements
  animBuyRequirementsInfo
  animResearchRequirementsUnitId
  animResearchRequirements
  animResearchRequirementsAncestors

  isBuyUnitWndOpened
  canPlayAnimUnitWithLink
  animNewUnitsAfterResearchTrigger

  unitsForExpAnim

  resetAnim
  needDelayAnimation
  canPlayAnimUnitAfterResearch
  loadStatusesAnimUnits
}