from "%globalsDarg/darg_library.nut" import *
let logD = log_with_prefix("[DOWNLOAD] ")
let { deferOnce } = require("dagor.workcycle")
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { enqueueDownload, queryDownloadStatus, tryToInstall, getApkFileVersion = null, DOWNLOAD_STASUS_UNKNOWN,
  DOWNLOAD_STATUS_PENDING, DOWNLOAD_STATUS_RUNNING, DOWNLOAD_STATUS_PAUSED, DOWNLOAD_STATUS_SUCCESSFUL,
  DOWNLOAD_STATUS_FAILED } = require("android.platform")
  let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { OPT_AUTO_UPDATE_ENABLED, getOptValue } = require("%rGui/options/guiOptions.nut")
let { openFMsgBox, subscribeFMsgBtns } = require("%appGlobals/openForeignMsgBox.nut")
let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isTutorialActive } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { actualGameVersion, actualGameHash, getApkLinkWithCash } = require("needUpdate/needUpdateAndroidSite.nut")
let { get_base_game_version_str } = require("app")

let isSuggested = hardPersistWatched("suggestInstall.isSuggested", false)
let SUGGEST_INSTALL_APK = "suggestInstallApk"
let DOWNLOAD_SUCCESSFUL_BY_SITE = "downloadSuccessfulBySite"
let getApkName = @() $"wtm_production_{actualGameVersion.get()}.apk"

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
  customStatusHandlers[status](downloadId)
})

function downloadAPK() {
  if (getDownloadedId() != null && queryDownloadStatus(getDownloadedId()) == DOWNLOAD_STATUS_SUCCESSFUL)
    return customStatusHandlers[DOWNLOAD_STATUS_SUCCESSFUL](getDownloadedId())

  if (isDownloadInProgress.get()) {
    logD("Download is already in progress")
    return
  }

  let apkToInstall = getApkName()
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

  let downloadedVersion = getApkFileVersion?(apkToInstall)
  logD($"Ready to install version: {downloadedVersion}")

  if (downloadedVersion == null || downloadedVersion == availableForDownload) {
    logD("The most recent version is already downloaded")
    hasDownloadedApk.set(true)
    return
  }

  isDownloadInProgress.set(true)

  let downloadId = enqueueDownload(getApkLinkWithCash(actualGameHash.get()), apkToInstall, "Download WTM RC", false, false)
  let status = queryDownloadStatus(downloadId)

  customStatusHandlers[status](downloadId)
}

subscribeFMsgBtns({
  tryToInstallApk = function(_) {
    saveDownloadId(null)
    hasDownloadedApk.set(false)
    tryToInstall(getApkName())
  }
  markSuggestInstallSeen = @(_) isSuggested.set(true)
  tryToDownloadApkFromSite = @(_) downloadAPK()
})

needShowModal.subscribe(@(v) v ? deferOnce(showSuggestInstallModal) : null)

let updateBySite = @() getOptValue(OPT_AUTO_UPDATE_ENABLED) ? downloadAPK() : null

return { updateBySite, isDownloadInProgress }
