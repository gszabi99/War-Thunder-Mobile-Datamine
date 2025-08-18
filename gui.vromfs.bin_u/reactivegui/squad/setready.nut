from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { isInSquad, isSquadLeader, isReady, squadLeaderCampaign } = require("%appGlobals/squadState.nut")
let { curCampaign, campaignsList, setCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { rewardTutorialMission } = require("%rGui/tutorial/tutorialMissions.nut")
let { squadAddons } = require("%rGui/squad/squadAddons.nut")
let { localizeAddons, getAddonsSizeStr } = require("%appGlobals/updater/addons.nut")
let { addonsSizes } = require("%appGlobals/updater/addonsState.nut")


subscribeFMsgBtns({
  function squadChangeCampaignByLeader(_) {
    let campaign = squadLeaderCampaign.get()
    if (curCampaign.value == campaign)
      return
    if (!campaignsList.get().contains(campaign)) {
      openFMsgBox({ text = loc("squad/cant_ready/leader_campaign_invalid") })
      return
    }
    let unit = servProfile.value?.units
      .findvalue(@(_, name) serverConfigs.get()?.allUnits[name].campaign == campaign)
    if (unit == null)
      rewardTutorialMission(campaign)
    setCampaign(campaign)
  }
})

function showChangeCampaignMsg() {
  if (!campaignsList.get().contains(squadLeaderCampaign.get())) {
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
  if (ready == isReady.get() || !isInSquad.get() || isSquadLeader.get())
    return
  if (!ready) {
    isReady.set(false)
    return
  }
  if (curCampaign.get() != squadLeaderCampaign.get()) {
    showChangeCampaignMsg()
    return
  }

  if (squadAddons.get().len() > 0) {
    let addonsArr = squadAddons.get().keys()
    let locs = localizeAddons(addonsArr)
    log($"[ADDONS] Ask update addons on try to set ready in the squad:", addonsArr)
    openFMsgBox({
      text = loc("msg/needAddonToPlayBySquad",
        { count = locs.len(),
          addon = ", ".join(locs.map(@(t) colorize("@mark", t)))
          size = getAddonsSizeStr(addonsArr, addonsSizes.get())
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

  isReady.set(true)
}

subscribeFMsgBtns({
  downloadAddonsForSquadReady = @(addons)
    eventbus_send("openDownloadAddonsWnd", { addons, successEventId = "squadSetReady", bqSource = "squadSetReady" })
})

eventbus_subscribe("squadSetReady", @(_) setReady(true))

squadAddons.subscribe(function(v) {
  if (v.len() > 0)
    setReady(false)
})

return setReady