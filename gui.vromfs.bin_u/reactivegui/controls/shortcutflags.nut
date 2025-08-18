let { isPlayingReplay } = require("%rGui/hudState.nut")
let { eventbus_send } = require("eventbus")
let { resetTimeout } = require("dagor.workcycle")
let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")

let isReplayShortcuts = isPlayingReplay.get()

function reloadVmIfNeed() {
  if (isPlayingReplay.get() != isReplayShortcuts && !isInLoadingScreen.get())
    eventbus_send("reloadDargVM", { msg = "replay shortcuts changed" })
}
isPlayingReplay.subscribe(@(_) resetTimeout(0.1, reloadVmIfNeed))
isInLoadingScreen.subscribe(@(_) resetTimeout(0.1, reloadVmIfNeed))

return {
  isReplayShortcuts
}