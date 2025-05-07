from "%scripts/dagui_library.nut" import *
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { setTimeout, resetTimeout } = require("dagor.workcycle")
let { chooseRandom } = require("%sqstd/rand.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { isMatchingOnline, showMatchingConnectProgress } = require("matchingOnline.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { allGameModes } = require("%appGlobals/gameModes/gameModes.nut")
let { campMyUnits, curUnit } = require("%appGlobals/pServer/profile.nut")
let { isInQueue, joinQueue } = require("queuesClient.nut")
let { localizeAddons, getAddonsSizeStr } = require("%appGlobals/updater/addons.nut")
let { addonsSizes, addonsVersions } = require("%appGlobals/updater/addonsState.nut")
let { curCampaign, setCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curCampaignSlotUnits } = require("%appGlobals/pServer/slots.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { getModeAddonsInfo, getModeAddonsDbgString } = require("gameModeAddons.nut")
let { balanceGold } = require("%appGlobals/currenciesState.nut")
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

isInSquad.subscribe(@(_) maxSquadRankDiff(MAX_SQUAD_MRANK_DIFF))

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
  let { minSquadSize = 1, only_override_units = false } = mode
  if (!isInSquad.value) {
    if (minSquadSize > 1)
      return msgBoxWithFalse({ text = loc("squad/minimumSquadSizeWarning", { count = minSquadSize }) })
    return true
  }

  if (!isSquadLeader.value)
    return msgBoxWithFalse({ text = loc("squad/only_leader_can_queue") })

  if (squadMembers.value.len() < minSquadSize)
    return msgBoxWithFalse({ text = loc("squad/minimumSquadSizeWarning", { count = minSquadSize }) })

  let { maxSquadSize = minSquadSize } = mode
  if (squadMembers.value.len() > maxSquadSize) {
    if (maxSquadSize == 1)
      openFMsgBox({ text = loc("squad/modeNotAvailableForSquad") })
    else
      openFMsgBox({ text = loc("squad/minimumSquadSizeWarning", { count = minSquadSize }) })
    return false
  }

  if (isInvitedToSquad.value.len() > 0)
    return msgBoxWithFalse({ text = loc("squad/has_non_accept_invites") })

  if (squadMembers.value.findindex(@(_, uid) !squadOnline.value?[uid]))
    return msgBoxWithFalse({ text = loc("squad/has_offline_members") })

  if (reqBMods.len() > 0) {
    let noModsMembers = squadMembers.get().filter(@(m) !!m?.battleMods.findvalue(@(bm) reqBMods.contains(bm)))
    if (noModsMembers.len() != squadMembers.get().len()) {
      showReqBattleModeMsg("squad/not_all_has_battle_mod", reqBMods)
      return false
    }
  }

  if (!only_override_units) {
    local rankMin = curUnit.value?.mRank ?? 0
    local rankMax = rankMin
    foreach(m in squadMembers.value) {
      let mRank = getMemberMaxMRank(m, squadLeaderCampaign.get(), serverConfigs.get())
      if (mRank == null)
        continue
      rankMin = min(rankMin, mRank)
      rankMax = max(rankMax, mRank)
    }
    if (rankMax - rankMin > maxSquadRankDiff.value)
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
            context = { diff = rankMax - rankMin, modeId = mode.gameModeId }
            styleId = "BATTLE"
            isDefault = true
          }
        ]
      })
  }

  local hasAllAddons = true
  foreach(uid, member in squadMembers.value)
    if (uid != squadId.value
        && (member?.missingAddons ?? []).findvalue(@(a) a in allReqAddons)) {
      hasAllAddons = false
      break
    }
  if (!hasAllAddons)
    return msgBoxWithFalse({ text = loc("squad/not_all_has_packs") })

  if (squadMembers.value.findindex(@(m, uid) uid != squadId.value && !m?.ready))
    return msgBoxWithFalse({ text = loc("squad/not_all_ready") })

  return true
}

