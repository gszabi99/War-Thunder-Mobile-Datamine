from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { isInSquad, isSquadLeader, isReady, squadLeaderCampaign } = require("%appGlobals/squadState.nut")
let { curCampaign, campaignsList, setCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { rewardTutorialMission } = require("%rGui/tutorial/tutorialMissions.nut")
let { squadAddons } = require("squadAddons.nut")
let { localizeAddons, getAddonsSizeStr } = require("%appGlobals/updater/addons.nut")

subscribeFMsgBtns({
  function squadChangeCampaignByLeader(_) {
    let campaign = squadLeaderCampaign.value
    if (curCampaign.value == campaign)
      return
    if (!campaignsList.value.contains(campaign)) {
      openFMsgBox({ text = loc("squad/cant_ready/leader_campaign_invalid") })
      return
    }
    let unit = servProfile.value?.units
      .findvalue(@(_, name) serverConfigs.value?.allUnits[name].campaign == campaign)
    if (unit == null)
      rewardTutorialMission(campaign)
    setCampaign(campaign)
  }
})

function showChangeCampaignMsg() {
  if (!campaignsList.value.contains(squadLeaderCampaign.value)) {
    openFMsgBox({ text = loc("squad/cant_ready/leader_campaign_invalid") })
    return
  }

  openFMsgBox({
    text = loc("squad/cant_ready/need_change_campaign",
      { campaign = colorize("@mark", loc(getCampaignPresentation(squadLeaderCampaign.get()).headerLocId)) })
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "continue", isDefault = true, styleId = "PRIMARY", eventId = "squadChangeCampaignByLeader" }
    ]
  })
}

function setReady(ready) {
  if (ready == isReady.value || !isInSquad.value || isSquadLeader.value)
    return
  if (!ready) {
    isReady(false)
    return
  }
  if (curCampaign.value != squadLeaderCampaign.value) {
    showChangeCampaignMsg()
    return
  }

  if (squadAddons.value.len() > 0) {
    let addonsArr = squadAddons.value.keys()
    let locs = localizeAddons(addonsArr)
    log($"[ADDONS] Ask update addons on try to set ready in the squad:", addonsArr)
    openFMsgBox({
      text = loc("msg/needAddonToPlayBySquad",
        { count = locs.len(),
          addon = ", ".join(locs.map(@(t) colorize("@mark", t)))
          size = getAddonsSizeStr(addonsArr)
        })
      buttons = [
        { id = "cancel", isCancel = true }
        { text = loc("msgbox/btn_download")
          eventId = "downloadAddonsForSquadReady"
          context = addonsArr
          styleId = "PRIMARY"
          isDefault = true
        }
      ]
    })
    return
  }

  isReady(true)
}

subscribeFMsgBtns({
  downloadAddonsForSquadReady = @(addons)
    eventbus_send("openDownloadAddonsWnd", { addons, successEventId = "squadSetReady" })
})

eventbus_subscribe("squadSetReady", @(_) setReady(true))

squadAddons.subscribe(function(v) {
  if (v.len() > 0)
    setReady(false)
})

return setReady