from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { prevIfEqual } = require("%sqstd/underscore.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInBattle, isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { questsBySection, saveSeenQuests } = require("%rGui/quests/questsState.nut")
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

function trySendQuestProgressDiff(diff) {
  if (diff == null)
    return
  saveSeenQuests(diff.keys())
  eventbus_send("BattleResultQuestProgressDiff", diff.len() == 0 ? null
    : diff.map(function(v) {
        let res = clone v
        res.$rawdelete("$prog")
        res.$rawdelete("$desc")
        return res
      }))
}

let questProgressDiff = keepref(Computed(function(prev) {
  let prevValues = prevProgress.get()
  if (prevValues == null)
    return null

  let res = {}
  foreach (section in {}.__merge(questsBySection.get(), getTreeEventQuests()))
    foreach (id, quest in section) {
      let previous = prevValues?[id]
      if (previous != null && quest.current > previous)
        res[id] <- quest.__merge({ _previous = previous })
    }
  return prevIfEqual(prev, res)
}))

trySendQuestProgressDiff(questProgressDiff.get())

isInBattle.subscribe(@(v) v ? savePrevProgress() : null)
isInDebriefing.subscribe(@(v) v ? null : resetPrevProgress())
questProgressDiff.subscribe(function(v) {
  this_subscriber_call_may_take_up_to_usec(10 * get_slow_subscriber_threshold_usec())
  trySendQuestProgressDiff(v)
})