function getAllBattleUnits() {
  let res = {}
  if (curCampaignSlotUnits.get() != null)
    curCampaignSlotUnits.get().each(@(name) res[name] <- true)
  else if (curUnit.value != null)
    res[curUnit.value.name] <- true
  foreach(m in squadMembers.value) {
    let list = m?.units[squadLeaderCampaign.get()]
    if (type(list) == "array")
      foreach(name in list)
        res[name] <- true
  }
  return res.keys()
}

function queueToGameModeImpl(mode) {
  if (isInQueue.value)
    return
  if (balanceGold.value < 0) {
    eventbus_send("showNegativeBalanceWarning", {})
    return
  }

  let { reqBattleMod = "" } = mode
  let reqBMods = reqBattleMod.split(";").filter(@(v) v != "")
  if (reqBMods.len() > 0 && !reqBMods.findvalue(@(v) !!activeBattleMods.get()?[v])) {
    showReqBattleModeMsg("msg/needBattleMode", reqBMods)
    return
  }

  let allBattlenits = getAllBattleUnits()
  log("[ADDONS] getModeAddonsInfo at queueToGameMode for units: ", getAllBattleUnits())
  log("modeInfo = ", getModeAddonsDbgString(mode))
  let { addonsToDownload, updateDiff, allReqAddons } = getModeAddonsInfo(mode, allBattlenits)
  if (!isSquadReadyWithMsgbox(mode, allReqAddons, reqBMods))
    return

  if (addonsToDownload.len() > 0 && !canBattleWithoutAddons.get()) {
    let isUpdate = updateDiff >= 0
    let locs = localizeAddons(addonsToDownload)
    addonsToDownload.each(@(a) log($"[ADDONS] Ask update addon {a} on try to join queue (cur version = '{addonsVersions.get()?[a] ?? "-"}')"))
    openFMsgBox({
      text = loc(isUpdate ? "msg/needUpdateAddonToPlayGameMode" : "msg/needAddonToPlayGameMode",
        { count = locs.len(),
          addon = ", ".join(locs.map(@(t) colorize(0xFFFFB70B, t)))
          size = getAddonsSizeStr(addonsToDownload, addonsSizes.get())
        })
      buttons = [
        { id = "cancel", isCancel = true }
        { text = loc(isUpdate ? "ugm/btnUpdate" : "msgbox/btn_download")
          eventId = "downloadAddonsForQueue"
          context = { addons = addonsToDownload, modeId = mode.gameModeId }
          styleId = "PRIMARY"
          isDefault = true
        }
      ]
    })
    return
  }

  if (addonsToDownload.len())
    log("[ADDONS] Queue game mode while missing addons: ", addonsToDownload)

  let { campaign = null, only_override_units = false } = mode
  if (campaign != null
      && !only_override_units
      && (campaign != curCampaign.get() && campaign != getCampaignPresentation(curCampaign.get()).campaign)) {
    setCampaign(campaign)
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
  if (!isMatchingOnline.value) {
    showMatchingConnectProgress()
    startBattleDelayed.modeId = modeId
    return
  }

  let mode = allGameModes.value?[modeId]
  if (mode == null) {
    logerr($"Not found mode with id {modeId} to start battle")
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
  let mode = allGameModes.value?[modeId]
  if (mode == null)
    return 
  let { addonsToDownload } = getModeAddonsInfo(mode, getAllBattleUnits())
  if (addonsToDownload.len() == 0)
    queueToGameMode(modeId)
  else
    openFMsgBox({ text = loc("msg/unableToUpadateAddons") })
}

function requeueToDelayedMode() {
  let { modeId } = startBattleDelayed
  if (modeId == null)
    return
  startBattleDelayed.modeId = null
  queueToGameMode(modeId)
}

isMatchingOnline.subscribe(function(v) {
  if (v)
    requeueToDelayedMode()
})

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
      { addons = p.addons, successEventId = "queueToGameModeAfterAddons", context = { modeId = p.modeId } })
  }
  function queueToGameModeRetry(p) {
    sendBqIfNeed(p)
    queueToGameMode(p.modeId)
  }
  function incMaxSquadRankDiffAndQueue(p) {
    maxSquadRankDiff(p.diff)
    queueToGameMode(p.modeId)
  }
})

return queueToGameMode
