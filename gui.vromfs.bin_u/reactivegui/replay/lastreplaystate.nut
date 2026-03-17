from "%globalsDarg/darg_library.nut" import *
let logR = log_with_prefix("[REPLAY] ")
let { is_replay_present, on_save_replay, is_replay_playing } = require("replays")
let { isInBattle, isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")

let isReplaySaved = mkWatched(persist, "isSaved", false)
let needSkipSaveReplay = mkWatched(persist, "needSkipSaveReplay", false)
let isReplayPresent = Watched(is_replay_present())
let hasUnsavedReplay = Computed(@() isReplayPresent.get() && !isReplaySaved.get())

isInBattle.subscribe(function(v) {
  if (v)
    needSkipSaveReplay.set(is_replay_playing())
  else if (!needSkipSaveReplay.get()) {
    isReplaySaved.set(false)
    isReplayPresent.set(is_replay_present())
    logR($"Is replay present: {is_replay_present()}")
  }
})
isInLoadingScreen.subscribe(@(_) isReplayPresent.set(is_replay_present()))
hasUnsavedReplay.subscribe(@(v) logR($"Has Unsaved Replay changed to: {v}"))

function saveLastReplay(name) {
  let isSuccess = on_save_replay(name)
  openFMsgBox({
    text = isSuccess ? loc("replay/save_success") : loc("replays/save_error")
  })
  if (isSuccess) {
    isReplaySaved.set(true)
    logR("Replay saved successfully")
  }
  return isSuccess
}

return {
  hasUnsavedReplay
  saveLastReplay
}