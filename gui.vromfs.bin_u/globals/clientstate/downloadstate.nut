from "blkGetters" import get_local_custom_settings_blk
from "math" import clamp
from "%sqstd/globalState.nut" import hardPersistWatched


const MB = 1 << 20
const ALLOW_LIMITED_DOWNLOAD_SAVE_ID = "allowLimitedConnectionDownload"

let downloadState = hardPersistWatched("updater.downloadState", null)
let totalSizeBytes = hardPersistWatched("updater.totalSizeBytes", 0)
let toDownloadSizeBytes = hardPersistWatched("updater.toDownloadSizeBytes", 0)
let downloadInProgress = hardPersistWatched("updater.downloadInProgress", {})
let allowLimitedDownload = hardPersistWatched("updater.allowLimitedDownload",
  get_local_custom_settings_blk()?[ALLOW_LIMITED_DOWNLOAD_SAVE_ID] ?? false)

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