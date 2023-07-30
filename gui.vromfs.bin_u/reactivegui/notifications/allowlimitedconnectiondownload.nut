from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { allowLimitedDownload, isDownloadPausedByConnection, isDownloadPaused } = require("%rGui/updater/updaterState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")

let SAVE_ID = "isLimitedDownloadAsked"
let isAsked = Watched(get_local_custom_settings_blk()?[SAVE_ID] ?? false)

isAsked.subscribe(function(v) {
  get_local_custom_settings_blk()[SAVE_ID] = v
})

let needShowMessage = keepref(Computed(@() !isAsked.value
  && isInMenu.value
  && !isDownloadPaused.value
  && isDownloadPausedByConnection.value))

let function openMessageIfNeed() {
  if (!needShowMessage.value)
    return
  openMsgBox({
    text = loc("msg/allowMobileNetworkDownload")
    buttons = [
      { id = "no", isCancel = true, cb = @() isAsked(true) }
      { id = "yes", isPrimary = true, isDefault = true,
        function cb() {
          isAsked(true)
          allowLimitedDownload(true)
        }
      }
    ]
  })
}

resetTimeout(0.2, openMessageIfNeed)
needShowMessage.subscribe(@(v) !v ? null : resetTimeout(0.2, openMessageIfNeed))
register_command(@() isAsked(false), "ui.resetLimitedDownloadMessage")
