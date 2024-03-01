from "%globalsDarg/darg_library.nut" import *
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { activeUnlocks, allUnlocksRaw, unlockTables, unlockProgress } = require("%rGui/unlocks/unlocks.nut")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { canShowAds, showAdsForReward, showNotAvailableAdsMsg } = require("%rGui/ads/adsState.nut")
let { playSound } = require("sound_wt")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { speed_up_unlock_progress } = require("%appGlobals/pServer/pServerApi.nut")
let adBudget = require("%rGui/ads/adBudget.nut")
let { specialEvents, MAIN_EVENT_ID, curEvent, getSpecialEventName } = require("%rGui/event/eventState.nut")
let { getUnlockRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")


let EVENT_PREFIX = "day"
let SEEN_QUESTS = "seenQuests"
let COMMON_TAB = "common"
let EVENT_TAB = MAIN_EVENT_ID
let PROMO_TAB = "promo"
let MINI_EVENT_TAB = "miniEvent"
let ACHIEVEMENTS_TAB = "achievements"
let SPECIAL_EVENT_1_TAB = getSpecialEventName(1)

let SPEED_UP_AD_COST = 1

let seenQuests = mkWatched(persist, SEEN_QUESTS, {})
let isQuestsOpen = mkWatched(persist, "isQuestsOpen", false)
let rewardsList = Watched(null)
let isRewardsListOpen = Computed(@() rewardsList.value != null)
let curTabId = Watched(null)
let curTabParams = Watched({})

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
  [ACHIEVEMENTS_TAB] = ["achievement"],
}.__merge(specialEvents.value.reduce(@(res, v)
  res.__update({ [v.eventId] = [v.eventName] }), {})))

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
      res[section] <- activeUnlocks.value.filter(@(u) section in u?.meta || u?.meta.event_id == section) ?? {}
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
  daily_quest = activeUnlocks.get().findvalue(@(unlock) "daily_progress" in unlock?.meta)
  weekly_quest = activeUnlocks.get().findvalue(@(unlock) "weekly_progress" in unlock?.meta)
})

function getQuestCurrenciesInTab(tabId, qCfg, qBySection, pUnlockBySection, pUnlockByTab, sConfigs) {
  let res = []
  foreach (idx, s in qCfg?[tabId] ?? []) {
    foreach (quest in qBySection[s].values().append(
      pUnlockBySection?[s],
      idx == 0 ? pUnlockByTab?[tabId] : null
    ).filter(@(v) v)) {
      let stage = quest.stages?[quest.stage]
      if (stage != null){
        if ((stage?.price ?? 0) > 0 && !res.contains(stage?.currencyCode) && !quest?.isCompleted)
          res.append(stage?.currencyCode)
        foreach (reward in getUnlockRewardsViewInfo(stage, sConfigs)){
          if (reward.rType == "currency" && !res.contains(reward.id))
            res.append(reward.id)
        }
      }
    }
  }
  return res
}

function saveSeenQuests(ids) {
  seenQuests.mutate(function(v) {
    foreach (id in ids)
      v[id] <- true
  })
  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk.addBlock(SEEN_QUESTS)
  foreach (id, isSeen in seenQuests.value)
    if (isSeen)
      blk[id] = true
  eventbus_send("saveProfile", {})
}

function loadSeenQuests() {
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

function openQuestsWnd() {
  if (isOfflineMenu) {
    openFMsgBox({ text = "Not supported in the offline mode" })
    return
  }
  isQuestsOpen(true)
}

function openQuestsWndOnTab(tabId) {
  isQuestsOpen(false)
  curTabId(tabId)
  openQuestsWnd()
}

function onWatchQuestAd(unlock) {
  let { name, progressCorrectionStep = 0, isCompleted = false } = unlock
  if (adBudget.value == 0) {
    openMsgBox({ text = loc("playBattlesToUnlockAds") })
    return false
  }
  if (!canShowAds.value) {
    showNotAvailableAdsMsg()
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

eventbus_subscribe("adsRewardApply", function(data) {
  if ("speedUpUnlockId" in data)
    speed_up_unlock_progress(data.speedUpUnlockId)
})

register_command(function() {
  seenQuests({})
  get_local_custom_settings_blk().removeBlock(SEEN_QUESTS)
  eventbus_send("saveProfile", {})
}, "debug.reset_seen_quests")

return {
  openQuestsWnd
  openQuestsWndOnTab
  openEventQuestsWnd = @() openQuestsWndOnTab(curEvent.value)
  isQuestsOpen

  rewardsList
  isRewardsListOpen
  openRewardsList
  closeRewardsList

  curTabId
  curTabParams
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
  getQuestCurrenciesInTab

  COMMON_TAB
  EVENT_TAB
  MINI_EVENT_TAB
  PROMO_TAB
  ACHIEVEMENTS_TAB
  SPECIAL_EVENT_1_TAB

  onWatchQuestAd
  SPEED_UP_AD_COST
}
