from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { get_per_machine_custom_blk } = require("blkGetters")
let { register_command } = require("console")
let { eventbus_send } = require("eventbus")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { allowLimitedDownload, isDownloadPausedByConnection, isDownloadPaused } = require("%rGui/updater/updaterState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")

let SAVE_ID = "isLimitedDownloadAsked"
let isAsked = Watched(get_per_machine_custom_blk()?[SAVE_ID] ?? false)

isAsked.subscribe(function(v) {
  get_per_machine_custom_blk()[SAVE_ID] = v
  eventbus_send("saveProfile", {})
})

let needShowMessage = keepref(Computed(@() !isAsked.get()
  && isInMenu.get()
  && !isDownloadPaused.get()
  && isDownloadPausedByConnection.get()))

function openMessageIfNeed() {
  if (!needShowMessage.get())
    return
  openMsgBox({
    text = loc("msg/allowMobileNetworkDownload")
    buttons = [
      { id = "cancel", isCancel = true, cb = @() isAsked.set(true) }
      { id = "download", styleId = "PRIMARY", isDefault = true,
        function cb() {
          isAsked.set(true)
          allowLimitedDownload.set(true)
        }
      }
    ]
  })
}

resetTimeout(0.2, openMessageIfNeed)
needShowMessage.subscribe(@(v) !v ? null : resetTimeout(0.2, openMessageIfNeed))
register_command(@() isAsked.set(false), "ui.resetLimitedDownloadMessage")
