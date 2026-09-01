from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/campaign.nut" import campProfile
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/components/debugWnd.nut" import openDebugWnd
from "%rGui/debugTools/debugCampaignSelector.nut" import isForCampaign, dbgCampaignSelector
from "types" import Table, Array


let tabs = Computed(@() (isForCampaign.get() ? campProfile.get() : servProfile.get())
  .filter(@(v) v instanceof Table || v instanceof Array)
  .map(@(data, id) { id, data })
  .values()
  .sort(@(a, b) a.id <=> b.id))

return {
  openDebugProfileWnd = @() openDebugWnd({ tabs, childrenOverTabs = dbgCampaignSelector, isJsonStyle = true })
}

