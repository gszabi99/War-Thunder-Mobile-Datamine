from "%globalsDarg/darg_library.nut" import *
let logA = log_with_prefix("[ADDONS] ")
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { get_free_disk_space = @() -1,
  download_addons_in_background, stop_updater, is_updater_running,
  get_incomplete_addons, download_units_in_background, has_missing_resources_for_units,
  remove_addons_resources_async = @(_) null,
  UPDATER_RESULT_SUCCESS, UPDATER_ERROR, UPDATER_EVENT_STAGE, UPDATER_EVENT_DOWNLOAD_SIZE, UPDATER_EVENT_PROGRESS,
  UPDATER_EVENT_ERROR, UPDATER_EVENT_FINISH, UPDATER_DOWNLOADING, UPDATER_EVENT_INCOMPATIBLE_VERSION
} = require("contentUpdater")
let { get_local_custom_settings_blk, get_settings_blk } = require("blkGetters")
let { isEqual } = require("%sqstd/underscore.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInLoadingScreen, isInMpBattle } = require("%appGlobals/clientState/clientState.nut")
let { downloadInProgress, downloadState, totalSizeBytes, toDownloadSizeBytes, getDownloadLeftMbNotUpdatable,
  allowLimitedDownload, ALLOW_LIMITED_DOWNLOAD_SAVE_ID
} = require("%appGlobals/clientState/downloadState.nut")
let { localizeAddonsLimited, initialAddons, latestDownloadAddonsByCamp, latestDownloadAddons,
  commonUhqAddons, soloNewbieByCampaign, coopNewbieByCampaign, getAddonsSize, MB, extendedSoundAddons
} = require("%appGlobals/updater/addons.nut")
let { hasAddons, addonsSizes, addonsExistInGameFolder, addonsVersions,
  isAddonsInfoActual, isAddonsExistInGameFolderActual, isAddonsVersionsActual
} = require("%appGlobals/updater/addonsState.nut")
let { getAddonCampaign, getCampaignOrig, getCampaignPkgsForOnlineBattle, getPkgsForCampaign,
  getCampaignPkgsForNewbieCoop, getCampaignPkgsForNewbieSingle
} = require("%appGlobals/updater/campaignAddons.nut")
let { allMyBattleUnits } = require("%appGlobals/updater/gameModeAddons.nut")
let { isAnyCampaignSelected, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { campMyUnits, battleUnitsMaxMRank } = require("%appGlobals/pServer/profile.nut")
let { isConnectionLimited, hasConnection } = require("%appGlobals/clientState/connectionStatus.nut")
let { sendLoadingAddonsBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isRandomBattleNewbie, isRandomBattleNewbieSingle } = require("%rGui/gameModes/gameModeState.nut")
let { squadAddons } = require("%rGui/squad/squadAddons.nut")
let { needUhqTextures } = require("%rGui/options/options/graphicOptions.nut")
let { mkOptionValue, OPT_SOUND_USE_EXTENDED } = require("%rGui/options/guiOptions.nut")
let msgBoxError = require("%rGui/components/msgBoxError.nut")
let { totalSizeText } = require("%globalsDarg/updaterUtils.nut")
let isScriptsLoading = require("%rGui/isScriptsLoading.nut")


let DOWNLOAD_ADDONS_EVENT_ID = "downloadAddonsEvent"
let SIZE_INCREASE_MULTIPLIER = 1.2

let addonsToDownload = hardPersistWatched("updater.addonsToDownload",
  get_incomplete_addons().reduce(function(res, v) {
    if (!v.endswith("_uhq")) 
      res[v] <- true
    return res
  }, {}))
let unitsToDownload = hardPersistWatched("updater.unitsToDownload", {})
let isDownloadPaused = hardPersistWatched("updater.isDownloadPaused", false)
let currentStage = hardPersistWatched("updater.currentStage", null)
let updaterError = hardPersistWatched("updater.updaterError", null)
let awaitingAddonsInfoUpd = hardPersistWatched("updater.awaitingAddonsInfoUpd", null)
let isIncompatibleVersion = Watched(false)
let extAutoDownloadUnits = Watched({})

let firstPriorityAddons = mkWatched(persist, "firstPriorityAddons", {})
let firstPriorityUnits = mkWatched(persist, "firstPriorityUnits", {})
let downloadWndParams = mkWatched(persist, "downloadWndParams", null)
let progressPercent = Computed(function() {
  let { percent = null } = downloadState.get()
  if (totalSizeBytes.get() == 0 || percent == null)
    return percent
  return clamp((100.0 + toDownloadSizeBytes.get() * (percent - 100.0) / totalSizeBytes.get() + 0.5).tointeger(), 0, 100)
})

let isStageDownloading = Computed(@() currentStage.value == UPDATER_DOWNLOADING)

function mkAddonsToDownload(list, hasAddonsV, prev) {
  let res = {}
  foreach(a in list)
    if (!(hasAddonsV?[a] ?? true))
      res[a] <- true
  return isEqual(res, prev) ? prev : res
}

let initialAddonsToDownload = Computed(@(prev) mkAddonsToDownload(initialAddons, hasAddons.get(), prev))
let latestAddonsToDownload = Computed(@(prev) mkAddonsToDownload(
  (clone latestDownloadAddons).extend(latestDownloadAddonsByCamp?[curCampaign.value] ?? []),
  hasAddons.get(), prev))

let validateSoundOption = @(val, list) list.contains(val) ? val : list[0]
let useExtendedSoundsList = [false, true]
let isSoundAddonsEnabled = mkOptionValue(OPT_SOUND_USE_EXTENDED, false, @(v) validateSoundOption(v, useExtendedSoundsList))
let soundAddonsToDownload = Computed(@(prev) mkAddonsToDownload(extendedSoundAddons, hasAddons.get(), prev))

let extAutoDownloadUnitsWatches = []

function recalcExtAutoUnits() {
  let units = {}
  foreach (list in extAutoDownloadUnitsWatches)
    units.__update(list.get())
  extAutoDownloadUnits.set(units)
}
let deferRecalcExtAutoUnits = @() deferOnce(recalcExtAutoUnits)

function registerAutoDownloadUnits(unitsW) {
  if (!isScriptsLoading.get() && !__static_analysis__) {
    logerr("registerAutoDownloadUnits call not on scripts load")
    return
  }
  if (extAutoDownloadUnitsWatches.contains(unitsW)) {
    logerr("duplicate registerAutoDownloadUnits")
    return
  }
  extAutoDownloadUnitsWatches.append(unitsW)
  unitsW.subscribe(@(_) deferRecalcExtAutoUnits())
  deferRecalcExtAutoUnits()
}

let uhqAddonsToDownload = Computed(function(prev) {
  if (!needUhqTextures.value || (get_settings_blk()?.graphics.uhqForceDisabled ?? true))
    return isEqual(prev, {}) ? prev : {}
  let res = clone commonUhqAddons
  foreach(a, has in hasAddons.get())
    if (has) {
      let uhq = $"{a}_uhq"
      if (uhq in hasAddons.get())
        res.append(uhq)
    }
  return mkAddonsToDownload(res, hasAddons.get(), prev)
})

let prevIfEqual = @(prev, cur) isEqual(cur, prev) ? prev : cur

let wantStartDownloadAddons = Computed(function(prev) {
  if (!isLoggedIn.value
      || isIncompatibleVersion.value
      || (addonsToDownload.get().len() + uhqAddonsToDownload.get().len() + unitsToDownload.get().len()) == 0)
    return prevIfEqual(prev, {})

  let addons = firstPriorityAddons.value.__merge(initialAddonsToDownload.value, squadAddons.value) 
  local res = addonsToDownload.value.filter(@(_, a) a in addons)
  if (res.len() != 0)
    return prevIfEqual(prev, { addons = res })

  local units = unitsToDownload.get().filter(@(_, u) u in firstPriorityUnits.get())
  if (units.len() != 0)
    return prevIfEqual(prev, { units })
  units = unitsToDownload.get().filter(@(_, u) u in extAutoDownloadUnits.get())
  if (units.len() != 0)
    return prevIfEqual(prev, { units })
  if (unitsToDownload.get().len() != 0)
    return prevIfEqual(prev, { units = unitsToDownload.get() })

  if (!isAnyCampaignSelected.value)
    return prevIfEqual(prev, {})

  let campaign = curCampaign.get()
  let maxMRank = battleUnitsMaxMRank.get()
  let listGetters = []
  if (isRandomBattleNewbieSingle.get())
    listGetters.append(@() getCampaignPkgsForNewbieSingle(campaign, maxMRank, allMyBattleUnits.get().keys()))
  if (isRandomBattleNewbie.get())
    listGetters.append(@() getCampaignPkgsForNewbieCoop(campaign, maxMRank))
  listGetters.append(@() getCampaignPkgsForOnlineBattle(campaign, maxMRank))
  foreach (getList in listGetters) {
    let curUnitAddons = getList()
    res = addonsToDownload.get().filter(@(_, a) curUnitAddons.contains(a))
    if (res.len() != 0)
      return prevIfEqual(prev, { addons = res })
  }

  let campaignOrig = getCampaignOrig(campaign)
  res = addonsToDownload.value.filter(@(_, a) (getAddonCampaign(a) ?? campaignOrig) == campaignOrig)
  if (res.len() != 0)
    return prevIfEqual(prev, { addons = res })

  res = addonsToDownload.value.filter(@(_, a) a in latestAddonsToDownload.value)
  if (res.len() != 0)
    return prevIfEqual(prev, { addons = res })

  if (addonsToDownload.value.len() != 0)
    return prevIfEqual(prev, { addons = addonsToDownload.get() })
  if (uhqAddonsToDownload.get().len() != 0)
    return prevIfEqual(prev, { addons = uhqAddonsToDownload.get() })
  return prevIfEqual(prev, {})
})

let needStartDownloadAddons = keepref(Computed(@()
  isDownloadPaused.value
      || isInLoadingScreen.get()
      || isInMpBattle.get()
      || (isConnectionLimited.value && !allowLimitedDownload.get())
      || !hasConnection.value
    ? {}
    : wantStartDownloadAddons.value))

function cleanAddonsToDownload() {
  let { addons = null, units = null } = needStartDownloadAddons.get()
  if (addons != null) {
    let res = addonsToDownload.get().filter(@(_, a) !hasAddons.get()?[a])
    foreach(a, _ in addons)
      res.$rawdelete(a)
    if (res.len() != addonsToDownload.get().len())
      addonsToDownload.set(res)
  }

  if (units != null) {
    let res = unitsToDownload.get().filter(@(_, u) !has_missing_resources_for_units([u], true))
    foreach(u, _ in units)
      res.$rawdelete(u)
    if (res.len() != unitsToDownload.get().len())
      unitsToDownload.set(res)
  }
}

let closeDownloadAddonsWnd = @() downloadWndParams(null)
curCampaign.subscribe(@(_) downloadWndParams.value == null ? firstPriorityAddons({}) : null)

function updateStartDownload() {
  let needDownload = needStartDownloadAddons.value.len() != 0
  if (needDownload == is_updater_running()
      && (!needDownload || isEqual(needStartDownloadAddons.value, downloadInProgress.get())))
    return

  if (!needDownload) {
    logA("stop download")
    stop_updater()
    downloadInProgress.set({})
    return
  }

  if (is_updater_running()) { 
    logA("stop download to change addons list")
    stop_updater()
    downloadInProgress.set({})
    return
  }

  let addons = needStartDownloadAddons.get()?.addons.keys()
  let units = needStartDownloadAddons.get()?.units.keys()
  local isStarted = false
  if (addons != null) {
    let totalSize = getAddonsSize(addons, addonsSizes.get())
    let freeSpace = get_free_disk_space()
    logA($"total size to download: {totalSize}, free space: {freeSpace}")
    if (freeSpace > 0 && totalSize > freeSpace){
      stop_updater()
      downloadInProgress.set({})
      msgBoxError({ text = loc("msgbox/notEnoughSpace", {space = totalSizeText(((totalSize - freeSpace) * SIZE_INCREASE_MULTIPLIER).tointeger())}) })
      return
    }
    isStarted = download_addons_in_background(DOWNLOAD_ADDONS_EVENT_ID, addons)
    logA(isStarted ? "start download " : "ignore download ",
      ", ".join(addons.map(@(a) $"{a}: {addonsExistInGameFolder.get()?[a] ? "exists in game folder" : (addonsVersions.get()?[a] ?? "-")}")))
  }
  else if (units != null) {
    isStarted = download_units_in_background(DOWNLOAD_ADDONS_EVENT_ID, units, true)
    logA(isStarted ? "start download units " : "ignore download units",
      ", ".join(units))
  }
  else
    logerr("[ADDONS] incorrect format of needStartDownloadAddons")

  if (!isStarted) {
    cleanAddonsToDownload() 
    downloadInProgress.set({})
  } else
    downloadInProgress.set(needStartDownloadAddons.get())
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
    awaitingAddonsInfoUpd.set({ isDownloadFinishedSuccessfully = isSuccess })
    isAddonsExistInGameFolderActual.set(false)
    isAddonsVersionsActual.set(false)
  }
})

