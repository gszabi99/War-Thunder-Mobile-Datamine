from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_common_local_settings_blk
from "console" import register_command
from "dagor.workcycle" import resetTimeout
from "eventbus" import eventbus_send
from "%appGlobals/clientState/clientState.nut" import isDownloadedFromSite
from "%appGlobals/pServer/campaign.nut" import firstLoginTime
from "%appGlobals/permissions.nut" import allow_apk_update
from "%appGlobals/userstats/serverTimeDay.nut" import serverTimeDay, getDay, dayOffset
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/mainMenu/mainMenuState.nut" import isInMenuNoModals
from "%rGui/options/options/gameAutoUpdateOption.nut" import isGameAutoUpdateEnabled, AU_NOT_ALLOW,
  AU_ALLOW_ONLY_WIFI, AU_ALLOW_ALWAYS


const SAVE_ID = "isGameAutoUpdateAsked"
let isAsked = Watched(get_common_local_settings_blk()?[SAVE_ID] ?? false)

isAsked.subscribe(function(v) {
  get_common_local_settings_blk()[SAVE_ID] = v
  eventbus_send("saveProfile", {})
})

let needShowMessage = !isDownloadedFromSite ? Watched(false)
  : keepref(Computed(@() !isAsked.get()
      && allow_apk_update.get()
      && isInMenuNoModals.get()
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