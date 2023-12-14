
from "%scripts/dagui_library.nut" import *
let { subscribe, send } = require("eventbus")
let { setTimeout } = require("dagor.workcycle")
let { get_addon_version } = require("contentUpdater")
let { chooseRandom } = require("%sqstd/rand.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { isMatchingOnline, showMatchingConnectProgress } = require("matchingOnline.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { allGameModes } = require("%appGlobals/gameModes/gameModes.nut")
let { myUnits, curUnit } = require("%appGlobals/pServer/profile.nut")
let { isInQueue, joinQueue } = require("queuesClient.nut")
let { localizeAddons, getAddonsSizeStr } = require("%appGlobals/updater/addons.nut")
let { curCampaign, setCampaign } = require("%appGlobals/pServer/campaign.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { getModeAddonsInfo } = require("gameModeAddons.nut")
let { balanceGold } = require("%appGlobals/currenciesState.nut")
let { isInSquad, isSquadLeader, squadMembers, squadId, isInvitedToSquad, squadOnline,
  MAX_SQUAD_MRANK_DIFF, squadLeaderCampaign
} = require("%appGlobals/squadState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")
let { isOnline, isDisconnected } = require("%appGlobals/clientState/clientState.nut")
let { checkReconnect } = require("%scripts/matchingRooms/sessionReconnect.nut")

let startBattleDelayed = persist("startBattleDelayed", @() { modeId = null })
let maxSquadRankDiff = mkWatched(persist, "minSquadRankDiff", MAX_SQUAD_MRANK_DIFF)

isInSquad.subscribe(@(_) maxSquadRankDiff(MAX_SQUAD_MRANK_DIFF))

let function msgBoxWithFalse(params) {
  openFMsgBox(params)
  return false
}

let function isSquadReadyWithMsgbox(mode, allReqAddons) {
  let { minSquadSize = 1 } = mode
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

  local rankMin = curUnit.value?.mRank ?? 0
  local rankMax = rankMin
  foreach(m in squadMembers.value) {
    let mRank = serverConfigs.value?.allUnits[m?.units[squadLeaderCampaign.value]].mRank
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

let function getAllBattleUnits() {
  let res = {}
  if (curUnit.value != null)
    res[curUnit.value.name] <- true
  foreach(m in squadMembers.value) {
    let name = m?.units[squadLeaderCampaign.value]
    if (name != null)
      res[name] <- true
  }
  return res.keys()
}

let function queueToGameModeImpl(mode) {
  if (isInQueue.value)
    return
  if (balanceGold.value < 0) {
    send("showNegativeBalanceWarning", {})
    return
  }

  let allBattlenits = getAllBattleUnits()
  log("[ADDONS] getModeAddonsInfo at queueToGameMode for units: ", getAllBattleUnits())
  let { addonsToDownload, updateDiff, allReqAddons } = getModeAddonsInfo(mode, allBattlenits)
  if (!isSquadReadyWithMsgbox(mode, allReqAddons))
    return

  if (addonsToDownload.len() > 0) {
    let isUpdate = updateDiff >= 0
    let locs = localizeAddons(addonsToDownload)
    addonsToDownload.each(@(a) log($"[ADDONS] Ask update addon {a} on try to join queue (cur version = '{get_addon_version(a)}')"))
    openFMsgBox({
      text = loc(isUpdate ? "msg/needUpdateAddonToPlayGameMode" : "msg/needAddonToPlayGameMode",
        { count = locs.len(),
          addon = ", ".join(locs.map(@(t) colorize(0xFFFFB70B, t)))
          size = getAddonsSizeStr(addonsToDownload)
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

  let { campaign } = mode
  if (campaign != null && campaign != curCampaign.value)
    setCampaign(campaign)

  //can check units here, but no unit rquirements in the current event yet.
  //so better to do it only when become need.
  joinQueue({ mode = mode.name })
}

let function queueModeOnRandomUnit(mode) {
  let mmRanges = mode.matchmaking?.mmRanges
  if (!mmRanges) {
    openFMsgBox({ text = "could not get current mode mRank ranges" })
    return
  }

  let unitsList = []
  foreach (unit in myUnits.value)
    foreach (range in mmRanges)
      if (unit.mRank >= range[0] && unit.mRank <= range[1]) {
        unitsList.append(unit)
        break
      }

  let unitName = chooseRandom(unitsList)?.name ?? ""
  let errString = setCurrentUnit(unitName)
  if (errString != "")
    logerr($"On choose unit {unitName}: {errString}")

  setTimeout(1.0, @() queueToGameModeImpl(mode)) //FIXME: why timer here instead of cb or subscribe?
}

let function tryQueueToGameMode(modeId) {
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

let function queueToGameMode(modeId) {
  if (isOnline.get() && isDisconnected.get()) {
    checkReconnect(@() tryQueueToGameMode(modeId))
    return
  }
  tryQueueToGameMode(modeId)
}

let function queueToGameModeAfterAddons(modeId) {
  let mode = allGameModes.value?[modeId]
  if (mode == null)
    return //mode missing while downloading, no need error here
  let { addonsToDownload } = getModeAddonsInfo(mode, getAllBattleUnits())
  if (addonsToDownload.len() == 0)
    queueToGameMode(modeId)
  else
    openFMsgBox({ text = loc("msg/unableToUpadateAddons") })
}

let function requeueToDelayedMode() {
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

subscribe("queueToGameMode", @(msg) queueToGameMode(msg.modeId))
subscribe("queueToGameModeAfterAddons", @(msg) queueToGameModeAfterAddons(msg.modeId))

let function sendBqIfNeed(p) {
  let { bqEvent = null, bqData = {} } = p
  if (bqEvent != null)
    sendUiBqEvent(bqEvent, bqData)
}

subscribeFMsgBtns({
  function downloadAddonsForQueue(p) {
    sendBqIfNeed(p)
    send("openDownloadAddonsWnd",
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