isAddonsInfoActual.subscribe(function(v) {
  if (!v || awaitingAddonsInfoUpd.get() == null)
    return

  logA("addons info updated after download finish")
  let { isDownloadFinishedSuccessfully } = awaitingAddonsInfoUpd.get()
  awaitingAddonsInfoUpd.set(null)

  downloadInProgress({})
  if (!isDownloadFinishedSuccessfully) {
    updateStartDownload()
    return
  }

  let { successEventId = null, context = {} } = downloadWndParams.get()
  cleanAddonsToDownload()
  closeDownloadAddonsWnd()
  if (successEventId != null)
    eventbus_send(successEventId, context)
  downloadState(null)
})

function getAddonPriority(addon) {
  let campaign = getAddonCampaign(addon)
  return campaign == getCampaignOrig(curCampaign.get()) ? 2
    : campaign == null ? 1
    : 0
}

let downloadAddonsStr = Computed(function() {
  if (wantStartDownloadAddons.value.len() == 0)
    return ""
  let list = wantStartDownloadAddons.get()?.addons.keys()
  if (list == null) 
    return loc("download/unitResources")

  list.sort(@(a, b) getAddonPriority(b) <=> getAddonPriority(a)
    || b <=> a)
  return localizeAddonsLimited(list, 3)
})

