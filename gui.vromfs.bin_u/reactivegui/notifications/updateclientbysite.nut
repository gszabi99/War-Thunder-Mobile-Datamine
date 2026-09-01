from "%globalsDarg/darg_library.nut" import *
from "android.platform" import enqueueDownload, queryDownloadStatus, tryToInstall, getApkFileVersion,
  DOWNLOAD_STASUS_UNKNOWN, DOWNLOAD_STATUS_PENDING, DOWNLOAD_STATUS_RUNNING, DOWNLOAD_STATUS_PAUSED,
  DOWNLOAD_STATUS_SUCCESSFUL, DOWNLOAD_STATUS_FAILED
from "app" import get_base_game_version_str
from "blkGetters" import get_local_custom_settings_blk
from "dagor.workcycle" import deferOnce, resetTimeout
from "eventbus" import eventbus_subscribe, eventbus_send
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/clientState/clientState.nut" import isInLoadingScreen
from "%appGlobals/clientState/connectionStatus.nut" import isConnectionLimited
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox, subscribeFMsgBtns
from "%rGui/components/modalWindows.nut" import hasModalWindows
from "%rGui/mainMenu/mainMenuState.nut" import isMainMenuAttached
from "%rGui/notifications/needUpdate/needUpdateAndroidSite.nut" import actualGameVersion, actualGameHash,
  getApkLinkWithHash, apkTag
from "%rGui/options/options/gameAutoUpdateOption.nut" import isGameAutoUpdateEnabled
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import isTutorialActive


let logD = log_with_prefix("[DOWNLOAD] ")

let isSuggested = hardPersistWatched("suggestInstall.isSuggested", false)
let cachedDownloadId = hardPersistWatched("suggestInstall.downloadId", null)
const SUGGEST_INSTALL_APK = "suggestInstallApk"
const DOWNLOAD_SUCCESSFUL_BY_SITE = "downloadSuccessfulBySite"
const TIME_TO_CHECK_DOWNLOAD_STATUS = 2
let getApkName = @() $"wtm_{apkTag}_{actualGameVersion.get()}.apk"

let hasDownloadedApk = Watched(false)
let isDownloadInProgress = Watched(false)

let needShowModal = keepref(Computed(@() !hasModalWindows.get()
  && !isDownloadInProgress.get()
  && !isInLoadingScreen.get()
  && !isTutorialActive.get()
  && !isSuggested.get()
  && hasDownloadedApk.get()
  && isMainMenuAttached.get()
  && isLoggedIn.get()))

function saveDownloadId(id) {
  let blk = get_local_custom_settings_blk()
  blk.addBlock(DOWNLOAD_SUCCESSFUL_BY_SITE)["downloadId"] <- id
  eventbus_send("saveProfile", {})
}

let getDownloadedId = @() get_local_custom_settings_blk()?[DOWNLOAD_SUCCESSFUL_BY_SITE]["downloadId"]

let showSuggestInstallModal = @() openFMsgBox({
  uid = SUGGEST_INSTALL_APK
  isPersist = true
  text = loc("msg/updateDownloaded/successfully")
  buttons = [
    { text = loc("ugm/btnDelay"), eventId = "markSuggestInstallSeen", isCancel = true }
    { text = loc("ugm/btnInstall"), eventId = "tryToInstallApk", styleId = "PRIMARY", isDefault = true }
  ]})

let customStatusHandlers = {
  [DOWNLOAD_STASUS_UNKNOWN] = @(id) logD($"Unknown download status for download: {id}"),
  [DOWNLOAD_STATUS_PENDING] = @(id) logD($"Download pending: {id}"),
  [DOWNLOAD_STATUS_RUNNING] = @(id) logD($"Download running: {id}"),
  [DOWNLOAD_STATUS_PAUSED] = @(id) logD($"Download paused: {id}"),
  [DOWNLOAD_STATUS_SUCCESSFUL] = function(id) {
    logD("Download successful")
    saveDownloadId(id)
    hasDownloadedApk.set(true)
    isDownloadInProgress.set(false)
  },
  [DOWNLOAD_STATUS_FAILED] = function(id) {
    logerr($"Download failed: {id}")
    isDownloadInProgress.set(false)
  }
}

