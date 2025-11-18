from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { isInSquad, isSquadLeader, isReady, squadLeaderCampaign } = require("%appGlobals/squadState.nut")
let { curCampaign, campaignsList, setCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { localizeAddons } = require("%appGlobals/updater/addons.nut")
let { localizeUnitsResources } = require("%appGlobals/updater/campaignAddons.nut")
let { hasAddons, addonsExistInGameFolder, addonsVersions, unitSizes
} = require("%appGlobals/updater/addonsState.nut")
let { allUnitsRanks, allBattleUnits, missingUnitResourcesByRank, getModeAddonsInfo, maxReleasedUnitRanks
} = require("%appGlobals/updater/gameModeAddons.nut")
let { openDownloadAddonsWnd } = require("%rGui/updater/updaterState.nut")
let { requiredSquadAddons } = require("%rGui/updater/randomBattleModeAddons.nut")


subscribeFMsgBtns({
  function squadChangeCampaignByLeader(_) {
    let campaign = squadLeaderCampaign.get()
    if (curCampaign.get() == campaign)
      return
    if (!campaignsList.get().contains(campaign)) {
      openFMsgBox({ text = loc("squad/cant_ready/leader_campaign_invalid") })
      return
    }
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

function getRequiredAddonsNotUpdatable(mGMode) {
  let { addonsToDownload, unitsToDownload } = getModeAddonsInfo({
    mode = mGMode,
    unitNames = allBattleUnits.get(),
    serverConfigsV = serverConfigs.get(),
    hasAddonsV = hasAddons.get(),
    addonsExistInGameFolderV = addonsExistInGameFolder.get(),
    addonsVersionsV = addonsVersions.get(),
    missingUnitResourcesByRankV = missingUnitResourcesByRank.get(),
    maxReleasedUnitRanksV = maxReleasedUnitRanks.get(),
    unitSizesV = unitSizes.get(),
  })
  return { addons = addonsToDownload, units = unitsToDownload }
}

function setReady(ready, mGMode = null) {
  if (ready == isReady.get() || !isInSquad.get() || isSquadLeader.get())
    return
  if (!ready) {
    isReady.set(false)
    return
  }
  if (mGMode == null && curCampaign.get() != squadLeaderCampaign.get()) {
    showChangeCampaignMsg()
    return
  }

  let { addons, units } = mGMode == null ? requiredSquadAddons.get() : getRequiredAddonsNotUpdatable(mGMode)
  if (addons.len() + units.len() > 0) {
    let locs = localizeAddons(addons)
    log($"[ADDONS] Ask update addons on try to set ready in the squad (mode = {mGMode?.name ?? "randomBattles"}):", addons)
    if (units.len() > 0) {
      let unitLocs = localizeUnitsResources(units, allUnitsRanks.get(), curCampaign.get())
      locs.extend(unitLocs)
      log($"[ADDONS] Ask download units on try to set ready in the squad ({units.len()}):", unitLocs)
    }

    openFMsgBox({
      viewType = "downloadMsg"
      addons = addons
      units = units
      bqAction = "msg_download_addons_for_set_ready"
      bqData = { source = "random_battles", unit = ";".join(allBattleUnits.get()) }

      text = loc("msg/needAddonToPlayBySquad",
        { count = locs.len(),
          addon = ", ".join(locs.map(@(t) colorize("@mark", t)))
        })
      buttons = [
        { id = "cancel", isCancel = true }
        { text = loc("msgbox/btn_download")
          eventId = "downloadAddonsForSquadReady"
          context = { addons, units, mGMode }
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
  downloadAddonsForSquadReady = @(p)
    openDownloadAddonsWnd(p.addons, p.units, "squadSetReady", {}, "squadSetReady", { mGMode = p?.mGMode })
})

eventbus_subscribe("squadSetReady", @(p) setReady(true, p?.mGMode))

requiredSquadAddons.subscribe(function(v) {
  if (v.addons.len() + v.units.len() > 0)
    setReady(false)
})

return setReady