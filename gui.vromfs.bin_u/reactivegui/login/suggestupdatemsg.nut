from "%globalsDarg/darg_library.nut" import *
let { get_base_game_version_str } = require("app")
let { send } = require("eventbus")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { check_version } = require("%sqstd/version_compare.nut")
let { isOutOfBattleAndResults } = require("%appGlobals/clientState/clientState.nut")
let actualGameVersion = require("actualGameVersion.nut")

let needExitToUpdate = Computed(function() {
  let { reqVersion = "" } = campConfigs.value?.circuit
  let version = get_base_game_version_str()
  return reqVersion == "" || version == "" ? false : !check_version(reqVersion, version)
})

let needSuggestToUpdate = Computed(function() {
  let actualVersion = actualGameVersion.value
    ?? campConfigs.value?.circuit.actualVersion
    ?? ""
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

needShowSuggestToUpdate.subscribe(@(v) !v ? null
  : openFMsgBox({
      text = loc("msg/updateAvailable/optional")
      isPersist = true
      buttons = [
        { id = "cancel", isCancel = true }
        { text = loc("ugm/btnUpdate"), eventId = "exitGameForUpdate", styleId = "PRIMARY", isDefault = true }
      ]
    }))
