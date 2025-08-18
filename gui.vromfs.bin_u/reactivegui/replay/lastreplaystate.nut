from "%globalsDarg/darg_library.nut" import *
let { is_replay_present, on_save_replay } = require("replays")
let { isInBattle, isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")

let isReplaySaved = mkWatched(persist, "isSaved", false)
let isReplayPresent = Watched(is_replay_present())
let hasUnsavedReplay = Computed(@() isReplayPresent.get() && !isReplaySaved.get())

isInBattle.subscribe(function(_) {
  isReplaySaved.set(false)
  isReplayPresent.set(is_replay_present())
})
isInLoadingScreen.subscribe(@(_) isReplayPresent.set(is_replay_present()))

function saveLastReplay(name) {
  let isSuccess = on_save_replay(name)
  openFMsgBox({
    text = isSuccess ? loc("replay/save_success") : loc("replays/save_error")
  })
  if (isSuccess)
    isReplaySaved.set(true)
  return isSuccess
}

return {
  hasUnsavedReplay
  saveLastReplay
}