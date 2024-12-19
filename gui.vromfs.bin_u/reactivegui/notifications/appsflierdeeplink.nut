from "%globalsDarg/darg_library.nut" import *
let { parse_json } = require("json")
let { register_command } = require("console")
let { eventbus_subscribe } = require("eventbus")
let {
  getAppsFlyerDeepLink = @() null,
  clearAppsFlyerDeepLink = @() null,
  triggerAppsFlyerDeepLink = @() null
} = require("appsFlyer")
let { curCampaign, campaignsList, isAnyCampaignSelected, setCampaign } = require("%appGlobals/pServer/campaign.nut")
let { apply_deeplink_reward, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let savedDeepLink = Watched(null)
let hasSavedDeepLink = Computed(@() savedDeepLink.get() != null)
let hasSelectedCampaign = Computed(@() isLoggedIn.get() && isAnyCampaignSelected.get()
  && campaignsList.get().len() > 1)

let canApplyDeepLink = keepref(Computed(@() isLoggedIn.get() && hasSelectedCampaign.get()))
let needApplyDeepLink = keepref(Computed(@() canApplyDeepLink.get() && hasSavedDeepLink.get()))

function loadDeepLinks() {
  let deepLink = getAppsFlyerDeepLink()
  if (!deepLink) {
    log("[DEEP_LINK_DATA]: DeepLink is empty")
    return
  }
  local res = null
  try
    res = parse_json(deepLink)
  catch(e)
    logerr($"Failed to parse deep link data")

  log($"[DEEP_LINK_DATA]: {deepLink}", res)

  if (res != null && res.len() > 0)
    savedDeepLink.set(res)
}

if (canApplyDeepLink.get())
  loadDeepLinks()

let customDeepLinkHandlers = {
  blogger_reward = @(offerId) apply_deeplink_reward(offerId, curCampaign.get(), "deepLinkRewardApplied")
}

let onAppsFlyerDeepLink = @(_) loadDeepLinks()
eventbus_subscribe("appsflyer.onDeepLink", onAppsFlyerDeepLink)

function resetDeepLink() {
  savedDeepLink.set(null)
  clearAppsFlyerDeepLink()
}

registerHandler("deepLinkRewardApplied", function(res) {
  resetDeepLink()
  if ("error" not in res && res.len() > 0) {
    let offerCampaign = res?.activeOffers.findindex(@(_) true)
    if(offerCampaign && offerCampaign != curCampaign.get())
      setCampaign(offerCampaign)
  }
})

function applyDeepLink() {
  let { name = "", values = [] } = savedDeepLink.get()
  if (name not in customDeepLinkHandlers || values.len() == 0)
    return resetDeepLink()
  customDeepLinkHandlers[name](values[0])
}

if (needApplyDeepLink.get())
  applyDeepLink()

canApplyDeepLink.subscribe(@(v) v ? loadDeepLinks() : null)
needApplyDeepLink.subscribe(@(v) v ? applyDeepLink() : null)

register_command(@() triggerAppsFlyerDeepLink(), "appsFlyer.trigger_deep_link")

return { hasSavedDeepLink }
