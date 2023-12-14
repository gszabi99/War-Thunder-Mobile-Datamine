from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { questsBySection } = require("%rGui/quests/questsState.nut")

let prevProgress = keepref(hardPersistWatched("prevProgress", null))

let savePrevProgress = function() {
  let res = {}
  foreach (section in questsBySection.get())
    foreach (id, quest in section)
      res[id] <- quest.current
  prevProgress.set(res)
}

let resetPrevProgress = @() prevProgress.set(null)

let function calcQuestProgressDiffAndSend(questsBySectionV) {
  let prevValues = prevProgress.get()
  if (prevValues == null)
    return
  resetPrevProgress()

  let res = {}
  foreach (section in questsBySectionV)
    foreach (id, quest in section) {
      let previous = prevValues?[id]
      if (previous != null && quest.current > previous)
        res[id] <- quest.__merge({ _previous = previous })
    }
  send("BattleResultQuestProgressDiff", res.len() ? res : null)
}

isInBattle.subscribe(@(v) v ? savePrevProgress() : null)
questsBySection.subscribe(@(v) calcQuestProgressDiffAndSend(v))