let maxCurCampaignMRank = Computed(function() {
  local res = 0
  foreach(unit in campMyUnits.get())
    res = max(res, unit.mRank)
  return res
})

let addonsToAutoDownload = keepref(Computed(function() {
  if (!isAnyCampaignSelected.value)
    return initialAddonsToDownload.value?.keys()
  let list = initialAddonsToDownload.value.__merge(latestAddonsToDownload.get(), squadAddons.get(),
    isSoundAddonsEnabled.get() ? soundAddonsToDownload.get() : {})
  foreach(a in getCampaignPkgsForOnlineBattle(curCampaign.value, maxCurCampaignMRank.value))
    list[a] <- true
  foreach(a in soloNewbieByCampaign?[curCampaign.get()] ?? [])
    list[a] <- true
  foreach(a in coopNewbieByCampaign?[curCampaign.get()] ?? [])
    list[a] <- true
  return list.keys()
}))

function startDownloadAddons(addons) {
  if (addons.len() == 0)
    return
  let fullAddons = clone addonsToDownload.value
  foreach (a in addons)
    if (!hasAddons.get()?[a])
      fullAddons[a] <- true
  if (fullAddons.len() != addonsToDownload.value.len())
    addonsToDownload(fullAddons)
}

startDownloadAddons(addonsToAutoDownload.value)
addonsToAutoDownload.subscribe(startDownloadAddons)

