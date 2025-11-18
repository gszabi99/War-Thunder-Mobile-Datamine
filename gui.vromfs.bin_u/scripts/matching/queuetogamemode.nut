from "%scripts/dagui_library.nut" import *
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { setTimeout, resetTimeout } = require("dagor.workcycle")
let { chooseRandom } = require("%sqstd/rand.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isMatchingOnline, showMatchingConnectProgress } = require("matchingOnline.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { allGameModes } = require("%appGlobals/gameModes/gameModes.nut")
let { campMyUnits, curUnit } = require("%appGlobals/pServer/profile.nut")
let { sendUiBqEvent, sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isInQueue, joinQueue } = require("queuesClient.nut")
let { localizeAddons } = require("%appGlobals/updater/addons.nut")
let { localizeUnitsResources, getCampaignOrig } = require("%appGlobals/updater/campaignAddons.nut")
let { addonsVersions, hasAddons, addonsExistInGameFolder, unitSizes
} = require("%appGlobals/updater/addonsState.nut")
let { curCampaign, setCampaign, campaignsList } = require("%appGlobals/pServer/campaign.nut")
let { getModeAddonsInfo, getModeAddonsDbgString, allBattleUnits, missingUnitResourcesByRank,
  allUnitsRanks, maxReleasedUnitRanks
} = require("%appGlobals/updater/gameModeAddons.nut")
let { onlineBattleBlockCurrencyId } = require("%appGlobals/currenciesState.nut")
let { isInSquad, isSquadLeader, squadMembers, squadId, isInvitedToSquad, squadOnline,
  MAX_SQUAD_MRANK_DIFF, squadLeaderCampaign, getMemberMaxMRank
} = require("%appGlobals/squadState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")
let { isOnline, isDisconnected, canBattleWithoutAddons } = require("%appGlobals/clientState/clientState.nut")
let { checkReconnect } = require("%scripts/matchingRooms/sessionReconnect.nut")
let { activeBattleMods } = require("%appGlobals/pServer/battleMods.nut")
let { getBattleModPresentation } = require("%appGlobals/config/battleModPresentation.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")


let startBattleDelayed = persist("startBattleDelayed", @() { modeId = null })
let maxSquadRankDiff = mkWatched(persist, "minSquadRankDiff", MAX_SQUAD_MRANK_DIFF)

isInSquad.subscribe(@(_) maxSquadRankDiff.set(MAX_SQUAD_MRANK_DIFF))

function msgBoxWithFalse(params) {
  openFMsgBox(params)
  return false
}

function showReqBattleModeMsg(msgLocId, reqBMods, msgParams = {}) {
  local modeName = reqBMods[0]
  foreach(bm in reqBMods) {
    let { locId = null} = getBattleModPresentation(bm)
    if (locId != null) {
      modeName = loc(locId)
    }
  }
  openFMsgBox({ text = loc(msgLocId, msgParams.__merge({ mode = modeName })) })
}

function isSquadReadyWithMsgbox(mode, allReqAddons, reqBMods) {
  let { minSquadSize = 1, only_override_units = false, gameModeId } = mode
  if (!isInSquad.get()) {
    if (minSquadSize > 1)
      return msgBoxWithFalse({ text = loc("squad/minimumSquadSizeWarning", { count = minSquadSize }) })
    return true
  }

  if (!isSquadLeader.get())
    return msgBoxWithFalse({ text = loc("squad/only_leader_can_queue") })

  if (squadMembers.get().len() < minSquadSize)
    return msgBoxWithFalse({ text = loc("squad/minimumSquadSizeWarning", { count = minSquadSize }) })

  let { maxSquadSize = minSquadSize } = mode
  if (squadMembers.get().len() > maxSquadSize) {
    if (maxSquadSize == 1)
      openFMsgBox({ text = loc("squad/modeNotAvailableForSquad") })
    else
      openFMsgBox({ text = loc("squad/minimumSquadSizeWarning", { count = minSquadSize }) })
    return false
  }

  if (isInvitedToSquad.get().len() > 0)
    return msgBoxWithFalse({ text = loc("squad/has_non_accept_invites") })

  if (squadMembers.get().findindex(@(_, uid) !squadOnline.get()?[uid]))
    return msgBoxWithFalse({ text = loc("squad/has_offline_members") })

  if (reqBMods.len() > 0) {
    let noModsMembers = squadMembers.get().filter(@(m) !!m?.battleMods.findvalue(@(bm) reqBMods.contains(bm)))
    if (noModsMembers.len() != squadMembers.get().len()) {
      showReqBattleModeMsg("squad/not_all_has_battle_mod", reqBMods)
      return false
    }
  }

  if (only_override_units || mode?.mission_decl.customRules.customBots) {
    local hasAllResources = true
    foreach(uid, member in squadMembers.get())
      if (uid != squadId.get() && !member?.readyOvrGameModes[gameModeId.tostring()]) {
        hasAllResources = false
        break
      }
    if (!hasAllResources)
      return msgBoxWithFalse({
        text = loc("squad/not_all_has_packs")
        buttons = [
          { id = "cancel", isCancel = true }
          { text = loc("squad/requestAddonsDownload")
            styleId = "PRIMARY"
            eventId = "initiateSquadAddonsDownload"
            context = { modeId = gameModeId }
          }
        ]
      })
  }

  if (!only_override_units) {
    let campaign = squadLeaderCampaign.get()
    local rankMin = curUnit.get()?.mRank ?? 0
    local rankMax = rankMin
    foreach(m in squadMembers.get()) {
      let mRank = getMemberMaxMRank(m, campaign, serverConfigs.get())
      if (mRank == null)
        continue
      rankMin = min(rankMin, mRank)
      rankMax = max(rankMax, mRank)
    }
    if (rankMax - rankMin > maxSquadRankDiff.get())
      return msgBoxWithFalse({
        text = loc("msg/bigRankDiff/toBattle", {
          rankMin = colorize("@mark", getRomanNumeral(rankMin)),
          rankMax = colorize("@mark", getRomanNumeral(rankMax)),
        })
        buttons = [
          { id = "cancel", isCancel = true }
          { text = loc("squad/rankCheck")
            styleId = "PRIMARY"
            eventId = "initiateSquadMRankCheck"
          }
          { text = loc("mainmenu/toBattle/short")
            eventId = "incMaxSquadRankDiffAndQueue"
            context = { diff = rankMax - rankMin, modeId = gameModeId }
            styleId = "BATTLE"
            isDefault = true
          }
        ]
      })

    foreach(m in squadMembers.get())
      if ((m?.readyBattleRanks[getCampaignOrig(campaign)] ?? 0) < rankMax + 1)
        return msgBoxWithFalse({
          text = loc("squad/not_all_has_packs")
          buttons = [
            { id = "cancel", isCancel = true }
            { text = loc("squad/requestAddonsDownload")
              styleId = "PRIMARY"
              eventId = "initiateSquadAddonsDownload"
              context = { modeId = gameModeId }
            }
          ]
        })
  }

  local hasAllAddons = true
  foreach(uid, member in squadMembers.get())
    if (uid != squadId.get()
        && (member?.missingAddons ?? []).findvalue(@(a) a in allReqAddons)) {
      hasAllAddons = false
      break
    }
  if (!hasAllAddons)
    return msgBoxWithFalse({ text = loc("squad/not_all_has_packs") })

  if (squadMembers.get().findindex(@(m, uid) uid != squadId.get() && !m?.ready))
    return msgBoxWithFalse({ text = loc("squad/not_all_ready") })

  return true
}

function queueToGameModeImpl(mode) {
  if (isInQueue.get())
    return
  if (onlineBattleBlockCurrencyId.get() != null) {
    eventbus_send("showNegativeBalanceWarning", {})
    return
  }

  let { reqBattleMod = "", campaign = null, only_override_units = false } = mode
  let reqBMods = reqBattleMod.split(";").filter(@(v) v != "")
  if (reqBMods.len() > 0 && !reqBMods.findvalue(@(v) !!activeBattleMods.get()?[v])) {
    showReqBattleModeMsg("msg/needBattleMode", reqBMods)
    return
  }

  log("[ADDONS] getModeAddonsInfo at queueToGameMode for units: ", allBattleUnits.get())
  log("modeInfo = ", getModeAddonsDbgString(mode))
  let { addonsToDownload, updateDiff, allReqAddons, unitsToDownload } = getModeAddonsInfo({
    mode,
    unitNames = allBattleUnits.get(),
    serverConfigsV = serverConfigs.get(),
    hasAddonsV = hasAddons.get(),
    addonsExistInGameFolderV = addonsExistInGameFolder.get(),
    addonsVersionsV = addonsVersions.get(),
    missingUnitResourcesByRankV = missingUnitResourcesByRank.get(),
    maxReleasedUnitRanksV = maxReleasedUnitRanks.get(),
    unitSizesV = unitSizes.get(),
  })
  if (!isSquadReadyWithMsgbox(mode, allReqAddons, reqBMods))
    return

  if (addonsToDownload.len() + unitsToDownload.len() > 0 && !canBattleWithoutAddons.get()) {
    let isUpdate = updateDiff >= 0
    let locs = localizeAddons(addonsToDownload)
    if (unitsToDownload.len() > 0) {
      let unitLocs = localizeUnitsResources(unitsToDownload, allUnitsRanks.get(), campaign ?? curCampaign.get())
      locs.extend(unitLocs)
      log($"[ADDONS] Ask download units on try to join queue {unitsToDownload.len()}", unitLocs)
    }
    addonsToDownload.each(@(a) log($"[ADDONS] Ask update addon {a} on try to join queue (cur version = '{addonsVersions.get()?[a] ?? "-"}')"))

    openFMsgBox({
      viewType = "downloadMsg"
      addons = addonsToDownload
      units = unitsToDownload
      bqAction = isUpdate ? "msg_update_addons_for_queue" : "msg_download_addons_for_queue"
      bqData = { source = mode.name, unit = ";".join(allBattleUnits.get()) }

      text = loc(isUpdate ? "msg/needUpdateAddonToPlayGameMode" : "msg/needAddonToPlayGameMode",
        { count = locs.len(),
          addon = ", ".join(locs.map(@(t) colorize(0xFFFFB70B, t)))
        })
      buttons = [
        { id = "cancel", isCancel = true }
        { text = loc(isUpdate ? "ugm/btnUpdate" : "msgbox/btn_download")
          eventId = "downloadAddonsForQueue"
          context = { addons = addonsToDownload, units = unitsToDownload, modeId = mode.gameModeId, modeName = mode.name }
          styleId = "PRIMARY"
          isDefault = true
        }
      ]
    })
    return
  }

  if (addonsToDownload.len() + unitsToDownload.len() != 0)
    log("[ADDONS] Queue game mode while missing addons: ", addonsToDownload, unitsToDownload)

  if (campaign != null
      && !only_override_units
      && (campaign != curCampaign.get() && campaign != getCampaignPresentation(curCampaign.get()).campaign)) {
    let campToSet = campaignsList.get().findvalue(@(c) c == campaign || getCampaignPresentation(c).campaign == campaign)
      ?? campaign
    setCampaign(campToSet)
    resetTimeout(0.1, @() eventbus_send("queueToGameMode", { modeId = mode.gameModeId }))
    return
  }

  
  
  joinQueue({ mode = mode.name })
}

function queueModeOnRandomUnit(mode) {
  let mmRanges = mode.matchmaking?.mmRanges
  if (!mmRanges) {
    openFMsgBox({ text = "could not get current mode mRank ranges" })
    return
  }

  let unitsList = []
  foreach (unit in campMyUnits.get())
    foreach (range in mmRanges)
      if (unit.mRank >= range[0] && unit.mRank <= range[1]) {
        unitsList.append(unit)
        break
      }

  let unitName = chooseRandom(unitsList)?.name ?? ""
  let errString = setCurrentUnit(unitName)
  if (errString != "")
    logerr($"On choose unit {unitName}: {errString}")

  setTimeout(1.0, @() queueToGameModeImpl(mode)) 
}

function tryQueueToGameMode(modeId) {
  if (!isMatchingOnline.get()) {
    showMatchingConnectProgress()
    startBattleDelayed.modeId = modeId
    return
  }

  let mode = allGameModes.get()?[modeId]
  if (mode == null) {
    logerr($"Not found mode with id /*{modeId}*/ to start battle")
    return
  }

  if (mode?.needStartOnRandomUnit ?? false)
    queueModeOnRandomUnit(mode)
  else
    queueToGameModeImpl(mode)
}

function queueToGameMode(modeId) {
  if (isOnline.get() && isDisconnected.get()) {
    checkReconnect(@() tryQueueToGameMode(modeId))
    return
  }
  tryQueueToGameMode(modeId)
}

function queueToGameModeAfterAddons(modeId) {
  let mode = allGameModes.get()?[modeId]
  if (mode == null)
    return 
  let { addonsToDownload, unitsToDownload } = getModeAddonsInfo({
    mode,
    unitNames = allBattleUnits.get(),
    serverConfigsV = serverConfigs.get(),
    hasAddonsV = hasAddons.get(),
    addonsExistInGameFolderV = addonsExistInGameFolder.get(),
    addonsVersionsV = addonsVersions.get(),
    missingUnitResourcesByRankV = missingUnitResourcesByRank.get(),
    maxReleasedUnitRanksV = maxReleasedUnitRanks.get(),
    unitSizesV = unitSizes.get(),
  })
  if (addonsToDownload.len() + unitsToDownload.len() == 0)
    queueToGameMode(modeId)
  else {
    log("[ADDONS] failed to load addons at queueToGameMode (", allBattleUnits.get(), "): ", addonsToDownload, unitsToDownload)
    sendErrorLocIdBqEvent("msg/unableToUpadateAddons")
    openFMsgBox({ text = loc("msg/unableToUpadateAddons") })
  }
}

function requeueToDelayedMode() {
  let { modeId } = startBattleDelayed
  if (modeId == null)
    return
  startBattleDelayed.modeId = null
  queueToGameMode(modeId)
}

isMatchingOnline.subscribe(@(v) v ? requeueToDelayedMode() : null)
isLoggedIn.subscribe(@(v) v ? null : startBattleDelayed.$rawset("modeId", null))

eventbus_subscribe("queueToGameMode", @(msg) queueToGameMode(msg.modeId))
eventbus_subscribe("queueToGameModeAfterAddons", @(msg) queueToGameModeAfterAddons(msg.modeId))

function sendBqIfNeed(p) {
  let { bqEvent = null, bqData = {} } = p
  if (bqEvent != null)
    sendUiBqEvent(bqEvent, bqData)
}

subscribeFMsgBtns({
  function downloadAddonsForQueue(p) {
    sendBqIfNeed(p)
    eventbus_send("openDownloadAddonsWnd",
      { addons = p.addons, units = p?.units ?? [], successEventId = "queueToGameModeAfterAddons", context = { modeId = p.modeId },
        bqSource = "applyDownloadAddonsForQueue", bqParams = { paramStr1 = p.modeName }
      })
  }
  function queueToGameModeRetry(p) {
    sendBqIfNeed(p)
    queueToGameMode(p.modeId)
  }
  function incMaxSquadRankDiffAndQueue(p) {
    maxSquadRankDiff.set(p.diff)
    queueToGameMode(p.modeId)
  }
})

return queueToGameMode
