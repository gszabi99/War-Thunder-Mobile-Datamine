from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "eventbus" import eventbus_send
from "%sqstd/datablock.nut" import eachParam, isDataBlock
from "%appGlobals/loginState.nut" import isOnlineSettingsAvailable
from "%appGlobals/pServer/campaign.nut" import curCampaign, campaignsList, firstLoginTime
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile


const SAVE_ID = "seenCampaigns"
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