from "%globalsDarg/darg_library.nut" import *
from "appsFlyer" import getAppsFlyerDeepLink, clearAppsFlyerDeepLink, triggerAppsFlyerDeepLink
from "console" import register_command
from "eventbus" import eventbus_subscribe
from "json" import parse_json
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/campaign.nut" import curCampaign, campaignsList, isAnyCampaignSelected, setCampaign
from "%appGlobals/pServer/pServerApi.nut" import apply_deeplink_reward, registerHandler


let savedDeepLink = Watched(null)
let hasSavedDeepLink = Computed(@() savedDeepLink.get() != null)
let hasSelectedCampaign = Computed(@() isLoggedIn.get() && isAnyCampaignSelected.get()
  && campaignsList.get().len() > 1)

let canApplyDeepLink = keepref(Computed(@() isLoggedIn.get() && hasSelectedCampaign.get()))
let needApplyDeepLink = keepref(Computed(@() canApplyDeepLink.get() && hasSavedDeepLink.get()))

function loadDeepLinks() {
  let deepLink = getAppsFlyerDeepLink()
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
