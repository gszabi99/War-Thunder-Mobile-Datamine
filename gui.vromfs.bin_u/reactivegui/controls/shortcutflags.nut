let { isPlayingReplay } = require("%rGui/hudState.nut")
let { eventbus_send } = require("eventbus")
let { resetTimeout } = require("dagor.workcycle")
let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")

let isReplayShortcuts = isPlayingReplay.value

function reloadVmIfNeed() {
  if (isPlayingReplay.value != isReplayShortcuts && !isInLoadingScreen.value)
    eventbus_send("reloadDargVM", null)
}
isPlayingReplay.subscribe(@(_) resetTimeout(0.1, reloadVmIfNeed))
isInLoadingScreen.subscribe(@(_) resetTimeout(0.1, reloadVmIfNeed))

return {
  isReplayShortcuts
}