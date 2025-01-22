from "%globalsDarg/darg_library.nut" import *
let { is_android, is_pc } = require("%sqstd/platform.nut")
let contentUpdater = is_android ? require("contentUpdaterAndroid") : null
if (contentUpdater == null && !is_pc)
  return

let { eventbus_send } = require("eventbus")
let { get_common_local_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { updater_worker_restart = @(_) false, updater_worker_stop = @() false } = contentUpdater
let { isBackgroundUpdateEnabled } = require("%rGui/options/options/backgroundUpdateOption.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")


let UPDATE_INTERVAL_MIN = 5
let SAVE_ID = "backgroundContentUpdaterState"

let isAsked = Watched(get_common_local_settings_blk()?[SAVE_ID] ?? false)

isAsked.subscribe(function(v) {
  get_common_local_settings_blk()[SAVE_ID] = v
  eventbus_send("saveProfile", {})
})

let updater_worker_restart_with_time = @() updater_worker_restart(UPDATE_INTERVAL_MIN)
let doAction = @(isEnabled) isEnabled ? updater_worker_restart_with_time() : updater_worker_stop()

if (isAsked.get())
  doAction(isBackgroundUpdateEnabled.get())
isBackgroundUpdateEnabled.subscribe(@(v) isAsked.get() ? doAction(v)
  : openMsgBox({
      text = loc("msg/updateBackground")
      buttons = [
        { id = "cancel", isCancel = true,
          function cb() {
            isAsked.set(true)
            isBackgroundUpdateEnabled.set(false)
            updater_worker_stop()
          }
        }
        { id = "download", styleId = "PRIMARY", isDefault = true,
          function cb() {
            isAsked.set(true)
            updater_worker_restart_with_time()
          }
        }
      ]
    }))
register_command(@() isAsked.set(false), "ui.resetBackgroundContentUpdater")