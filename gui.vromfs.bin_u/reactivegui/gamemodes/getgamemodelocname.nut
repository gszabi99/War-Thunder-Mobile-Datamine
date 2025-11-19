from "%globalsDarg/darg_library.nut" import *
from "dagor.localize" import doesLocTextExist
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation


function getGameModeLocName(mode) {
  let { name = "", displayType = "", campaign = "", eventId = null } = mode
  if (displayType == "random_battle")
    return loc(getCampaignPresentation(campaign).headerLocId)

  if (eventId != null)
    return loc(getEventPresentation(eventId).locId)

  let locId = $"gameMode/{name}"
  return doesLocTextExist(locId) ? loc(locId) : name
}

return getGameModeLocName