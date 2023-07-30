//checked for explicitness
#no-root-fallback
#explicit-this

let { Computed } = require("frp")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")

let itemsOrderFull = [
  //ships
  "ship_tool_kit"
  "ship_smoke_screen_system_mod"

  //tanks
  "tank_tool_kit_expendable"
  "tank_extinguisher"
  "spare"
]

let orderByItems = {}
foreach (idx, itemId in itemsOrderFull)
  orderByItems[itemId] <- idx

let itemsOrder = Computed(@() itemsOrderFull.filter(@(id) id in campConfigs.value?.allItems))
let itemsCfgOrdered = Computed(@() itemsOrderFull.map(@(id) campConfigs.value?.allItems[id]).filter(@(v) v != null))

return {
  itemsOrderFull
  orderByItems
  itemsOrder
  itemsCfgOrdered
}
