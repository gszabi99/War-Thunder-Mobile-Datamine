from "dagor.workcycle" import resetTimeout
from "eventbus" import eventbus_send
from "%appGlobals/clientState/clientState.nut" import isInLoadingScreen
from "%rGui/hudState.nut" import isPlayingReplay


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