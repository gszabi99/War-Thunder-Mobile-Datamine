from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { unitsResearchStatus } = require("unitsTreeNodesState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { needSelectResearch } = require("selectResearchWnd.nut")
let { isUnitsTreeOpen } = require("%rGui/unitsTree/unitsTreeState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { maxBuyRequirementsAnimTime } = require("%rGui/unitsTree/treeAnimConsts.nut")

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

let animExpPart = mkWatched(persist, "animExpPart", false)
local expPartValue = 0

animUnitAfterResearch.subscribe(function(v) {
  if(v){
    anim_start($"anim_{v}")
    resetTimeout(animExpPartDelay, function() {
      animExpPart(1)
    })
  }
})

isUnitsTreeOpen.subscribe(function(v){
  if(v && animUnitAfterResearch.get()){
    animExpPart(expPartValue)
    resetTimeout(animExpPartDelay, function() {
      animExpPart(1)
    })
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
  let list = unitsResearchStatus.get()
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

unitsResearchStatus.subscribe(function(v){
  if(v){
    let list = unitsForExpAnim.get()
    foreach(key, value in list){
      if(v?[key].exp != value?.expStart){
        if(v?[key].isResearched){
          expPartValue = (1.0 * (value?.expStart ?? 0))/(v?[key].reqExp ?? 1)
          animUnitAfterResearch(key)
        }
        unitsForExpAnim.set(unitsForExpAnim.get().__merge({
          [key] = { expStart = v?[key].exp }
        }))
      }
    }
  }
})

let animBuyRequirements = Computed(function() {
  let res = {}
  if (animBuyRequirementsUnitId.get() == null)
    return res
  let allNodes = serverConfigs.get()?.unitTreeNodes[curCampaign.get()]
  let list = [animBuyRequirementsUnitId.get()]
  foreach(name in list) {
    let node = allNodes?[name]
    if (!node)
      continue
    foreach(u in node.reqUnits)
      if (u not in res) {
        res[u] <- true
        list.append(u) // warning disable: -modified-container
      }
  }
  return res
})

let clearRequirementsAnim = @() animBuyRequirementsUnitId.set(null)
animBuyRequirementsUnitId.subscribe(@(v) v == null ? null : resetTimeout(maxBuyRequirementsAnimTime, clearRequirementsAnim))
animBuyRequirements.subscribe(@(v) v.each(@(_, id) anim_start($"unit_price_{id}")))

return {
  animUnitAfterResearch
  animUnitWithLink
  animNewUnitsAfterResearch
  needShowPriceUnit
  hasAnimDarkScreen
  animExpPart
  animBuyRequirementsUnitId
  animBuyRequirements

  isBuyUnitWndOpened
  canPlayAnimUnitWithLink
  animNewUnitsAfterResearchTrigger

  unitsForExpAnim

  resetAnim
}