from "%globalsDarg/darg_library.nut" import *
let { get_base_game_version_str } = require("app")
let { send } = require("eventbus")
let { is_android } = require("%sqstd/platform.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { openFMsgBox, closeFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { check_version } = require("%sqstd/version_compare.nut")
let { isOutOfBattleAndResults } = require("%appGlobals/clientState/clientState.nut")
let { isDownloadedFromGooglePlay } = require("android.platform")
let actualGameVersion = require("actualGameVersion.nut")

const SUGGEST_UPDATE = "suggest_update_msg"

let needExitToUpdate = Computed(function() {
  let { reqVersion = "" } = campConfigs.value?.circuit
  let version = get_base_game_version_str()
  return reqVersion == "" || version == "" ? false : !check_version(reqVersion, version)
})

let shouldCheckHotfixVersion = is_android && !isDownloadedFromGooglePlay()
let needSuggestToUpdate = Computed(function() {
  local actualVersion = actualGameVersion.value
  if (actualVersion == null)
    actualVersion = campConfigs.value?.circuit.actualVersion ?? ""
  else if (shouldCheckHotfixVersion)
    actualVersion = $">={actualVersion}"
  else {
    let parts = actualVersion.split(".")
    if (parts.len() != 4)
      actualVersion = ""
    else {
      parts[parts.len()-1] = "X"
      actualVersion = $">={".".join(parts)}"
    }
  }

  let version = get_base_game_version_str()
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
