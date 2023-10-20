from "%globalsDarg/darg_library.nut" import *
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { activeUnlocks, allUnlocksRaw, unlockTables, unlockProgress } = require("%rGui/unlocks/unlocks.nut")
let { send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { isEqual } = require("%sqstd/underscore.nut")

const EVENT_PREFIX = "day"
const SEEN_QUESTS = "seenQuests"
const COMMON_TAB = "common"
const EVENT_TAB = "event"
const PROMO_TAB = "promo"

let seenQuests = mkWatched(persist, SEEN_QUESTS, {})
let isQuestsOpen = mkWatched(persist, "isQuestsOpen", false)
let rewardsList = Watched(null)
let isRewardsListOpen = Computed(@() rewardsList.value != null)
let curSectionId = Watched(null)
let curTabId = Watched(null)

let openRewardsList = @(rewards) rewardsList(rewards)
let closeRewardsList = @() rewardsList(null)

let mkEventSectionName = @(day) "".concat(EVENT_PREFIX, day)

let inactiveEventUnlocks = Computed(@() allUnlocksRaw.value
  .filter(@(u) u?.meta.event_day != null && !(unlockTables.value?[u?.table] ?? false))
  .map(@(u, id) u.__merge(unlockProgress.value?[id] ?? {})))

let eventUnlocksByDays = Computed(function() {
  let days = {}
  let unlocks = {}.__merge(activeUnlocks.value, inactiveEventUnlocks.value)
  foreach (name, u in unlocks) {
    let day = u?.meta.event_day
    if (u?.meta.event_quest && day != null)
      days[day] <- (days?[day] ?? {}).__update({ [name] = u })
  }
  return days
})

let isEventActive = Computed(@() eventUnlocksByDays.value.len() != 0)

let eventDays = Computed(function(prev) {
  let res = eventUnlocksByDays.value.keys()
    .sort(@(a, b) a.tointeger() <=> b.tointeger())
  return isEqual(prev, res) ? prev : res
})

let eventSections = Computed(@() eventDays.value.map(@(v) {
  name = mkEventSectionName(v)
  idx = v
}))

let questsCfg = Computed(@() {
  [COMMON_TAB] = ["daily_quest", "weekly_quest"],
  [PROMO_TAB] = ["promo_quest"],
  [EVENT_TAB] = eventSections.value.map(@(v) v.name)
})

let sectionsCfg = Computed(@() {
  daily_quest = {
    text = loc("userlog/battletask/type/daily")
    timerId = "daily"
  }
  weekly_quest = {
    text = loc("quests/weekly")
    timerId = "weekly"
  }
}.__update(eventSections.value.reduce(function(res, v) {
  res[v.name] <- {
    text = loc("enumerated_day", { number = v.idx }),
    timerId = v.name
  }
  return res
}, {})))

let questsBySection = Computed(function() {
  let res = {}
  foreach (sections in questsCfg.value)
    foreach (section in sections)
      res[section] <- activeUnlocks.value.filter(@(u) section in u?.meta) ?? {}
  res.__update(eventUnlocksByDays.value.reduce(function(acc, v, key) {
    acc[mkEventSectionName(key)] <- v
    return acc
  }, {}))
  return res
})

let isCurSectionInactive = Computed(@() !unlockTables.value?[curSectionId.value]
  && questsCfg.value?[EVENT_TAB].findindex(@(v) v == curSectionId.value) != null)

let progressUnlock = Computed(@() activeUnlocks.value.findvalue(@(unlock) "event_progress" in unlock?.meta))

let function saveSeenQuests(ids) {
  seenQuests.mutate(function(v) {
    foreach (id in ids)
      v[id] <- true
  })
  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk.addBlock(SEEN_QUESTS)
  foreach (id, isSeen in seenQuests.value)
    if (isSeen)
      blk[id] = true
  send("saveProfile", {})
}

let function loadSeenQuests() {
  let blk = get_local_custom_settings_blk()
  let htBlk = blk?[SEEN_QUESTS]
  if (!isDataBlock(htBlk)) {
    seenQuests({})
    return
  }
  let res = {}
  eachParam(htBlk, @(isSeen, id) res[id] <- isSeen)
  seenQuests(res)
}

if (seenQuests.value.len() == 0)
  loadSeenQuests()

let hasUnseenQuestsBySection = Computed(@() questsBySection.value.map(@(quests)
  null != quests.findindex(@(v, id) (id not in seenQuests.value && id not in inactiveEventUnlocks.value) || v.hasReward)))

let saveSeenQuestsCurSection = @() !hasUnseenQuestsBySection.value?[curSectionId.value] ? null
  : saveSeenQuests(questsBySection.value?[curSectionId.value].filter(@(v) !v.hasReward).keys())

let function onSectionChange(id) {
  saveSeenQuestsCurSection()
  curSectionId(id)
}

let function openQuestsWnd() {
  if (isOfflineMenu) {
    openFMsgBox({ text = "Not supported in the offline mode" })
    return
  }
  isQuestsOpen(true)
}

let function openEventQuestsWnd() {
  isQuestsOpen(false)
  curTabId(EVENT_TAB)
  openQuestsWnd()
}

register_command(function() {
  seenQuests({})
  get_local_custom_settings_blk().removeBlock(SEEN_QUESTS)
  send("saveProfile", {})
}, "debug.reset_seen_quests")

return {
  openQuestsWnd
  openEventQuestsWnd
  isQuestsOpen

  rewardsList
  isRewardsListOpen
  openRewardsList
  closeRewardsList

  curSectionId
  curTabId
  questsBySection
  onSectionChange
  isCurSectionInactive

  seenQuests
  hasUnseenQuestsBySection
  saveSeenQuestsCurSection

  questsCfg
  sectionsCfg
  eventUnlocksByDays
  inactiveEventUnlocks
  isEventActive
  progressUnlock

  COMMON_TAB
  EVENT_TAB
  PROMO_TAB
}
