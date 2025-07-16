from "%globalsDarg/darg_library.nut" import *
let { get_local_custom_settings_blk } = require("blkGetters")
let { eventbus_send } = require("eventbus")
let { eachParam, isDataBlock } = require("%sqstd/datablock.nut")
let { curCampaign, campaignsList, firstLoginTime } = require("%appGlobals/pServer/campaign.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")


let SAVE_ID = "seenCampaigns"
let seenCampaigns = Watched({})

let newReleasedCampaigns = Computed(function() {
  let { campaignCfg = {} } = serverConfigs.get()
  return campaignCfg.filter(function(cfg, campaign) {
    let { releaseDate = 0 } = cfg
    return releaseDate > firstLoginTime.get()
      && (servProfile.get()?.levelInfo[campaign].exp ?? 0) == 0
      && (servProfile.get()?.levelInfo[campaign].level ?? 0) == 0
      && campaignsList.get().contains(campaign)
  })
})

let unseenCampaigns = Computed(@() newReleasedCampaigns.get().filter(@(_, c) c not in seenCampaigns.get() && c != curCampaign.get()))

function loadSeen() {
  if (!isOnlineSettingsAvailable.get())
    return
  let blk = get_local_custom_settings_blk()?[SAVE_ID]
  if (!isDataBlock(blk)) {
    seenCampaigns.set({})
    return
  }
  let seen = {}
  eachParam(blk, @(_, campaign) seen.$rawset(campaign, true))
  seenCampaigns.set(seen)
}

loadSeen()
isOnlineSettingsAvailable.subscribe(@(_) loadSeen())

function markAllCampaignsSeen() {
  if (null == newReleasedCampaigns.get().findvalue(@(_, c) c not in seenCampaigns.get()))
    return
  let blk = get_local_custom_settings_blk().addBlock(SAVE_ID)
  let newSeen = {}
  foreach(c, _ in newReleasedCampaigns.get()) {
    newSeen[c] <- true
    blk[c] = true
  }
  eventbus_send("saveProfile", {})
  seenCampaigns.set(newSeen)
}

return {
  unseenCampaigns
  markAllCampaignsSeen
}