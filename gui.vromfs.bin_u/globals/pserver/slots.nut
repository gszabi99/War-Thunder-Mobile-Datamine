let { Computed } = require("frp")
let { isEqual } = require("%sqstd/underscore.nut")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { campConfigs, campProfile, curCampaign } = require("%appGlobals/pServer/campaign.nut")


let slotsSelectedByUser = sharedWatched("slotsSelectedByUser", @() {})

let isCampaignWithSlots = Computed(@() (campConfigs.get()?.campaignCfg.totalSlots ?? 0) > 0)
let curCampaignSlots = Computed(function() {
  if (!isCampaignWithSlots.get())
    return null
  let campaignSlots = campProfile.get()?.campaignSlots
  if (campaignSlots == null)
    return null
  let slots = slotsSelectedByUser.get()?[curCampaign.get()] ?? campaignSlots.slots
  let { allUnits = {} } = campConfigs.get()
  return campaignSlots.__merge({ slots = slots.map(@(v) v.name in allUnits ? v : v.__merge({ name = "" })) })
})

let curSlots = Computed(function() {
  let res = clone curCampaignSlots.get()?.slots ?? []
  return res.resize(curCampaignSlots.get()?.totalSlots ?? 0)
})

let curCampaignSlotUnits = Computed(function(prev) {
  if (!isCampaignWithSlots.get())
    return null
  let slots = curSlots.get()
  let res = slots?.map(@(s) s.name)
    .filter(@(v) v != "")
  return isEqual(res, prev) ? prev : res
})

isLoggedIn.subscribe(@(v) !v ? slotsSelectedByUser.set({}) : null)

return {
  curSlots
  curCampaignSlots
  curCampaignSlotUnits
  isCampaignWithSlots
  slotsSelectedByUser
}
