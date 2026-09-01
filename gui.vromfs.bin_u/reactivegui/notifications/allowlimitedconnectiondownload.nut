from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_per_machine_custom_blk
from "console" import register_command
from "dagor.workcycle" import resetTimeout
from "eventbus" import eventbus_send
from "%appGlobals/clientState/clientState.nut" import isInMenu
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/updater/updaterState.nut" import allowLimitedDownload, isDownloadPausedByConnection, isDownloadPaused


const SAVE_ID = "isLimitedDownloadAsked"
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
