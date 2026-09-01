from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_send
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import prevIfEqual
from "%appGlobals/clientState/clientState.nut" import isInBattle, isInDebriefing
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/event/eventLocName.nut" import getSpecialEventRewardUnitName
from "%rGui/event/eventState.nut" import specialEventsOrdered
import "%rGui/event/shouldShowEventMechanics.nut" as shouldShowEventMechanics
from "%rGui/quests/questsState.nut" import questsBySection, progressUnlockByTab, saveSeenQuests
from "%rGui/shop/shopState.nut" import allShopGoods
from "%rGui/unlocks/unlocks.nut" import activeUnlocks
from "%rGui/unlocks/unlocksConst.nut" import MAIN_EVENT_ID


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

let sectionsWithoutEvents = [ "promo_quest", "achievement" ].totable()

function savePrevProgress() {
  let res = {}
  foreach (sId, section in {}.__merge(questsBySection.get(), getTreeEventQuests()))
    if (shouldShowEventMechanics.get() || sId in sectionsWithoutEvents)
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

function mkSpecialEventRewardUnitName(quest) {
  let { event_id = "" } = quest?.meta
  if (event_id == "" || event_id == MAIN_EVENT_ID)
    return ""
  let { locId } = getEventPresentation(event_id)
  if (!loc(locId).contains("{name}")) 
    return ""
  let { eventId = "" } = specialEventsOrdered.get().findvalue(@(v) v.eventName == event_id)
  let { stages = [] } = progressUnlockByTab.get()?[eventId]
  return getSpecialEventRewardUnitName(stages, serverConfigs.get(), allShopGoods.get())
}

let questProgressDiff = keepref(Computed(function(prev) {
  let prevValues = prevProgress.get()
  if (prevValues == null)
    return null

  let res = {}
  foreach (section in {}.__merge(questsBySection.get(), getTreeEventQuests()))
    foreach (id, quest in section) {
      let previous = prevValues?[id]
      if (previous != null && quest.current > previous) {
        let extraParams = { _previous = previous }
        let specialEventRewardUnitName = mkSpecialEventRewardUnitName(quest)
        if (specialEventRewardUnitName != "")
          extraParams._specialEventRewardUnitName <- specialEventRewardUnitName
        res[id] <- quest.__merge(extraParams)
      }
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
