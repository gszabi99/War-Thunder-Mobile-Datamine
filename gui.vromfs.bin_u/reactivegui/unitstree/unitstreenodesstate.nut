from "%globalsDarg/darg_library.nut" import *
let { isEqual } = require("%sqstd/underscore.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { allUnitsCfg, myUnits } = require("%appGlobals/pServer/profile.nut")
let { filters, filterCount } = require("%rGui/unit/unitsFilterPkg.nut")


let nodes = Computed(@() serverConfigs.get()?.unitTreeNodes[curCampaign.get()])
let selectedCountry = mkWatched(persist, "selectedCountry", null)
let curCountry = Computed(@() nodes.get()?.findvalue(@(n) n?.nodeCountry == selectedCountry.get()).nodeCountry
  ?? nodes.get()?[0].nodeCountry)

let countries = Computed(function() {
  let res = {}
  foreach (node in nodes.get() ?? [])
    if (node?.nodeCountry && node.nodeCountry not in res)
      res[node.nodeCountry] <- true
  return res.keys()
})

let filteredNodes = Computed(function(prev) {
  local res = nodes.get()?.filter(@(v) v?.nodeCountry == curCountry.get()
      && (!allUnitsCfg.get()?[v.name].isHidden || v.name in myUnits.get()))
    ?? {}

  if (filterCount.get() > 0)
    foreach (f in filters) {
      let value = f.value.get()
      if (value != null)
        res = res.filter(@(node) f.isFit(allUnitsCfg.get()?[node.name], value))
    }

  local prevX = 0
  local xGaps = {}
  foreach (node in res.values().sort(@(a, b) a.x <=> b.x)) {
    node.xMod <- node.x
    if (node.x - prevX > 1)
      xGaps[node.x] <- (node.x - prevX - 1)
    prevX = node.x
    foreach (gapX, gapSize in xGaps)
      if (node.x >= gapX)
        node.xMod = (node?.xMod ?? node.x) - gapSize

    let isAvailable = node.reqUnits.len() == 0
      || null != node.reqUnits.findvalue(@(parent)
        servProfile.get()?.unitsResearch[parent].isResearched || parent in myUnits.get())
    node.isAvailable <- isAvailable
    node.needParentToBuy <- isAvailable && node.reqUnits.findvalue(@(parent) parent not in myUnits.get())
  }

  local prevY = 0
  local yGaps = {}
  foreach (node in res.values().sort(@(a, b) a.y <=> b.y)) {
    node.yMod <- node.y
    if (node.y - prevY > 1)
      yGaps[node.y] <- (node.y - prevY - 1)
    prevY = node.y
    foreach (gapY, gapSize in yGaps)
      if (node.y >= gapY)
        node.yMod = (node?.yMod ?? node.y) - gapSize
  }

  return isEqual(prev, res) ? prev : res
})

let unitsResearchStatus = Computed(function(prev) {
  let res = {}
  foreach (unitName, reqExp in serverConfigs.get()?.unitResearchExp ?? {}) {
    let hasUnlockedParent = filteredNodes.get()?[unitName].isAvailable ?? false
    let isAvailable = hasUnlockedParent && unitName not in myUnits.get()
    res[unitName] <- {
      isAvailable
      reqExp
    }
  }
  foreach (unitName, unitResearch in servProfile.value?.unitsResearch ?? {}) {
    let { exp = 0, isCurrent = false, isResearched = false, canBuy = false
    } = unitResearch
    res[unitName].__update({
      isCurrent
      isResearched
      canBuy = canBuy || serverConfigs.get()?.allUnits[unitName].isPremium
      exp
    })
  }
  return isEqual(prev, res) ? prev : res
})

return {
  nodes
  selectedCountry
  curCountry
  countries
  filteredNodes
  unitsResearchStatus
}