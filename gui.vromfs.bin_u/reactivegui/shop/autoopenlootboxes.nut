from "%globalsDarg/darg_library.nut" import *
let { lootboxInProgress, open_lootbox, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let ERROR_UPDATE_DELAY = 60
let wasErrorSoon = Watched(false)

let lootboxes = Computed(function() {
  let { lootboxesCfg = {} } = serverConfigs.value
  return (servProfile.value?.lootboxes ?? {}).filter(@(v, id) v > 0 && id in lootboxesCfg)
})

let canOpen = Computed(@() !isInBattle.value && lootboxInProgress.value == null && !wasErrorSoon.value)

let idToOpen = keepref(Computed(@() canOpen.value ? lootboxes.value.findindex(@(_) true) : null))

registerHandler("onAutoOpenLootbox", @(res) res?.error == null ? null : wasErrorSoon(true))

let function tryOpen() {
  if (idToOpen.value != null)
    open_lootbox(idToOpen.value, "onAutoOpenLootbox")
}
tryOpen()
idToOpen.subscribe(@(_) deferOnce(tryOpen))

let resetError = @() wasErrorSoon(false)
wasErrorSoon.subscribe(@(v) v ? resetTimeout(ERROR_UPDATE_DELAY, resetError) : null)