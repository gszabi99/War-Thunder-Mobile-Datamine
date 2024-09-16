
let { Computed } = require("frp")
let { campConfigs, campaignsList } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let SPARE = "spare"

let itemsOrderFull = [
  //ships
  "ship_tool_kit"
  "ship_smoke_screen_system_mod"
  "ircm_kit"

  //tanks
  "tank_tool_kit_expendable"
  "tank_extinguisher"
  SPARE

  //event
  "firework_kit"
]

let hiddenItems = ["ircm_kit", "firework_kit"].reduce(@(res, v) res.$rawset(v, true), {})

let orderByItems = {}
foreach (idx, itemId in itemsOrderFull)
  orderByItems[itemId] <- idx

let itemsOrder = Computed(@() itemsOrderFull.filter(@(id) id not in hiddenItems
  && id in campConfigs.value?.allItems))
let itemsCfgOrdered = Computed(@() itemsOrderFull
  .map(@(id) id in hiddenItems ? null : campConfigs.get()?.allItems[id])
  .filter(@(v) v != null))
let itemsCfgByCampaignOrdered = Computed(function() {
  let { allItems = {}, campaignCfg = {} } = serverConfigs.get()
  let needUseBit = "campaign" not in allItems.findvalue(@(_) true) //compatibility with 2024.08.26
  let res = {}
  foreach (campaignName, campaign in campaignCfg) {
    let { bit = 0 } = campaign
    let campId = campaignsList.get()?.findindex(@(c) c == campaignName)

    let itemsConfigByCampaign = needUseBit
      ? allItems.filter(@(o) (o.campaigns & bit) != 0)
      : allItems.filter(@(o) o.campaign == campId)

    res[campaignName] <- itemsOrderFull
      .map(@(id) id in hiddenItems ? null : itemsConfigByCampaign?[id])
      .filter(@(v) v != null)
  }
  return res
})

return {
  SPARE
  itemsCfgByCampaignOrdered
  itemsOrderFull
  orderByItems
  itemsOrder
  itemsCfgOrdered
}
