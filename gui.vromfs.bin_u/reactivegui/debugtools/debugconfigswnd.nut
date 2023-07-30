from "%globalsDarg/darg_library.nut" import *
let { openDebugWnd } = require("%rGui/components/debugWnd.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { isForCampaign, dbgCampaignSelector } = require("debugCampaignSelector.nut")

let tabs = Computed(@() (isForCampaign.value ? campConfigs.value : serverConfigs.value)
  .filter(@(v) type(v) == "table" || type(v) == "array")
  .map(@(data, id) { id, data })
  .values()
  .sort(@(a, b) a.id <=> b.id))

return {
  openDebugConfigWnd = @() openDebugWnd(tabs, dbgCampaignSelector)
}
