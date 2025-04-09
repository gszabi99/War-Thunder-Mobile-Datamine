from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { questsBySection } = require("%rGui/quests/questsState.nut")
let { activeUnlocks } = require("%rGui/unlocks/unlocks.nut")

let prevProgress = keepref(hardPersistWatched("prevProgress", null))

function getTreeEventQuests() {
  let res = {}
  foreach (name, u in activeUnlocks.get()) {
    let { event_id = null, tree_quest = false } = u?.meta
    if (tree_quest && event_id != null) {
      if (event_id not in res)
        res[event_id] <- {}
      res[event_id][name] <- u
    }
  }
  return res
}

let savePrevProgress = function() {
  let res = {}
  foreach (section in {}.__merge(questsBySection.get(), getTreeEventQuests()))
    foreach (id, quest in section)
      res[id] <- quest.current
  prevProgress.set(res)
}

let resetPrevProgress = @() prevProgress.set(null)

function calcQuestProgressDiffAndSend(questsBySectionV) {
  let prevValues = prevProgress.get()
  if (prevValues == null)
    return
  resetPrevProgress()

  let res = {}
  foreach (section in {}.__merge(questsBySectionV, getTreeEventQuests()))
    foreach (id, quest in section) {
      let previous = prevValues?[id]
      if (previous != null && quest.current > previous)
        res[id] <- quest.__merge({ _previous = previous })
    }
  eventbus_send("BattleResultQuestProgressDiff", res.len() ? res : null)
}

isInBattle.subscribe(@(v) v ? savePrevProgress() : null)
questsBySection.subscribe(@(v) calcQuestProgressDiffAndSend(v))
