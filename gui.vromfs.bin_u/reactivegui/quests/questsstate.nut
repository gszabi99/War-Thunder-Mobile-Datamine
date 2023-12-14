from "%globalsDarg/darg_library.nut" import *
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { activeUnlocks, allUnlocksRaw, unlockTables, unlockProgress } = require("%rGui/unlocks/unlocks.nut")
let { send, subscribe } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { canShowAds, showAdsForReward } = require("%rGui/ads/adsState.nut")
let { playSound } = require("sound_wt")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { speed_up_unlock_progress } = require("%appGlobals/pServer/pServerApi.nut")
let adBudget = require("%rGui/ads/adBudget.nut")

const EVENT_PREFIX = "day"
const SEEN_QUESTS = "seenQuests"
const COMMON_TAB = "common"
const EVENT_TAB = "event"
const PROMO_TAB = "promo"
const MINI_EVENT_TAB = "miniEvent"
const ACHIEVEMENTS_TAB = "achievements"

let SPEED_UP_AD_COST = 1

let seenQuests = mkWatched(persist, SEEN_QUESTS, {})
let isQuestsOpen = mkWatched(persist, "isQuestsOpen", false)
let rewardsList = Watched(null)
let isRewardsListOpen = Computed(@() rewardsList.value != null)
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
  [EVENT_TAB] = eventSections.value.map(@(v) v.name),
  [MINI_EVENT_TAB] = ["mini_event"],
  [ACHIEVEMENTS_TAB] = ["achievement"]
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

let progressUnlockByTab = Computed(@() {
  [EVENT_TAB] = activeUnlocks.get().findvalue(@(unlock) "event_progress" in unlock?.meta),
})

let progressUnlockBySection = Computed(@() {
  daily_quest = activeUnlocks.get()?.daily_quest_global_progress
  weekly_quest = activeUnlocks.get()?.weekly_quest_global_progress
})

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

let saveSeenQuestsForSection = @(sectionId) !hasUnseenQuestsBySection.value?[sectionId] ? null
  : saveSeenQuests(questsBySection.value?[sectionId].filter(@(v) !v.hasReward).keys())

let function openQuestsWnd() {
  if (isOfflineMenu) {
    openFMsgBox({ text = "Not supported in the offline mode" })
    return
  }
  isQuestsOpen(true)
}

let function openQuestsWndOnTab(tabId) {
  isQuestsOpen(false)
  curTabId(tabId)
  openQuestsWnd()
}

let function onWatchQuestAd(unlock) {
  let { name, progressCorrectionStep = 0, isCompleted = false } = unlock
  if (adBudget.value == 0) {
    openMsgBox({ text = loc("playBattlesToUnlockAds") })
    return false
  }
  if (!canShowAds.value) {
    openMsgBox({ text = loc("msg/adsNotReadyYet") })
    return false
  }

  if (progressCorrectionStep > 0 && !isCompleted) {
    playSound("meta_ad_button")
    showAdsForReward({ speedUpUnlockId = name, bqId = $"unlock_{name}" })
    return true
  }

  logerr($"Trying to show ads to speed up the unlock which is completed or does not support speed up")
  return false
}

subscribe("adsRewardApply", function(data) {
  if ("speedUpUnlockId" in data)
    speed_up_unlock_progress(data.speedUpUnlockId)
})

register_command(function() {
  seenQuests({})
  get_local_custom_settings_blk().removeBlock(SEEN_QUESTS)
  send("saveProfile", {})
}, "debug.reset_seen_quests")

return {
  openQuestsWnd
  openQuestsWndOnTab
  openEventQuestsWnd = @() openQuestsWndOnTab(EVENT_TAB)
  isQuestsOpen

  rewardsList
  isRewardsListOpen
  openRewardsList
  closeRewardsList

  curTabId
  questsBySection

  seenQuests
  hasUnseenQuestsBySection
  saveSeenQuestsForSection

  questsCfg
  sectionsCfg
  eventUnlocksByDays
  inactiveEventUnlocks
  progressUnlockByTab
  progressUnlockBySection

  COMMON_TAB
  EVENT_TAB
  MINI_EVENT_TAB
  PROMO_TAB
  ACHIEVEMENTS_TAB

  onWatchQuestAd
  SPEED_UP_AD_COST
}
