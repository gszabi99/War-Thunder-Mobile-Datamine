from "%globalsDarg/darg_library.nut" import *
from "android.platform" import enqueueDownload, queryDownloadStatus, tryToInstall, requestApkFileVersion,
  DOWNLOAD_STATUS_PENDING, DOWNLOAD_STATUS_RUNNING, DOWNLOAD_STATUS_PAUSED, DOWNLOAD_STATUS_SUCCESSFUL,
  DOWNLOAD_STATUS_FAILED
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
const SAVED_DOWNLOAD_BLK = "downloadSuccessfulBySite" 
const TIME_TO_CHECK_DOWNLOAD_STATUS = 2
const DOWNLOAD_DESCRIPTION = "Download WTM RC"
let getApkName = @() $"wtm_{apkTag}_{actualGameVersion.get()}.apk"

let hasDownloadedApk = hardPersistWatched("suggestInstall.hasDownloadedApk", false)
let isDownloadInProgress = hardPersistWatched("suggestInstall.isDownloadInProgress", false)
let checkedDownloadId = hardPersistWatched("suggestInstall.checkedDownloadId", null)
let checkedApkName = hardPersistWatched("suggestInstall.checkedApkName", null)
let exitCheckDownloadId = hardPersistWatched("suggestInstall.exitCheckDownloadId", null)

let needShowModal = keepref(Computed(@() !hasModalWindows.get()
  && !isDownloadInProgress.get()
  && !isInLoadingScreen.get()
  && !isTutorialActive.get()
  && !isSuggested.get()
  && hasDownloadedApk.get()
  && isMainMenuAttached.get()
  && isLoggedIn.get()))

let getSavedDownload = @() get_local_custom_settings_blk()?[SAVED_DOWNLOAD_BLK]

function saveDownload(downloadId, apkName) {
  let blk = get_local_custom_settings_blk()
  blk.removeBlock(SAVED_DOWNLOAD_BLK)
  if (apkName != null) {
    let saved = blk.addBlock(SAVED_DOWNLOAD_BLK)
    saved["apkName"] <- apkName
    saved["downloadId"] <- downloadId
  }
  eventbus_send("saveProfile", {})
}

let clearSavedDownload = @() saveDownload(null, null)

let showSuggestInstallModal = @() openFMsgBox({
  uid = SUGGEST_INSTALL_APK
  isPersist = true
  text = loc("msg/updateDownloaded/successfully")
  buttons = [
    { text = loc("ugm/btnDelay"), eventId = "markSuggestInstallSeen", isCancel = true }
    { text = loc("ugm/btnInstall"), eventId = "tryToInstallApk", styleId = "PRIMARY", isDefault = true }
  ]})

function onDownloadSuccessful(downloadId) {
  logD($"Download successful: {downloadId}")
  hasDownloadedApk.set(true)
  isDownloadInProgress.set(false)
}

function onDownloadFailed(downloadId) {
  logerr($"Download failed: {downloadId}")
  if (getSavedDownload()?.downloadId == downloadId)
    clearSavedDownload()
  isDownloadInProgress.set(false)
}

function delayedCheckDownloadStatus() {
  if (isLoggedIn.get() || cachedDownloadId.get() == null)
    return

  exitCheckDownloadId.set(cachedDownloadId.get())
  cachedDownloadId.set(null)
  queryDownloadStatus(exitCheckDownloadId.get())
}

if (cachedDownloadId.get() != null)
  resetTimeout(TIME_TO_CHECK_DOWNLOAD_STATUS, delayedCheckDownloadStatus)

function startDownload() {
  isDownloadInProgress.set(true)
  enqueueDownload(getApkLinkWithHash(actualGameHash.get()), getApkName(), DOWNLOAD_DESCRIPTION, false, false)
}

function checkApkFile(apkName) {
  checkedApkName.set(apkName)
  requestApkFileVersion(apkName)
}

function checkSavedDownload(downloadId) {
  checkedDownloadId.set(downloadId)
  queryDownloadStatus(downloadId)
}

eventbus_subscribe("android.platform.onCompleteApkDownload", function(evt) {
  let { downloadId } = evt
  logD($"On complete apk download id : {downloadId}")
  queryDownloadStatus(downloadId)
})

eventbus_subscribe("android.platform.onDownloadStatus", function(evt) {
  let { downloadId, status } = evt
  logD($"Download status / id : {downloadId}, status : {status}")

  if (downloadId == exitCheckDownloadId.get()) {
    exitCheckDownloadId.set(null)
    if (isDownloadInProgress.get() && status != DOWNLOAD_STATUS_FAILED)
      eventbus_send("exit_for_download_apk", { message = loc("updater/newVersion/exitGame", { actionBtn = loc("msgbox/btn_exit")}) })
    else
      eventbus_send("fMsgBox.onClick.exitAndLinkToStore", null)
  }

  if (downloadId == checkedDownloadId.get()) {
    checkedDownloadId.set(null)
    if ([DOWNLOAD_STATUS_PENDING, DOWNLOAD_STATUS_RUNNING, DOWNLOAD_STATUS_PAUSED].contains(status)) {
      cachedDownloadId.set(downloadId)
      isDownloadInProgress.set(true)
    }
    else {
      clearSavedDownload()
      checkApkFile(getApkName())
    }
  }
  else if (status == DOWNLOAD_STATUS_SUCCESSFUL)
    onDownloadSuccessful(downloadId)
  else if (status == DOWNLOAD_STATUS_FAILED)
    onDownloadFailed(downloadId)
})

eventbus_subscribe("android.platform.onApkFileVersion", function(evt) {
  let { fileName, version = null } = evt
  if (fileName != checkedApkName.get())
    return

  checkedApkName.set(null)
  logD($"Ready to install version: {version}")
  if (version != null && version == actualGameVersion.get()) {
    logD("The most recent version is already downloaded")
    saveDownload(null, fileName)
    hasDownloadedApk.set(true)
    return
  }
  startDownload()
})

eventbus_subscribe("android.platform.onEnqueueDownload", function(evt) {
  let { fileName, downloadId } = evt
  logD($"On start downloading apk / id : {downloadId}, apk name : {fileName}")
  if (downloadId < 0) {
    logerr($"Download enqueue failed: {fileName}")
    isDownloadInProgress.set(false)
    return
  }
  cachedDownloadId.set(downloadId)
  saveDownload(downloadId, fileName)
  resetTimeout(TIME_TO_CHECK_DOWNLOAD_STATUS, delayedCheckDownloadStatus)
})

function downloadAPK() {
  resetTimeout(TIME_TO_CHECK_DOWNLOAD_STATUS, delayedCheckDownloadStatus)

  if (isDownloadInProgress.get()) {
    logD("Download is already in progress")
    return
  }
  if (checkedDownloadId.get() != null || checkedApkName.get() != null) {
    logD("Download check is already in progress")
    return
  }

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

  let apkName = getApkName()
  logD($"Available apk name: {apkName}")
  let saved = getSavedDownload()
  if (saved?.apkName == apkName && saved?.downloadId != null)
    checkSavedDownload(saved.downloadId)
  else
    checkApkFile(apkName)
}

subscribeFMsgBtns({
  tryToInstallApk = function(_) {
    let apkName = getSavedDownload()?.apkName ?? getApkName()
    clearSavedDownload()
    hasDownloadedApk.set(false)
    tryToInstall(apkName)
    logD($"On trying install downloaded apk : {apkName}")
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
