let { clamp } = require("math")
let { get_local_custom_settings_blk } = require("blkGetters")
let sharedWatched = require("%globalScripts/sharedWatched.nut")


let MB = 1 << 20
let ALLOW_LIMITED_DOWNLOAD_SAVE_ID = "allowLimitedConnectionDownload"

let downloadState = sharedWatched("updater.downloadState", @() null)
let totalSizeBytes = sharedWatched("updater.totalSizeBytes", @() 0)
let toDownloadSizeBytes = sharedWatched("updater.toDownloadSizeBytes", @() 0)
let downloadInProgress = sharedWatched("updater.downloadInProgress", @() {})
let allowLimitedDownload = sharedWatched("updater.allowLimitedDownload",
  @() get_local_custom_settings_blk()?[ALLOW_LIMITED_DOWNLOAD_SAVE_ID] ?? false)

let getDownloadLeftMbNotUpdatable = @()
  toDownloadSizeBytes.get() * (1.0 - 0.01 * clamp(downloadState.get()?.percent ?? 0, 0, 100)) / MB

return {
  downloadInProgress
  downloadState
  totalSizeBytes
  toDownloadSizeBytes

  ALLOW_LIMITED_DOWNLOAD_SAVE_ID
  allowLimitedDownload

  getDownloadLeftMbNotUpdatable
}