function startDownloadUnits(units) {
  if (units.len() == 0)
    return
  let fullUnits = clone unitsToDownload.get()
  foreach (u, _ in units)
    if (has_missing_resources_for_units([u], true))
      fullUnits[u] <- true
  if (fullUnits.len() != unitsToDownload.value.len())
    unitsToDownload.set(fullUnits)
}

startDownloadUnits(extAutoDownloadUnits.get())
extAutoDownloadUnits.subscribe(startDownloadUnits)

allowLimitedDownload.subscribe(function(allow) {
  get_local_custom_settings_blk()[ALLOW_LIMITED_DOWNLOAD_SAVE_ID] = allow
  logA("Allow limited connection download cahnged to: ", allow)
})

function openDownloadAddonsWnd(addons = [], bqSource = "unknown", bqParams = {}, successEventId = null, context = {}) {
  let rqAddons = addons.filter(@(a) !hasAddons.get()?[a])
  if (addons.len() != 0 && rqAddons.len() == 0) {  
    if (successEventId != null)
      eventbus_send(successEventId, context)
    return
  }

  let rqTbl = addons.len() != 0 ? {}
    : firstPriorityAddons.get().filter(@(_, a) !hasAddons.get()?[a])
  foreach (a in rqAddons)
    rqTbl[a] <- true

  let fullAddons = addonsToDownload.value.__merge(rqTbl)
  if (fullAddons.len() != addonsToDownload.value.len())
    addonsToDownload(fullAddons)

  let isAlreadyInProgress = isEqual(downloadInProgress.get()?.addons, rqTbl)
  local sizeMb = isAlreadyInProgress ? getDownloadLeftMbNotUpdatable() : 0
  if (sizeMb <= 0 && rqAddons.len() > 0)
    sizeMb = (getAddonsSize(rqAddons, addonsSizes.get()) + (MB / 2)) / MB
  sendLoadingAddonsBqEvent("open_download_wnd", rqAddons, bqParams.__merge({ sizeMb, source = bqSource }))

  firstPriorityAddons(rqTbl)
  downloadWndParams({ addons, successEventId, context })

  if (rqAddons.len() != 0)
    isDownloadPaused(false)
}

