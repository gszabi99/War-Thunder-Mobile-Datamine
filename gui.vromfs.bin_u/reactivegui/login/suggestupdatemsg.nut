from "%globalsDarg/darg_library.nut" import *
let { get_game_version_str } = require("app")
let { send } = require("eventbus")
let { is_ios, is_android } = require("%sqstd/platform.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { openFMsgBox, subscribeFMsgBtns } = require("%appGlobals/openForeignMsgBox.nut")
let { check_version } = require("%sqstd/version_compare.nut")
let { isOutOfBattleAndResults } = require("%appGlobals/clientState/clientState.nut")

let updateUrl = is_ios ? "https://apps.apple.com/us/app/war-thunder-mobile/id1577525428"
  : is_android ? "https://play.google.com/console/u/0/developers/5621070044383975821/app/4975398800615320917/"
  : "https://apps.apple.com/us/app/war-thunder-mobile/id1577525428"

subscribeFMsgBtns({
  updateGame = @(_) send("openUrl", { baseUrl = updateUrl })
})

let needExitToUpdate = Computed(function() {
  let { reqVersion = "" } = campConfigs.value?.circuit
  let version = get_game_version_str()
  return reqVersion == "" || version == "" ? false : !check_version(reqVersion, version)
})

let needSuggestToUpdate = Computed(function() {
  let { actualVersion = "" } = campConfigs.value?.circuit
  let version = get_game_version_str()
  return actualVersion == "" || version == "" ? false : !check_version(actualVersion, version)
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
    buttons = updateUrl == null
      ? [{ id = "exit", eventId = "loginExitGame", isPrimary = true, isDefault = true }]
      : [{ text = loc("ugm/btnUpdate"), eventId = "updateGame", isPrimary = true, isDefault = true }]
  })
})

needShowSuggestToUpdate.subscribe(@(v) !v ? null
  : openFMsgBox({
      text = loc("msg/updateAvailable/optional")
      isPersist = true
      buttons = updateUrl == null ? null
        : [
            { id = "cancel", isCancel = true }
            { text = loc("ugm/btnUpdate"), eventId = "updateGame", isPrimary = true, isDefault = true }
          ]
    }))
