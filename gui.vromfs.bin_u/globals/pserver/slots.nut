let { Computed } = require("frp")
let { isEqual } = require("%sqstd/underscore.nut")
let { campConfigs, campProfile } = require("%appGlobals/pServer/campaign.nut")


let isCampaignWithSlots = Computed(@() (campConfigs.get()?.campaignCfg.totalSlots ?? 0) > 0)
let curCampaignSlots = Computed(@() isCampaignWithSlots.get() ? campProfile.get()?.campaignSlots : null)

let curSlots = Computed(function() {
  let res = clone curCampaignSlots.get()?.slots ?? []
  return res.resize(curCampaignSlots.get()?.totalSlots ?? 0)
})

let curCampaignSlotUnits = Computed(function(prev) {
  let res = curCampaignSlots.get()?.slots
    .map(@(s) s.name)
    .filter(@(v) v != "")
  return isEqual(res, prev) ? prev : res
})

return {
  curSlots
  curCampaignSlots
  curCampaignSlotUnits
  isCampaignWithSlots
}
