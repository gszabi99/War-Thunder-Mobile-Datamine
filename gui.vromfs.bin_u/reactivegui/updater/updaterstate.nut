from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { download_addons_in_background, stop_updater, is_updater_running, get_addon_version,
  get_incomplete_addons, is_addon_exists_in_game_folder, UPDATER_RESULT_SUCCESS, UPDATER_ERROR,
  UPDATER_EVENT_STAGE, UPDATER_EVENT_DOWNLOAD_SIZE, UPDATER_EVENT_PROGRESS, UPDATER_EVENT_ERROR,
  UPDATER_EVENT_FINISH, UPDATER_DOWNLOADING, UPDATER_EVENT_INCOMPATIBLE_VERSION
} = require("contentUpdater")
let { get_local_custom_settings_blk, get_settings_blk } = require("blkGetters")
let logA = log_with_prefix("[ADDONS] ")
let { isEqual } = require("%sqstd/underscore.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInLoadingScreen, isInMpBattle } = require("%appGlobals/clientState/clientState.nut")
let { localizeAddonsLimited, initialAddons, latestDownloadAddonsByCamp, latestDownloadAddons,
  commonUhqAddons, soloNewbieByCampaign
} = require("%appGlobals/updater/addons.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")
let { getAddonCampaign, getCampaignPkgsForOnlineBattle, getCampaignPkgsForNewbieBattle
} = require("%appGlobals/updater/campaignAddons.nut")
let { isAnyCampaignSelected, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { myUnits, battleUnitsMaxMRank } = require("%appGlobals/pServer/profile.nut")
let { isConnectionLimited, hasConnection } = require("%appGlobals/clientState/connectionStatus.nut")
let { isRandomBattleNewbie, isRandomBattleNewbieSingle } = require("%rGui/gameModes/gameModeState.nut")
let { squadAddons } = require("%rGui/squad/squadAddons.nut")
let { needUhqTextures } = require("%rGui/options/options/graphicOptions.nut")

let DOWNLOAD_ADDONS_EVENT_ID = "downloadAddonsEvent"
let ALLOW_LIMITED_DOWNLOAD_SAVE_ID = "allowLimitedConnectionDownload"

let addonsToDownload = hardPersistWatched("updater.addonsToDownload",
  get_incomplete_addons().reduce(function(res, v) {
    if (!v.endswith("_uhq")) //no need to finalize uhq addons by default.
      res[v] <- true
    return res
  }, {}))
let isDownloadPaused = hardPersistWatched("updater.isDownloadPaused", false)
let allowLimitedDownload = Watched(get_local_custom_settings_blk()?[ALLOW_LIMITED_DOWNLOAD_SAVE_ID] ?? false)
let downloadInProgress = hardPersistWatched("updater.downloadInProgress", {})
let currentStage = hardPersistWatched("updater.currentStage", null)
let totalSizeBytes = hardPersistWatched("updater.totalSizeBytes", 0)
let toDownloadSizeBytes = hardPersistWatched("updater.toDownloadSizeBytes", 0)
let downloadState = hardPersistWatched("updater.downloadState", null)
let updaterError = hardPersistWatched("updater.updaterError", null)
let isIncompatibleVersion = Watched(false)

let firstPriorityAddons = mkWatched(persist, "firstPriorityAddons", {})
let downloadWndParams = mkWatched(persist, "downloadWndParams", null)
let progressPercent = Computed(function() {
  let { percent = null } = downloadState.value
  if (totalSizeBytes.value == 0 || percent == null)
    return percent
  return clamp((100.0 + toDownloadSizeBytes.value * (percent - 100.0) / totalSizeBytes.value + 0.5).tointeger(), 0, 100)
})

let isStageDownloading = Computed(@() currentStage.value == UPDATER_DOWNLOADING)

function mkAddonsToDownload(list, hasAddonsV, prev) {
  let res = {}
  foreach(a in list)
    if (!(hasAddonsV?[a] ?? true))
      res[a] <- true
  return isEqual(res, prev) ? prev : res
}

let initialAddonsToDownload = Computed(@(prev) mkAddonsToDownload(initialAddons, hasAddons.value, prev))
let latestAddonsToDownload = Computed(@(prev) mkAddonsToDownload(
  (clone latestDownloadAddons).extend(latestDownloadAddonsByCamp?[curCampaign.value] ?? []),
  hasAddons.value, prev))

let uhqAddonsToDownload = Computed(function(prev) {
  if (!needUhqTextures.value || (get_settings_blk()?.graphics.uhqForceDisabled ?? true))
    return isEqual(prev, {}) ? prev : {}
  let res = clone commonUhqAddons
  foreach(a, has in hasAddons.value)
    if (has) {
      let uhq = $"{a}_uhq"
      if (uhq in hasAddons.value)
        res.append(uhq)
    }
  return mkAddonsToDownload(res, hasAddons.value, prev)
})

let prevIfEqual = @(prev, cur) isEqual(cur, prev) ? prev : cur

let wantStartDownloadAddons = Computed(function(prev) {
  if (!isLoggedIn.value
      || isIncompatibleVersion.value
      || (addonsToDownload.value.len() + uhqAddonsToDownload.value.len()) == 0)
    return prevIfEqual(prev, {})

  let addons = firstPriorityAddons.value.__merge(initialAddonsToDownload.value, squadAddons.value) //first priority on addons requested by download addons window
  local res = addonsToDownload.value.filter(@(_, a) a in addons)
  if (res.len() != 0)
    return prevIfEqual(prev, res)

  if (!isAnyCampaignSelected.value)
    return prevIfEqual(prev, {})

  let campaign = curCampaign.get()
  if (campaign in soloNewbieByCampaign) {
    foreach (a in soloNewbieByCampaign[campaign])
      if (a in addonsToDownload.get())
        res[a] <- true
    if (res.len() != 0)
      return prevIfEqual(prev, res)
  }

  let curUnitAddons = isRandomBattleNewbie.value
    ? getCampaignPkgsForNewbieBattle(campaign, battleUnitsMaxMRank.get(), isRandomBattleNewbieSingle.value)
    : getCampaignPkgsForOnlineBattle(campaign, battleUnitsMaxMRank.get())
  res = addonsToDownload.value.filter(@(_, a) curUnitAddons.contains(a))
  if (res.len() != 0)
    return prevIfEqual(prev, res)

  res = addonsToDownload.value.filter(@(_, a) (getAddonCampaign(a) ?? campaign) == campaign)
  if (res.len() != 0)
    return prevIfEqual(prev, res)

  res = addonsToDownload.value.filter(@(_, a) a in latestAddonsToDownload.value)
  if (res.len() != 0)
    return prevIfEqual(prev, res)

  if (addonsToDownload.value.len() != 0)
    return prevIfEqual(prev, addonsToDownload.value)

  return prevIfEqual(prev, uhqAddonsToDownload.value)
})

let needStartDownloadAddons = keepref(Computed(@()
  isDownloadPaused.value
      || isInLoadingScreen.value
      || isInMpBattle.value
      || (isConnectionLimited.value && !allowLimitedDownload.value)
      || !hasConnection.value
    ? {}
    : wantStartDownloadAddons.value))

function cleanAddonsToDownload() {
  if (needStartDownloadAddons.value.len() == 0)
    return
  let res = addonsToDownload.get().filter(@(_, a) !hasAddons.get()?[a])
  foreach(a, _ in needStartDownloadAddons.value)
    res?.$rawdelete(a)
  if (res.len() != addonsToDownload.value.len())
    addonsToDownload(res)
}

let closeDownloadAddonsWnd = @() downloadWndParams(null)
curCampaign.subscribe(@(_) downloadWndParams.value == null ? firstPriorityAddons({}) : null)

function updateStartDownload() {
  let needDownload = needStartDownloadAddons.value.len() != 0
  if (needDownload == is_updater_running()
      && (!needDownload || isEqual(needStartDownloadAddons.value, downloadInProgress.value)))
    return

  if (!needDownload) {
    logA("stop download")
    stop_updater()
    downloadInProgress({})
    return
  }

  if (is_updater_running()) { //will restart by event from updater
    logA("stop download to change addons list")
    stop_updater()
    downloadInProgress({})
    return
  }

  let addons = needStartDownloadAddons.value.keys()
  let isStarted = download_addons_in_background(DOWNLOAD_ADDONS_EVENT_ID, addons)
  logA(isStarted ? "start download " : "ignore download ",
    ", ".join(addons.map(@(a) $"{a}: {is_addon_exists_in_game_folder(a) ? "exists in game folder" : get_addon_version(a)}")))

  if (!isStarted) {
    cleanAddonsToDownload() //we will not download them anyway
    downloadInProgress({})
  } else
    downloadInProgress(needStartDownloadAddons.value)
}
updateStartDownload()
needStartDownloadAddons.subscribe(@(_) deferOnce(updateStartDownload))

addonsToDownload.subscribe(function(v) {
  if (v.len() != 0)
    return
  isDownloadPaused(false)
  currentStage(null)
  totalSizeBytes(0)
  toDownloadSizeBytes(0)
  downloadState(null)
  updaterError(null)
})

wantStartDownloadAddons.subscribe(function(_) {
  totalSizeBytes(0)
  toDownloadSizeBytes(0)
  downloadState(null)
})

eventbus_subscribe(DOWNLOAD_ADDONS_EVENT_ID, function(evt) {
  let { eventType } = evt
  if (eventType == UPDATER_EVENT_STAGE)
    currentStage(evt?.stage)
  else if (eventType == UPDATER_EVENT_DOWNLOAD_SIZE) {
    toDownloadSizeBytes(evt?.toDownload ?? 0)
    totalSizeBytes(evt?.total ?? 0)
  } else if (eventType == UPDATER_EVENT_PROGRESS)
    downloadState(evt)
  else if (eventType == UPDATER_EVENT_INCOMPATIBLE_VERSION) {
    isIncompatibleVersion(true)
    eventbus_send((evt?.needExeUpdate ?? true) ? "showIncompatibleVersionMsg" : "showRestartForUpdateMsg", null)
  }
  else if (eventType == UPDATER_EVENT_ERROR) {
    let errText = evt?.error ?? UPDATER_ERROR
    let { isStopped = false } = evt
    logA($"download error: {errText}, (isStopped = {isStopped})")
    if (!isStopped)
      updaterError(errText)
  }
  else if (eventType == UPDATER_EVENT_FINISH) {
    let isSuccess = evt?.result == UPDATER_RESULT_SUCCESS
    logA($"download finish. isSuccess = {isSuccess}, isStopped = {evt?.isStopped}")
    downloadInProgress({})
    eventbus_send("downloadAddonsFinished", {})
    if (!isSuccess) {
      updateStartDownload()
      return
    }

    let { successEventId = null, context = {} } = downloadWndParams.value
    cleanAddonsToDownload()
    closeDownloadAddonsWnd()
    if (successEventId != null)
      eventbus_send(successEventId, context)
    downloadState(null)
  }
})

function getAddonPriority(addon) {
  let campaign = getAddonCampaign(addon)
  return campaign == curCampaign.value ? 2
    : campaign == null ? 1
    : 0
}

let downloadAddonsStr = Computed(function() {
  if (wantStartDownloadAddons.value.len() == 0)
    return ""
  let list = wantStartDownloadAddons.value.keys()
  list.sort(@(a, b) getAddonPriority(b) <=> getAddonPriority(a)
    || b <=> a)

  return localizeAddonsLimited(list, 3)
})

let maxCurCampaignMRank = Computed(function() {
  local res = 0
  foreach(unit in myUnits.value)
    res = max(res, unit.mRank)
  return res
})

let addonsToAutoDownload = keepref(Computed(function() {
  if (!isAnyCampaignSelected.value)
    return initialAddonsToDownload.value?.keys()
  let list = initialAddonsToDownload.value.__merge(latestAddonsToDownload.value, squadAddons.value)
  foreach(a in getCampaignPkgsForOnlineBattle(curCampaign.value, maxCurCampaignMRank.value))
    list[a] <- true
  foreach(a in soloNewbieByCampaign?[curCampaign.get()] ?? [])
    list[a] <- true
  return list.keys()
}))

function startDownloadAddons(addons) {
  if (addons.len() == 0)
    return
  let fullAddons = clone addonsToDownload.value
  foreach (a in addons)
    if (!hasAddons.value?[a])
      fullAddons[a] <- true
  if (fullAddons.len() != addonsToDownload.value.len())
    addonsToDownload(fullAddons)
}

startDownloadAddons(addonsToAutoDownload.value)
addonsToAutoDownload.subscribe(startDownloadAddons)

allowLimitedDownload.subscribe(function(allow) {
  get_local_custom_settings_blk()[ALLOW_LIMITED_DOWNLOAD_SAVE_ID] = allow
  logA("Allow limited connection download cahnged to: ", allow)
})

function openDownloadAddonsWnd(addons = [], successEventId = null, context = {}) {
  let rqAddons = addons.filter(@(a) !hasAddons.value?[a])
  if (addons.len() != 0 && rqAddons.len() == 0) {  //already all downloaded
    if (successEventId != null)
      eventbus_send(successEventId, context)
    return
  }

  let rqTbl = {}
  foreach (a in rqAddons)
    rqTbl[a] <- true

  let fullAddons = addonsToDownload.value.__merge(rqTbl)
  if (fullAddons.len() != addonsToDownload.value.len())
    addonsToDownload(fullAddons)

  firstPriorityAddons(rqTbl)
  downloadWndParams({ addons, successEventId, context })

  if (rqAddons.len() != 0)
    isDownloadPaused(false)
}

eventbus_subscribe("openDownloadAddonsWnd", function(msg) {
  let { addons = [], successEventId = null, context = {} } = msg
  openDownloadAddonsWnd(addons, successEventId, context)
})

return {
  startDownloadAddons  //background download, does not open window
  openDownloadAddonsWnd
  closeDownloadAddonsWnd
  downloadWndParams
  allowLimitedDownload
  isDownloadPausedByConnection = Computed(@() addonsToDownload.value.len() > 0
    && ((isConnectionLimited.value && !allowLimitedDownload.value)
      || !hasConnection.value))
  isDownloadInProgress = Computed(@() downloadInProgress.value.len() > 0)

  addonsToDownload = Computed(@() addonsToDownload.value)
  wantStartDownloadAddons
  isDownloadPaused
  downloadAddonsStr
  currentStage
  totalSizeBytes
  downloadState
  updaterError
  progressPercent
  isStageDownloading
}