function openDownloadUnitsWnd(units = [], bqSource = "unknown", bqParams = {}, successEventId = null, context = {}) {
  if (units.len() == 0 || !has_missing_resources_for_units(units, true)) {
    if (successEventId != null)
      eventbus_send(successEventId, context)
    return
  }

  let rqTbl = {}
  foreach (u in units)
    rqTbl[u] <- true
  firstPriorityUnits.set(rqTbl)

  let fullUnits = unitsToDownload.get().__merge(rqTbl)
  if (fullUnits.len() != unitsToDownload.get().len())
    unitsToDownload.set(fullUnits)

  sendLoadingAddonsBqEvent("open_download_wnd_for_units", units, bqParams.__merge({ source = bqSource }))
  downloadWndParams.set({ units, successEventId, context })
  isDownloadPaused.set(false)
}

eventbus_subscribe("openDownloadAddonsWnd", function(msg) {
  let { addons = [], successEventId = null, context = {}, bqSource = "unknown_dagui", bqParams = {} } = msg
  openDownloadAddonsWnd(addons, bqSource, bqParams, successEventId, context)
})

function removeAddonsForCampaign(campaigns) {
  remove_addons_resources_async(getPkgsForCampaign(campaigns))
}

return {
  startDownloadAddons  
  openDownloadAddonsWnd
  openDownloadUnitsWnd
  closeDownloadAddonsWnd
  downloadWndParams
  allowLimitedDownload
  isDownloadPausedByConnection = Computed(@() addonsToDownload.value.len() > 0
    && ((isConnectionLimited.value && !allowLimitedDownload.get())
      || !hasConnection.value))
  isDownloadInProgress = Computed(@() downloadInProgress.get().len() > 0)
  registerAutoDownloadUnits

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
  removeAddonsForCampaign

  isSoundAddonsEnabled
  soundAddonsToDownload
  useExtendedSoundsList
}