eventbus_subscribe("android.platform.onCompleteApkDownload", function (event) {
  let { downloadId } = event
  let status = queryDownloadStatus(downloadId)
  logD($"On complete apk download id : {downloadId}, status : {status}")
  customStatusHandlers[status](downloadId)
})

function delayedCheckDownloadStatus() {
  if (isLoggedIn.get() || cachedDownloadId.get() == null)
    return

  let downloadId = cachedDownloadId.get()
  let status = queryDownloadStatus(downloadId)

  logD($"On delayed check for id : {downloadId}, status : {status}")

  cachedDownloadId.set(null)

  if (isDownloadInProgress.get() && status != DOWNLOAD_STATUS_FAILED)
    eventbus_send("exit_for_download_apk", { message = loc("updater/newVersion/exitGame", { actionBtn = loc("msgbox/btn_exit")}) })
  else
    eventbus_send("fMsgBox.onClick.exitAndLinkToStore", null)
}

if (cachedDownloadId.get() != null)
  resetTimeout(TIME_TO_CHECK_DOWNLOAD_STATUS, delayedCheckDownloadStatus)

function downloadAPK() {
  resetTimeout(TIME_TO_CHECK_DOWNLOAD_STATUS, delayedCheckDownloadStatus)

  if (getDownloadedId() != null && queryDownloadStatus(getDownloadedId()) == DOWNLOAD_STATUS_SUCCESSFUL)
    return customStatusHandlers[DOWNLOAD_STATUS_SUCCESSFUL](getDownloadedId())

  if (isDownloadInProgress.get()) {
    logD("Download is already in progress")
    return
  }

  let apkToInstall = getApkName()
  logD($"Available apk name: {apkToInstall}")
  let availableForDownload = actualGameVersion.get()
  logD($"Available for download: {availableForDownload}")

  if (availableForDownload == null) {
    logD("Available for download version is unknown")
    return
  }

  let installedVersion = get_base_game_version_str()
  logD($"Installed version: {installedVersion}")

  if (installedVersion == availableForDownload) {
    logD("No new vesion available")
    return
  }

  let downloadedVersion = getApkFileVersion(apkToInstall)
  logD($"Ready to install version: {downloadedVersion}")

  if (downloadedVersion == availableForDownload) {
    logD("The most recent version is already downloaded")
    hasDownloadedApk.set(true)
    return
  }

  isDownloadInProgress.set(true)

  let downloadId = enqueueDownload(getApkLinkWithHash(actualGameHash.get()), apkToInstall, "Download WTM RC", false, false)
  let status = queryDownloadStatus(downloadId)

  logD($"On start downloading apk / id : {downloadId}, status : {status}, apk name : {apkToInstall}")

  cachedDownloadId.set(downloadId)
  customStatusHandlers[status](downloadId)
}

subscribeFMsgBtns({
  tryToInstallApk = function(_) {
    saveDownloadId(null)
    hasDownloadedApk.set(false)
    tryToInstall(getApkName())
    logD($"On trying install downloaded apk : {getApkName()}")
  }
  markSuggestInstallSeen = @(_) isSuggested.set(true)
  tryToDownloadApkFromSite = @(_) downloadAPK()
})

needShowModal.subscribe(@(v) v ? deferOnce(showSuggestInstallModal) : null)

let canUpdateByConnectionStatus = Computed(function() {
  let statusOpt = isGameAutoUpdateEnabled.get()
  return statusOpt == "allow_always" || (statusOpt == "allow_only_wifi" && !isConnectionLimited.get())
})

return { updateBySite = downloadAPK, isDownloadInProgress, canUpdateByConnectionStatus }
