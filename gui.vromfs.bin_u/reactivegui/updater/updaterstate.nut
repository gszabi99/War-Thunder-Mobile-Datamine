from "%globalsDarg/darg_library.nut" import *
let logA = log_with_prefix("[ADDONS] ")
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let contentUpdater = require("contentUpdater")
let { get_free_disk_space = @() -1,
  download_content_in_background, stop_updater, is_updater_running,
  remove_addons_resources_async = @(_) null,
  UPDATER_RESULT_SUCCESS, UPDATER_ERROR, UPDATER_EVENT_STAGE, UPDATER_EVENT_DOWNLOAD_SIZE, UPDATER_EVENT_PROGRESS,
  UPDATER_EVENT_ERROR, UPDATER_EVENT_FINISH, UPDATER_DOWNLOADING, UPDATER_EVENT_INCOMPATIBLE_VERSION
} = contentUpdater
let { get_local_custom_settings_blk, get_settings_blk } = require("blkGetters")
let { isEqual, prevIfEqual } = require("%sqstd/underscore.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInLoadingScreen, isInMpBattle } = require("%appGlobals/clientState/clientState.nut")
let { downloadInProgress, downloadState, totalSizeBytes, toDownloadSizeBytes, getDownloadLeftMbNotUpdatable,
  allowLimitedDownload, ALLOW_LIMITED_DOWNLOAD_SAVE_ID
} = require("%appGlobals/clientState/downloadState.nut")
let { localizeAddonsLimited, initialAddons, latestDownloadAddonsByCamp, latestDownloadAddons,
  commonUhqAddons, coopNewbieByCampaign, getAddonsSize, MB, toMB
} = require("%appGlobals/updater/addons.nut")
let { hasAddons, addonsSizes, addonsExistInGameFolder, addonsVersions,
  isAddonsInfoActual, isAddonsAndUnitsInfoActual, isAddonsExistInGameFolderActual,
  isAddonsVersionsActual, isUnitSizesActual, unitSizes
} = require("%appGlobals/updater/addonsState.nut")
let { getAddonCampaign, getCampaignOrig, getCampaignPkgsForOnlineBattle, getPkgsForCampaign,
  getCampaignPkgsForNewbieCoop, getCampaignPkgsForNewbieSingle, localizeUnitsResources
} = require("%appGlobals/updater/campaignAddons.nut")
let { allMyBattleUnits, missingUnitResourcesByRank, allUnitsRanks, maxReleasedUnitRanks
} = require("%appGlobals/updater/gameModeAddons.nut")
let { getMGameModeMissionUnitsAndAddons } = require("%appGlobals/updater/missionUnits.nut")
let { isAnyCampaignSelected, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { campMyUnits, battleUnitsMaxMRank } = require("%appGlobals/pServer/profile.nut")
let { isConnectionLimited, hasConnection } = require("%appGlobals/clientState/connectionStatus.nut")
let { sendLoadingAddonsBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isRandomBattleNewbie, isRandomBattleNewbieSingle, randomBattleMode, randomBattleModeCore
} = require("%rGui/gameModes/gameModeState.nut")
let { requiredSquadAddons } = require("%rGui/updater/randomBattleModeAddons.nut")
let { mkDlSizeCompByTablesWatch } = require("%rGui/updater/downloadSize.nut")
let { needUhqTextures } = require("%rGui/options/options/graphicOptions.nut")
let msgBoxError = require("%rGui/components/msgBoxError.nut")
let { totalSizeText } = require("%globalsDarg/updaterUtils.nut")
let isScriptsLoading = require("%rGui/isScriptsLoading.nut")


let DOWNLOAD_ADDONS_EVENT_ID = "downloadAddonsEvent"
let SIZE_INCREASE_MULTIPLIER = 1.2

let addonsToDownload = hardPersistWatched("updater.addonsToDownload", {})
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

let isAllowedDownloadUnits = Computed(@(prev) (type(prev) == "bool" && prev) || isUnitSizesActual.get())
let isAllowedDownloadAddons = Computed(@(prev) (type(prev) == "bool" && prev) || isAddonsInfoActual.get())
let isStageDownloading = Computed(@() currentStage.get() == UPDATER_DOWNLOADING)
let maxMyMRank = Computed(@() campMyUnits.get().reduce(@(res, u) max(res, u.mRank), 1))

function mkAddonsToDownload(list, hasAddonsV, prev) {
  let res = {}
  foreach(a in list)
    if (!(hasAddonsV?[a] ?? true))
      res[a] <- true
  return isEqual(res, prev) ? prev : res
}

let initialAddonsToDownload = Computed(@(prev) mkAddonsToDownload(initialAddons, hasAddons.get(), prev))
let latestAddonsToDownload = Computed(@(prev) mkAddonsToDownload(
  (clone latestDownloadAddons).extend(latestDownloadAddonsByCamp?[getCampaignOrig(curCampaign.get())] ?? []),
  hasAddons.get(), prev))

let errorNames = {}
foreach(id, val in contentUpdater)
  if (type(val) != "integer")
    continue
  else if (id.startswith("UPDATER_ERROR"))
    errorNames[val] <- id
let getErrorName = @(v) errorNames?[v] ?? v

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
  if (!needUhqTextures.get() || (get_settings_blk()?.graphics.uhqForceDisabled ?? true))
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

let randomBattleMisInfo = Computed(@(prev) prevIfEqual(prev,
  getMGameModeMissionUnitsAndAddons(randomBattleMode.get(), 0, battleUnitsMaxMRank.get())))
let randomBattleCoreMisInfo = Computed(@(prev) prevIfEqual(prev,
  getMGameModeMissionUnitsAndAddons(randomBattleModeCore.get(), 0, battleUnitsMaxMRank.get() + 1)))

function getMissingUnits(byRank, maxMRank) {
  let res = {}
  foreach (rank, list in byRank)
    if (rank <= maxMRank)
      res.__update(list)
  return res
}

let wantStartDownloadAddons = Computed(function(prev) {
  if (!isLoggedIn.get()
      || isIncompatibleVersion.get()
      || !isAnyCampaignSelected.get()
      || (addonsToDownload.get().len() + uhqAddonsToDownload.get().len() + unitsToDownload.get().len()) == 0)
    return prevIfEqual(prev, {})

  let campaign = curCampaign.get()
  let campaignOrig = getCampaignOrig(campaign)
  let maxMRank = battleUnitsMaxMRank.get()
  let allUnits = isAllowedDownloadUnits.get() ? unitsToDownload.get() : {}
  let allAddons = isAllowedDownloadAddons.get() ? addonsToDownload.get() : {}

  let listGetters = [
    @() {
      addons = firstPriorityAddons.get() 
      units = firstPriorityUnits.get()
    }
    @() { addons = initialAddonsToDownload.get() }
    @() requiredSquadAddons.get().map(@(v) v.totable())
    @() { units = extAutoDownloadUnits.get() }
  ]

  if (isRandomBattleNewbieSingle.get())
    listGetters.append(@() {
      addons = getCampaignPkgsForNewbieSingle(campaign).totable()
      units = allMyBattleUnits.get()
    })
  if (isRandomBattleNewbie.get())
    listGetters.append(@() {
      addons = getCampaignPkgsForNewbieCoop(campaign, maxMRank).totable()
        .__merge(randomBattleMisInfo.get().misAddons)
      units = getMissingUnits(missingUnitResourcesByRank.get()?[getCampaignOrig(campaign)] ?? {}, maxMRank)
        .__merge(randomBattleMisInfo.get().misUnits)
    })

  listGetters.append(
    @() {
      addons = getCampaignPkgsForOnlineBattle(campaign, maxMRank).totable()
        .__merge(randomBattleCoreMisInfo.get().misAddons)
      units = getMissingUnits(missingUnitResourcesByRank.get()?[getCampaignOrig(campaign)] ?? {}, maxMRank + 1)
        .__merge(randomBattleCoreMisInfo.get().misUnits)
    }
    @() { addons = allAddons.filter(@(_, a) (getAddonCampaign(a) ?? campaignOrig) == campaignOrig) }
    @() { addons = latestAddonsToDownload.get() }
  )

  foreach (getList in listGetters) {
    let { addons = {}, units = {} } = getList()
    let fUnits = allUnits.filter(@(_, u) u in units)
    let fAddons = allAddons.filter(@(_, a) a in addons)
    if (fUnits.len() + fAddons.len() != 0)
      return prevIfEqual(prev, { addons = fAddons, units = fUnits })
  }

  return prevIfEqual(prev,
    allAddons.len() != 0 ? { addons = allAddons }
      : uhqAddonsToDownload.get().len() != 0 && isAllowedDownloadAddons.get()
        ? { addons = uhqAddonsToDownload.get() }
      : allUnits.len() != 0 ? { units = allUnits }
      : {})
})

let needStartDownloadAddons = keepref(Computed(@(prev)
  awaitingAddonsInfoUpd.get() != null && type(prev) == "table" ? prev
    : isDownloadPaused.get()
        || isInLoadingScreen.get()
        || isInMpBattle.get()
        || (isConnectionLimited.get() && !allowLimitedDownload.get())
        || !hasConnection.get()
      ? {}
    : wantStartDownloadAddons.get()))

let wantStartDlSize = mkDlSizeCompByTablesWatch(wantStartDownloadAddons, "Updater: ")

function cleanAddonsToDownload(addonsToRemoveArr = null, unitsToRemoveArr = null) {
  let resAddons = addonsToDownload.get().filter(@(_, a) !(hasAddons.get()?[a] ?? true))
  if (addonsToRemoveArr != null)
    foreach(a in addonsToRemoveArr)
      resAddons.$rawdelete(a)
  if (resAddons.len() != addonsToDownload.get().len())
    addonsToDownload.set(resAddons)

  let sizes = unitSizes.get()
  let resUnits = unitsToDownload.get().filter(@(_, u) (sizes?[u] ?? -1) != 0)
  if (unitsToRemoveArr != null)
    foreach(u in unitsToRemoveArr)
      resUnits.$rawdelete(u)
  if (resUnits.len() != unitsToDownload.get().len())
    unitsToDownload.set(resUnits)
}

let closeDownloadAddonsWnd = @() downloadWndParams.set(null)
curCampaign.subscribe(@(_) downloadWndParams.get() == null ? firstPriorityAddons.set({}) : null)

function updateStartDownload() {
  let needDownload = needStartDownloadAddons.get().len() != 0
  if (needDownload == is_updater_running()
      && (!needDownload || isEqual(needStartDownloadAddons.get(), downloadInProgress.get())))
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

  if (wantStartDlSize.get() < 0) {
    logA("Wait to get download size")
    return
  }

  let addons = needStartDownloadAddons.get()?.addons.keys() ?? []
  let units = needStartDownloadAddons.get()?.units.keys() ?? []
  local isStarted = false
  let totalSize = wantStartDlSize.get()
  let freeSpace = get_free_disk_space()
  logA($"total size to download: {toMB(totalSize)}MB, free space: {freeSpace < 0 ? freeSpace : toMB(freeSpace)}MB")
  if (freeSpace > 0 && totalSize > freeSpace) {
    stop_updater()
    downloadInProgress.set({})
    isDownloadPaused.set(true)
    msgBoxError({ text = loc("msgbox/notEnoughSpace", {space = totalSizeText(((totalSize - freeSpace) * SIZE_INCREASE_MULTIPLIER).tointeger())}) })
    return
  }
  isStarted = download_content_in_background(DOWNLOAD_ADDONS_EVENT_ID, units, addons)
  logA(isStarted ? "start download " : "ignore download ",
    ", ".join(addons.map(@(a) $"{a}: {addonsExistInGameFolder.get()?[a] ? "exists in game folder" : (addonsVersions.get()?[a] ?? "-")}")),
    "\nunits:\n",
    ", ".join(units))

  if (!isStarted) {
    cleanAddonsToDownload(addons, units) 
    downloadInProgress.set({})
  } else
    downloadInProgress.set(needStartDownloadAddons.get())
}
updateStartDownload()
needStartDownloadAddons.subscribe(@(_) deferOnce(updateStartDownload))
wantStartDlSize.subscribe(@(v) v >= 0 && !is_updater_running() && downloadInProgress.get().len() == 0
  ? deferOnce(updateStartDownload)
  : null)

addonsToDownload.subscribe(function(v) {
  if (v.len() != 0)
    return
  isDownloadPaused.set(false)
  currentStage.set(null)
  totalSizeBytes.set(0)
  toDownloadSizeBytes.set(0)
  downloadState.set(null)
  updaterError.set(null)
})

wantStartDownloadAddons.subscribe(function(_) {
  totalSizeBytes.set(0)
  toDownloadSizeBytes.set(0)
  downloadState.set(null)
})

eventbus_subscribe(DOWNLOAD_ADDONS_EVENT_ID, function(evt) {
  let { eventType } = evt
  if (eventType == UPDATER_EVENT_STAGE)
    currentStage.set(evt?.stage)
  else if (eventType == UPDATER_EVENT_DOWNLOAD_SIZE) {
    toDownloadSizeBytes.set(evt?.toDownload ?? 0)
    totalSizeBytes.set(evt?.total ?? 0)
  } else if (eventType == UPDATER_EVENT_PROGRESS)
    downloadState.set(evt)
  else if (eventType == UPDATER_EVENT_INCOMPATIBLE_VERSION) {
    isIncompatibleVersion.set(true)
    eventbus_send((evt?.needExeUpdate ?? true) ? "showIncompatibleVersionMsg" : "showRestartForUpdateMsg", null)
  }
  else if (eventType == UPDATER_EVENT_ERROR) {
    let errText = getErrorName(evt?.error ?? UPDATER_ERROR)
    let { isStopped = false } = evt
    logA($"download error: {errText}, (isStopped = {isStopped})")
    if (!isStopped)
      updaterError.set(errText)
  }
  else if (eventType == UPDATER_EVENT_FINISH) {
    let isSuccess = evt?.result == UPDATER_RESULT_SUCCESS
    logA($"download finish. isSuccess = {isSuccess}, isStopped = {evt?.isStopped}")
    awaitingAddonsInfoUpd.set({ isDownloadFinishedSuccessfully = isSuccess })
    isAddonsExistInGameFolderActual.set(false)
    isAddonsVersionsActual.set(false)
    isUnitSizesActual.set(false)
  }
})

isAddonsAndUnitsInfoActual.subscribe(function(v) {
  if (!v || awaitingAddonsInfoUpd.get() == null)
    return

  logA("addons info updated after download finish")
  let { isDownloadFinishedSuccessfully } = awaitingAddonsInfoUpd.get()
  awaitingAddonsInfoUpd.set(null)

  if (!is_updater_running())
    downloadInProgress.set({})
  if (!isDownloadFinishedSuccessfully) {
    updateStartDownload()
    return
  }

  cleanAddonsToDownload()
  downloadState.set(null)

  let { successEventId = null, context = {}, addons = [], units = [] } = downloadWndParams.get()
  if (null != addons.findvalue(@(a) a in addonsToDownload.get())
      || null != units.findvalue(@(u) u in unitsToDownload.get()))
    return 

  closeDownloadAddonsWnd()
  if (successEventId != null)
    eventbus_send(successEventId, context)
})

function getAddonPriority(addon) {
  let campaign = getAddonCampaign(addon)
  return campaign == getCampaignOrig(curCampaign.get()) ? 2
    : campaign == null ? 1
    : 0
}

let downloadAddonsStr = Computed(function() {
  let units = wantStartDownloadAddons.get()?.units.keys() ?? []
  let addons = wantStartDownloadAddons.get()?.addons.keys()
    .sort(@(a, b) getAddonPriority(b) <=> getAddonPriority(a)
      || b <=> a)
    ?? []
  let textArr = []
  if (units.len() != 0)
    textArr.extend(localizeUnitsResources(units, allUnitsRanks.get(), curCampaign.get()))
  if (addons.len() != 0)
    textArr.append(localizeAddonsLimited(addons, max(1, 3 - textArr.len())))
  return comma.join(textArr)
})

let maxCurCampaignMRank = Computed(function() {
  local res = 0
  foreach(unit in campMyUnits.get())
    res = max(res, unit.mRank)
  return res
})

let addonsToAutoDownload = keepref(Computed(function() {
  if (!isAnyCampaignSelected.get())
    return initialAddonsToDownload.get()?.keys()
  let maxMRank = max(battleUnitsMaxMRank.get(), maxCurCampaignMRank.get())
  let list = initialAddonsToDownload.get().__merge(latestAddonsToDownload.get(),
    requiredSquadAddons.get().addons.reduce(@(res, a) res.$rawset(a, true), {}))
  foreach (a in getCampaignPkgsForOnlineBattle(curCampaign.get(), maxMRank))
    list[a] <- true
  foreach (a in getCampaignPkgsForNewbieSingle(curCampaign.get()))
    list[a] <- true
  foreach (a in coopNewbieByCampaign?[getCampaignOrig(curCampaign.get())] ?? [])
    list[a] <- true
  list.__update(getMGameModeMissionUnitsAndAddons(randomBattleMode.get(), 0, maxMRank).misAddons)
  list.__update(getMGameModeMissionUnitsAndAddons(randomBattleModeCore.get(), 0, maxMRank + 1).misAddons)
  return list.keys()
}))

function startDownloadAddons(addons) {
  if (addons.len() == 0)
    return
  let fullAddons = clone addonsToDownload.get()
  foreach (a in addons)
    if (!(hasAddons.get()?[a] ?? true))
      fullAddons[a] <- true
  if (fullAddons.len() != addonsToDownload.get().len())
    addonsToDownload.set(fullAddons)
}

startDownloadAddons(addonsToAutoDownload.get())
addonsToAutoDownload.subscribe(startDownloadAddons)

let unitsToAutoDownload = keepref(Computed(function(prev) {
  if (!isAnyCampaignSelected.get() || !isAllowedDownloadUnits.get())
    return {}
  let res = clone extAutoDownloadUnits.get()
  let mRank = max(battleUnitsMaxMRank.get(), maxMyMRank.get())
  let tgtRank = clamp(maxReleasedUnitRanks.get()?[curCampaign.get()] ?? (mRank + 1), mRank, mRank + 1)
  foreach (rank, list in missingUnitResourcesByRank.get()?[getCampaignOrig(curCampaign.get())] ?? {})
    if (rank <= tgtRank)
      res.__update(list)
  res.__update(requiredSquadAddons.get().units.reduce(@(r, a) r.$rawset(a, true), {}),
    randomBattleMisInfo.get().misUnits,
    randomBattleCoreMisInfo.get().misUnits)
  return prevIfEqual(prev, res)
}))

function startDownloadUnits(units) {
  if (units.len() == 0)
    return
  let fullUnits = clone unitsToDownload.get()
  let sizes = unitSizes.get()
  foreach (u, _ in units)
    if ((sizes?[u] ?? -1) != 0)
      fullUnits[u] <- true
  if (fullUnits.len() != unitsToDownload.get().len())
    unitsToDownload.set(fullUnits)
}

startDownloadUnits(unitsToAutoDownload.get())
unitsToAutoDownload.subscribe(startDownloadUnits)

allowLimitedDownload.subscribe(function(allow) {
  get_local_custom_settings_blk()[ALLOW_LIMITED_DOWNLOAD_SAVE_ID] = allow
  logA("Allow limited connection download cahnged to: ", allow)
})

function openDownloadAddonsWnd(addons = [], units = [], bqSource = "unknown", bqParams = {}, successEventId = null, context = {}) {
  let rqAddons = addons.filter(@(a) !(hasAddons.get()?[a] ?? true))
  let rqUnits = units.filter(@(u) (unitSizes.get()?[u] ?? -1) != 0)
  if (rqAddons.len() + rqUnits.len() == 0 
      && (addons.len() + units.len() != 0 || addonsToDownload.get().len() + unitsToDownload.get().len() == 0)) {
    if (successEventId != null)
      eventbus_send(successEventId, context)
    return
  }

  local sizeMb = 0
  if (rqAddons.len() != 0) {
    let rqTbl = addons.len() != 0 ? {}
      : firstPriorityAddons.get().filter(@(_, a) !(hasAddons.get()?[a] ?? true))
    foreach (a in rqAddons)
      rqTbl[a] <- true
    firstPriorityAddons.set(rqTbl)

    let fullAddons = addonsToDownload.get().__merge(rqTbl)
    if (fullAddons.len() != addonsToDownload.get().len())
      addonsToDownload.set(fullAddons)

    let isAlreadyInProgress = isEqual(downloadInProgress.get()?.addons, rqTbl)
    sizeMb = isAlreadyInProgress ? getDownloadLeftMbNotUpdatable() : 0
    if (sizeMb <= 0 && rqAddons.len() > 0)
      sizeMb = (getAddonsSize(rqAddons, addonsSizes.get()) + (MB / 2)) / MB
  }

  if (rqUnits.len() != 0) {
    let rqTbl = {}
    foreach (u in rqUnits)
      rqTbl[u] <- true
    firstPriorityUnits.set(rqTbl)

    let fullUnits = unitsToDownload.get().__merge(rqTbl)
    if (fullUnits.len() != unitsToDownload.get().len())
      unitsToDownload.set(fullUnits)
  }

  let bqAction = rqAddons.len() + rqUnits.len() == 0 ? "open_download_wnd"
    : rqAddons.len() == 0 ? "open_download_wnd_for_units"
    : rqUnits.len() == 0 ? "open_download_wnd_for_addons"
    : "open_download_wnd_for_units_and_addons"
  sendLoadingAddonsBqEvent(bqAction, rqAddons, rqUnits, bqParams.__merge({ sizeMb, source = bqSource }))

  downloadWndParams.set({ addons, units, successEventId, context })

  if (rqAddons.len() + rqUnits.len() != 0)
    isDownloadPaused.set(false)
}

eventbus_subscribe("openDownloadAddonsWnd", function(msg) {
  let { addons = [], units = [], successEventId = null, context = {}, bqSource = "unknown_dagui", bqParams = {} } = msg
  openDownloadAddonsWnd(addons, units, bqSource, bqParams, successEventId, context)
})

function removeAddonsForCampaign(campaigns) {
  remove_addons_resources_async(getPkgsForCampaign(campaigns))
}

return {
  startDownloadAddons  
  openDownloadAddonsWnd
  closeDownloadAddonsWnd
  downloadWndParams
  allowLimitedDownload
  isDownloadPausedByConnection = Computed(@() addonsToDownload.get().len() > 0
    && ((isConnectionLimited.get() && !allowLimitedDownload.get())
      || !hasConnection.get()))
  isDownloadInProgress = Computed(@() downloadInProgress.get().len() > 0)
  registerAutoDownloadUnits

  addonsToDownload = Computed(@() addonsToDownload.get())
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
}