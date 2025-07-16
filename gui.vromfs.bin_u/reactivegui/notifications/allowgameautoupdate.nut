from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { resetTimeout } = require("dagor.workcycle")
let { get_common_local_settings_blk } = require("blkGetters")
let { allow_apk_update } = require("%appGlobals/permissions.nut")
let { firstLoginTime } = require("%appGlobals/pServer/campaign.nut")
let { isInMenu, isDownloadedFromSite } = require("%appGlobals/clientState/clientState.nut")
let { serverTimeDay, getDay, dayOffset } = require("%appGlobals/userstats/serverTimeDay.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { isGameAutoUpdateEnabled, AU_NOT_ALLOW, AU_ALLOW_ONLY_WIFI, AU_ALLOW_ALWAYS
} = require("%rGui/options/options/gameAutoUpdateOption.nut")


let SAVE_ID = "isGameAutoUpdateAsked"
let isAsked = Watched(get_common_local_settings_blk()?[SAVE_ID] ?? false)

isAsked.subscribe(function(v) {
  get_common_local_settings_blk()[SAVE_ID] = v
  eventbus_send("saveProfile", {})
})

let needShowMessage = keepref(Computed(@() isDownloadedFromSite
  && !isAsked.get()
  && allow_apk_update.get()
  && isInMenu.get()
  && isGameAutoUpdateEnabled.get() == AU_NOT_ALLOW
  && (serverTimeDay.get() - getDay(firstLoginTime.get(), dayOffset.get())) > 0))

function openMessageIfNeed() {
  if (!needShowMessage.get())
    return
  openMsgBox({
    text = loc("msg/allowGameAutoUpdate")
    buttons = [
      { id = "cancel", isCancel = true, cb = @() isAsked.set(true) }
      { id = "allow_wifi", styleId = "PRIMARY", cb = @() isGameAutoUpdateEnabled.set(AU_ALLOW_ONLY_WIFI) }
      { id = "allow", styleId = "PRIMARY", cb = @() isGameAutoUpdateEnabled.set(AU_ALLOW_ALWAYS) }
    ]
  })
}

if (isGameAutoUpdateEnabled.get() != AU_NOT_ALLOW)
  isAsked.set(true)
isGameAutoUpdateEnabled.subscribe(@(v) v != AU_NOT_ALLOW ? isAsked.set(true) : null)

resetTimeout(0.2, openMessageIfNeed)
needShowMessage.subscribe(@(v) !v ? null : resetTimeout(0.2, openMessageIfNeed))
register_command(@() isAsked.set(false), "ui.resetGameAutoUpdateMessage")