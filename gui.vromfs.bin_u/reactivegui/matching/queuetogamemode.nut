from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import setTimeout, resetTimeout
from "eventbus" import eventbus_subscribe, eventbus_send
from "%sqstd/math.nut" import getRomanNumeral
from "%sqstd/rand.nut" import chooseRandom
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/clientState/clientState.nut" import canBattleWithoutAddons
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/currenciesState.nut" import onlineBattleBlockCurrencyId
from "%appGlobals/gameModes/gameModes.nut" import allGameModes, gameModeQueueGroups, getGameModeQueueGroup
from "%appGlobals/loginState.nut" import isLoggedIn, isMatchingOnline
from "%appGlobals/openForeignMsgBox.nut" import subscribeFMsgBtns, openFMsgBox
from "%appGlobals/pServer/bqClient.nut" import sendUiBqEvent, sendErrorLocIdBqEvent
from "%appGlobals/pServer/campaign.nut" import curCampaign, setCampaign, campaignsList
from "%appGlobals/pServer/profile.nut" import campMyUnits, curUnit
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/squadState.nut" import isInSquad, isSquadLeader, squadMembers, squadId, isInvitedToSquad,
  squadOnline, MAX_SQUAD_MRANK_DIFF, squadLeaderCampaign, getMemberMaxMRank
from "%appGlobals/unitsState.nut" import setCurrentUnit
from "%appGlobals/updater/addons.nut" import localizeAddons
from "%appGlobals/updater/addonsState.nut" import hasAddons, unitSizes
from "%appGlobals/updater/campaignAddons.nut" import localizeUnitsResources
from "%appGlobals/updater/gameModeAddons.nut" import getModeAddonsInfo, getModeAddonsDbgString, allBattleUnits,
  missingUnitResourcesByRank, allUnitsRanks, maxReleasedUnitRanks
from "%rGui/matchingRooms/sessionReconnect.nut" import checkReconnect, needCheckReconnectOnGoToBattle
from "%rGui/matching/matchingApi.nut" import matchingRpcRegisterHandler
from "matchingOnline.nut" import showMatchingConnectProgress
from "queuesClient.nut" import isInQueue, joinQueue


let startBattleDelayed = hardPersistWatched("startBattleDelayed", { modeId = null })
let maxSquadRankDiff = mkWatched(persist, "minSquadRankDiff", MAX_SQUAD_MRANK_DIFF)

isInSquad.subscribe(@(_) maxSquadRankDiff.set(MAX_SQUAD_MRANK_DIFF))

function msgBoxWithFalse(params) {
  openFMsgBox(params)
  return false
}

function isSquadReadyWithMsgbox(mode, allReqAddons) {
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
      if ((m?.readyBattleRanks[campaign] ?? 0) < rankMax + 1)
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

  let { campaign = null, only_override_units = false } = mode

  log("[ADDONS] getModeAddonsInfo at queueToGameMode for units: ", allBattleUnits.get())
  log("modeInfo = ", getModeAddonsDbgString(mode))
  let modeList = getGameModeQueueGroup(mode, gameModeQueueGroups.get())

  let { addonsToDownload, allReqAddons, unitsToDownload } = getModeAddonsInfo({
    modeList,
    unitNames = allBattleUnits.get(),
    serverConfigsV = serverConfigs.get(),
    hasAddonsV = hasAddons.get(),
    missingUnitResourcesByRankV = missingUnitResourcesByRank.get(),
    maxReleasedUnitRanksV = maxReleasedUnitRanks.get(),
    unitSizesV = unitSizes.get(),
  })
  if (!isSquadReadyWithMsgbox(mode, allReqAddons))
    return

  if (addonsToDownload.len() + unitsToDownload.len() > 0 && !canBattleWithoutAddons.get()) {
    let locs = localizeAddons(addonsToDownload)
    if (addonsToDownload.len() > 0)
      log($"[ADDONS] Ask download addons on try to join queue {addonsToDownload.len()}", addonsToDownload)
    if (unitsToDownload.len() > 0) {
      let unitLocs = localizeUnitsResources(unitsToDownload, allUnitsRanks.get(), campaign ?? curCampaign.get())
      locs.extend(unitLocs)
      log($"[ADDONS] Ask download units on try to join queue {unitsToDownload.len()}", unitLocs)
    }

    openFMsgBox({
      viewType = "downloadMsg"
      addons = addonsToDownload
      units = unitsToDownload
      bqAction = "msg_download_addons_for_queue"
      bqData = { source = mode.name, unit = ";".join(allBattleUnits.get()) }

      text = loc("msg/needAddonToPlayGameMode",
        { count = locs.len(),
          addon = ", ".join(locs.map(@(t) colorize(0xFFFFB70B, t)))
        })
      buttons = [
        { id = "cancel", isCancel = true }
        { text = loc("msgbox/btn_download")
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

  
  
  joinQueue(modeList.len() <= 1 ? { mode = mode.name } : { game_modes_list = modeList.map(@(m) m.gameModeId) })
}

function queueModeOnRandomUnit(mode) {
  let mmRanges = mode?.matchmaking.mmRanges
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
    startBattleDelayed.mutate(@(v) v.modeId = modeId)
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
  if (isMatchingOnline.get() && needCheckReconnectOnGoToBattle.get()) {
    checkReconnect({ id = "queueOnFailReconnect", modeId })
    return
  }
  tryQueueToGameMode(modeId)
}

matchingRpcRegisterHandler("queueOnFailReconnect", @(_, context) tryQueueToGameMode(context.modeId))

function queueToGameModeAfterAddons(modeId) {
  let mode = allGameModes.get()?[modeId]
  if (mode == null)
    return 
  let { addonsToDownload, unitsToDownload } = getModeAddonsInfo({
    modeList = getGameModeQueueGroup(mode, gameModeQueueGroups.get()),
    unitNames = allBattleUnits.get(),
    serverConfigsV = serverConfigs.get(),
    hasAddonsV = hasAddons.get(),
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
  let { modeId } = startBattleDelayed.get()
  if (modeId == null)
    return
  startBattleDelayed.mutate(@(v) v.modeId = null)
  queueToGameMode(modeId)
}

isMatchingOnline.subscribe(@(v) v ? requeueToDelayedMode() : null)
isLoggedIn.subscribe(@(v) v ? null : startBattleDelayed.mutate(@(s) s.$rawset("modeId", null)))

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
