from "%globalsDarg/darg_library.nut" import *
let { is_replay_present, on_save_replay } = require("replays")
let { isInBattle, isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")

let isReplaySaved = mkWatched(persist, "isSaved", false)
let isReplayPresent = Watched(is_replay_present())
let hasUnsavedReplay = Computed(@() isReplayPresent.value && !isReplaySaved.value)

isInBattle.subscribe(function(_) {
  isReplaySaved(false)
  isReplayPresent(is_replay_present())
})
isInLoadingScreen.subscribe(@(_) isReplayPresent(is_replay_present()))

function saveLastReplay(name) {
  let isSuccess = on_save_replay(name)
  openFMsgBox({
    text = isSuccess ? loc("replay/save_success") : loc("replays/save_error")
  })
  if (isSuccess)
    isReplaySaved(true)
  return isSuccess
}

return {
  hasUnsavedReplay
  saveLastReplay
}