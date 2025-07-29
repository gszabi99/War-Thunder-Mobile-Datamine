from "%globalsDarg/darg_library.nut" import *
let { openDebugWnd } = require("%rGui/components/debugWnd.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { campProfile } = require("%appGlobals/pServer/campaign.nut")
let { isForCampaign, dbgCampaignSelector } = require("debugCampaignSelector.nut")

let tabs = Computed(@() (isForCampaign.get() ? campProfile.value : servProfile.value)
  .filter(@(v) type(v) == "table" || type(v) == "array")
  .map(@(data, id) { id, data })
  .values()
  .sort(@(a, b) a.id <=> b.id))

return {
  openDebugProfileWnd = @() openDebugWnd(tabs, dbgCampaignSelector)
}

