from "%globalsDarg/darg_library.nut" import *
let { get_base_game_version_str } = require("app")
let { eventbus_send } = require("eventbus")
let { isDownloadedFromGooglePlay, getBuildMarket } = require("android.platform")
let isHuaweiBuild = getBuildMarket() == "appgallery"
let { is_ios, is_android } = require("%sqstd/platform.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { openFMsgBox, closeFMsgBox, subscribeFMsgBtns } = require("%appGlobals/openForeignMsgBox.nut")
let { can_view_update_suggestion, allow_apk_update } = require("%appGlobals/permissions.nut")
let { check_version } = require("%sqstd/version_compare.nut")
let { isOutOfBattleAndResults, isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { needSuggestToUpdate } = isHuaweiBuild ? require("needUpdate/needUpdateAppGallery.nut")
  : isDownloadedFromGooglePlay() ? require("needUpdate/needUpdateGooglePlay.nut")
  : is_ios ? require("needUpdate/needUpdateAppStore.nut")
  : require("needUpdate/needUpdateAndroidSite.nut")
let { updateBySite, isDownloadInProgress, canUpdateByConnectionStatus } = require("updateClientBySite.nut")

const SUGGEST_UPDATE = "suggest_update_msg"

let needExitToUpdate = Computed(function() {
  let { reqVersion = "" } = campConfigs.get()?.circuit
  let version = get_base_game_version_str()
  return isInMenu.get() && (reqVersion == "" || version == "" ? false : !check_version(reqVersion, version))
})

let needShowExitToUpdate = keepref(Computed(@() needExitToUpdate.get() && isOutOfBattleAndResults.get()))

let isSuggested = hardPersistWatched("suggestUpdate.isSuggested", false)
let needProcessUpdate = keepref(Computed(@() needSuggestToUpdate.get()
  && can_view_update_suggestion.get()
  && isInMenu.get()
  && !isSuggested.get()
  && !needExitToUpdate.get()
  && isOutOfBattleAndResults.get()))

let isProcessByBgUpdate = is_android && !isDownloadedFromGooglePlay() && !isHuaweiBuild
  ? allow_apk_update
  : Watched(false)

let needSuggestMessage = keepref(Computed(@() needProcessUpdate.get() && !isProcessByBgUpdate.get()))
let needStartBackgroundUpdate = keepref(Computed(@() needProcessUpdate.get()
  && canUpdateByConnectionStatus.get()
  && !isDownloadInProgress.get()
  && isProcessByBgUpdate.get()))

let needSuggestMessageBySite = keepref(Computed(@() needProcessUpdate.get()
  && !isDownloadInProgress.get()
  && isProcessByBgUpdate.get()
  && !canUpdateByConnectionStatus.get()))

needShowExitToUpdate.subscribe(function(v) {
  if (!v)
    return

  eventbus_send("logOut", {})
  openFMsgBox({
    text = loc("msg/updateAvailable/mandatory")
    isPersist = true
    buttons = [{ text = loc("ugm/btnUpdate"), eventId = "exitGameForUpdate", styleId = "PRIMARY", isDefault = true }]
  })
})

subscribeFMsgBtns({
  markSuggestUpdateSeen = @(_) isSuggested(true)
})

function showMsg(isActive) {
  if (isActive)
    openFMsgBox({
      uid = SUGGEST_UPDATE
      text = loc("msg/updateAvailable/optional")
      buttons = [
        { id = "cancel", eventId = "markSuggestUpdateSeen", isCancel = true }
        { text = loc("ugm/btnUpdate"), eventId = "exitGameForUpdate", styleId = "PRIMARY", isDefault = true }
      ]})
  else
    closeFMsgBox(SUGGEST_UPDATE)
}

function showMsgForSite(isActive) {
  if (isActive)
    openFMsgBox({
      uid = SUGGEST_UPDATE
      text = loc("msg/updateAvailable/optional")
      buttons = [
        { id = "cancel", eventId = "markSuggestUpdateSeen", isCancel = true }
        { text = loc("ugm/btnUpdate"), eventId = "tryToDownloadApkFromSite", styleId = "PRIMARY", isDefault = true }
      ]})
  else
    closeFMsgBox(SUGGEST_UPDATE)
}

needStartBackgroundUpdate.subscribe(@(v) v ? updateBySite() : null)
if (needStartBackgroundUpdate.get())
  updateBySite()

needSuggestMessage.subscribe(showMsg)
showMsg(needSuggestMessage.get())

needSuggestMessageBySite.subscribe(showMsgForSite)
showMsgForSite(needSuggestMessageBySite.get())
