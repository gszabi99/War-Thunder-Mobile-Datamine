//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let { subscribe, send } = require("eventbus")
let { setTimeout } = require("dagor.workcycle")
let { get_addon_version } = require("contentUpdater")
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

let startBattleDelayed = persist("startBattleDelayed", @() { modeId = null })

let function queueToGameModeImpl(mode) {
  if (isInQueue.value)
    return

  let { addonsToDownload, updateDiff } = getModeAddonsInfo(mode, curUnit.value?.name)
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
          isPrimary = true
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

  let unitName = ::u.chooseRandom(unitsList)?.name ?? ""
  let errString = setCurrentUnit(unitName)
  if (errString != "")
    logerr($"On choose unit {unitName}: {errString}")

  setTimeout(1.0, @() queueToGameModeImpl(mode)) //FIXME: why timer here instead of cb or subscribe?
}

let function queueToGameMode(modeId) {
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

let function queueToGameModeAfterAddons(modeId) {
  let mode = allGameModes.value?[modeId]
  if (mode == null)
    return //mode missing while downloading, no need error here
  let { addonsToDownload } = getModeAddonsInfo(mode, curUnit.value?.name)
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
})

return queueToGameMode
