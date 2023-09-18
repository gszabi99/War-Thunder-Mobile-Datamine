from "%globalsDarg/darg_library.nut" import *
let { get_base_game_version_str } = require("app")
let { send } = require("eventbus")
let { is_ios } = require("%sqstd/platform.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { openFMsgBox, closeFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { check_version } = require("%sqstd/version_compare.nut")
let { isOutOfBattleAndResults } = require("%appGlobals/clientState/clientState.nut")
let { isDownloadedFromGooglePlay } = require("android.platform")
let { needSuggestToUpdate } = isDownloadedFromGooglePlay() ? require("needUpdate/needUpdateGooglePlay.nut")
  : is_ios ? require("needUpdate/needUpdateAppStore.nut")
  : require("needUpdate/needUpdateAndroidSite.nut")

const SUGGEST_UPDATE = "suggest_update_msg"

let needExitToUpdate = Computed(function() {
  let { reqVersion = "" } = campConfigs.value?.circuit
  let version = get_base_game_version_str()
  return reqVersion == "" || version == "" ? false : !check_version(reqVersion, version)
})

let needShowExitToUpdate = keepref(Computed(@() needExitToUpdate.value && isOutOfBattleAndResults.value))
let needShowSuggestToUpdate = keepref(Computed(@() needSuggestToUpdate.value
  && !needExitToUpdate.value && isOutOfBattleAndResults.value))

needShowExitToUpdate.subscribe(function(v) {
  if (!v)
    return

  send("logOut", {})
  openFMsgBox({
    text = loc("msg/updateAvailable/mandatory")
    isPersist = true
    buttons = [{ text = loc("ugm/btnUpdate"), eventId = "exitGameForUpdate", styleId = "PRIMARY", isDefault = true }]
  })
})

let function updateSuggestState(isActive) {
  if (isActive)
    openFMsgBox({
      uid = SUGGEST_UPDATE
      text = loc("msg/updateAvailable/optional")
      isPersist = true
      buttons = [
        { id = "cancel", isCancel = true }
        { text = loc("ugm/btnUpdate"), eventId = "exitGameForUpdate", styleId = "PRIMARY", isDefault = true }
      ]})
  else
    closeFMsgBox(SUGGEST_UPDATE)
}

needShowSuggestToUpdate.subscribe(updateSuggestState)
updateSuggestState(needShowSuggestToUpdate.value)
