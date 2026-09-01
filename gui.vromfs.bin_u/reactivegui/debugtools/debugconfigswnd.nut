from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/campaign.nut" import campConfigs
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/components/debugWnd.nut" import openDebugWnd
from "%rGui/debugTools/debugCampaignSelector.nut" import isForCampaign, dbgCampaignSelector
from "types" import Table, Array


let tabs = Computed(@() (isForCampaign.get() ? campConfigs.get() : serverConfigs.get())
  .filter(@(v) v instanceof Table || v instanceof Array)
  .map(@(data, id) { id, data })
  .values()
  .sort(@(a, b) a.id <=> b.id))

return {
  openDebugConfigWnd = @() openDebugWnd({ tabs, childrenOverTabs = dbgCampaignSelector, isJsonStyle = true })
}
