from "%globalsDarg/darg_library.nut" import *
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { hasVip } = require("%rGui/state/profilePremium.nut")
let { campaignActiveUnlocks, allUnlocksDesc, unlockTables, unlockProgress } = require("%rGui/unlocks/unlocks.nut")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { showAdsForReward, isProviderInited  } = require("%rGui/ads/adsState.nut")
let { playSound } = require("sound_wt")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { speed_up_unlock_progress } = require("%appGlobals/pServer/pServerApi.nut")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")
let adBudget = require("%rGui/ads/adBudget.nut")
let { specialEvents, MAIN_EVENT_ID } = require("%rGui/event/eventState.nut")
let { getUnlockRewardsViewInfo, isSingleViewInfoRewardEmpty } = require("%rGui/rewards/rewardViewInfo.nut")

let EVENT_PREFIX = "day"
let SEEN_QUESTS = "seenQuests"
let COMMON_TAB = "common"
let EVENT_TAB = MAIN_EVENT_ID
let PROMO_TAB = "promo"
let ACHIEVEMENTS_TAB = "achievements"
let PERSONAL_TAB = "personal"
let DAILY_SECTION = "daily_quest"
let WEEKLY_SECTION = "weekly_quest"
let PERSONAL_META_MARK = "personal"

let SPEED_UP_AD_COST = 1

let seenQuests = mkWatched(persist, SEEN_QUESTS, {})
let isQuestsOpen = mkWatched(persist, "isQuestsOpen", false)
let rewardsList = Watched(null)
let isRewardsQuestFinished = Watched(false)
let isRewardsListOpen = Computed(@() rewardsList.get() != null)
let curTabId = Watched(null)
let curTabParams = Watched({})

let tutorialSectionId = Watched(null)
let isSameTutorialSectionId = Watched(false)

function openRewardsList(rewards, isQuestFinished = false) {
  rewardsList.set(rewards)
  isRewardsQuestFinished.set(isQuestFinished)
}
function closeRewardsList() {
  rewardsList.set(null)
  isRewardsQuestFinished.set(false)
}

let mkEventSectionName = @(day, eventName) "".concat(eventName, "_", EVENT_PREFIX, day)

let inactiveEventUnlocks = Computed(@() allUnlocksDesc.get()
  .filter(@(u) u?.meta.event_day != null && !(unlockTables.get()?[u?.table] ?? false))
  .map(@(u, id) u.__merge(unlockProgress.get()?[id] ?? {})))

let eventUnlocksByDays = Computed(function() {
  let days = {}
  let unlocks = {}.__merge(campaignActiveUnlocks.get(), inactiveEventUnlocks.get())
  foreach (name, u in unlocks) {
    let { event_day = null, event_id = null } = u?.meta
    if (!event_id || !event_day)
      continue
    if (event_id not in days)
      days[event_id] <- {}
    days[event_id][event_day] <- (days[event_id]?[event_day] ?? {}).__update({ [name] = u })
  }
  return days
})

let eventDays = Computed(function(prev) {
  let res = {}
  foreach (key, event in eventUnlocksByDays.get())
    res[key] <- event.keys().sort(@(a, b) a.tointeger() <=> b.tointeger())
  return isEqual(prev, res) ? prev : res
})

let eventSections = Computed(function() {
  let res = {}
  foreach (eventName, days in eventDays.get())
    res[eventName] <- days.map(@(v) {
      name = mkEventSectionName(v, eventName)
      idx = v
    })
  return res
})

let sectionMetaMarks = [DAILY_SECTION, WEEKLY_SECTION, "promo_quest", "achievement", PERSONAL_META_MARK]

let questsCfg = Computed(@() {
  [COMMON_TAB] = [DAILY_SECTION, WEEKLY_SECTION],
  [PROMO_TAB] = ["promo_quest"],
  [EVENT_TAB] = eventSections.get()?[EVENT_TAB].map(@(v) v.name) ?? [EVENT_TAB],
  [ACHIEVEMENTS_TAB] = ["achievement"],
  [PERSONAL_TAB] = [PERSONAL_META_MARK]
}.__merge(specialEvents.get().reduce(@(res, v)
    res.__update({ [v.eventId] = eventSections.get()?[v.eventName].map(@(q) q.name) ?? [v.eventName] }), {})))

let sectionsCfg = Computed(function() {
  let res = {
    [DAILY_SECTION] = loc("userlog/battletask/type/daily"),
    [WEEKLY_SECTION] = loc("quests/weekly")
  }
  foreach (cfg in eventSections.get())
    res.__update(cfg.reduce(function(acc, v) {
      acc[v.name] <- loc("enumerated_day", { number = v.idx })
      return acc
    }, {}))
  return res
})

let questsBySection = Computed(function() {
  let res = {}
  foreach (sections in questsCfg.get())
    foreach (section in sections)
      res[section] <- {}

  foreach (name, u in campaignActiveUnlocks.get())
    if (u?.meta.event_id in res)
      res[u.meta.event_id][name] <- u
    else
      foreach (section in sectionMetaMarks)
        if (section in u?.meta)
          res[section][name] <- u

  foreach (eventName, unlocks in eventUnlocksByDays.get())
    res.__update(unlocks.reduce(function(acc, v, key) {
      acc[mkEventSectionName(key, eventName)] <- v
      return acc
    }, {}))
  return res
})

let progressUnlockByTab = Computed(function() {
  let res = {}
  foreach(unlock in campaignActiveUnlocks.get())
    if ("event_progress" in unlock?.meta) {
      let { event_id = MAIN_EVENT_ID } = unlock.meta
      let key = event_id == MAIN_EVENT_ID || event_id == "" ? EVENT_TAB
        : specialEvents.get().findindex(@(e) e.eventName == event_id)
      if (key != null)
        res[key] <- unlock
    }
  return res
})

let progressUnlockBySection = Computed(@() {
  [DAILY_SECTION] = campaignActiveUnlocks.get().findvalue(@(unlock) "daily_progress" in unlock?.meta),
  [WEEKLY_SECTION] = campaignActiveUnlocks.get().findvalue(@(unlock) "weekly_progress" in unlock?.meta)
})

let tutorialSectionIdWithReward = Computed(@() questsCfg.get()?[EVENT_TAB]
  .findvalue(@(section) null != questsBySection.get()?[section].findvalue(@(r) r.hasReward)))

function getQuestCurrenciesInTab(tabId, qCfg, qBySection, pUnlockBySection, pUnlockByTab, statsTables, sConfigs) {
  let res = []
  foreach (idx, s in qCfg?[tabId] ?? []) {
    foreach (quest in qBySection[s].values().append(
      pUnlockBySection?[s],
      idx == 0 ? pUnlockByTab?[tabId] : null
    ).filter(@(v) v)) {
      let { currency = null } = statsTables?.stats[quest.table].rerollPrice
      if (currency != null && !res.contains(currency))
        res.append(currency)
      let stage = quest.stages?[quest.stage] ?? quest.stages?[quest.stages.len() - 1]
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

let mkHasReceivedAllRewards = @(item, rewardsPreview) Computed(function() {
  if (item.get()?.isFinished)
    return true
  let rPreview = rewardsPreview.get()
  local countReceivedR = 0
  foreach (r in rPreview)
    countReceivedR += isSingleViewInfoRewardEmpty(r, servProfile.get()) ?  1 : 0
  return countReceivedR == rPreview.len()
})

function saveSeenQuests(ids) {
  seenQuests.mutate(function(v) {
    foreach (id in ids)
      v[id] <- true
  })
  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk.addBlock(SEEN_QUESTS)
  foreach (id, isSeen in seenQuests.get())
    if (isSeen)
      blk[id] = true
  eventbus_send("saveProfile", {})
}

function loadSeenQuests() {
  if (!isSettingsAvailable.get())
    return seenQuests.set({})
  let blk = get_local_custom_settings_blk()
  let htBlk = blk?[SEEN_QUESTS]
  if (!isDataBlock(htBlk)) {
    seenQuests.set({})
    return
  }
  let res = {}
  eachParam(htBlk, @(isSeen, id) res[id] <- isSeen)
  seenQuests.set(res)
}

if (seenQuests.get().len() == 0)
  loadSeenQuests()

isSettingsAvailable.subscribe(@(_) loadSeenQuests())

let hasUnseenQuestsBySection = Computed(@() questsBySection.get().map(@(quests)
  null != quests.findindex(@(v, id) id not in inactiveEventUnlocks.get() && (id not in seenQuests.get() || v.hasReward))))

let saveSeenQuestsForSection = @(sectionId) !hasUnseenQuestsBySection.get()?[sectionId] ? null
  : saveSeenQuests(questsBySection.get()?[sectionId].filter(@(v) !v.hasReward).keys())

function openQuestsWnd() {
  if (isOfflineMenu) {
    openFMsgBox({ text = "Not supported in the offline mode" })
    return
  }
  isQuestsOpen.set(true)
}

function openQuestsWndOnTab(tabId) {
  isQuestsOpen.set(false)
  curTabId.set(tabId)
  openQuestsWnd()
}

function onWatchQuestAd(unlock) {
  let { name, progressCorrectionStep = 0, isCompleted = false } = unlock
  if (adBudget.get() < SPEED_UP_AD_COST) {
    openMsgBox({ text = loc("msg/adsLimitReached") })
    return false
  }

  if (hasVip.get()) {
    speed_up_unlock_progress(name)
    return true
  }

  if (!isProviderInited.get()) {
    let locId = "shop/notAvailableAds"
    openMsgBox({ text = loc(locId) })
    sendErrorLocIdBqEvent(locId)
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
  seenQuests.set({})
  get_local_custom_settings_blk().removeBlock(SEEN_QUESTS)
  eventbus_send("saveProfile", {})
}, "debug.reset_seen_quests")

return {
  openQuestsWnd
  openQuestsWndOnTab
  openEventQuestsWnd = openQuestsWndOnTab
  isQuestsOpen

  rewardsList
  isRewardsQuestFinished
  isRewardsListOpen
  openRewardsList
  closeRewardsList

  curTabId
  curTabParams
  questsBySection

  seenQuests
  saveSeenQuests
  hasUnseenQuestsBySection
  saveSeenQuestsForSection

  questsCfg
  sectionsCfg
  inactiveEventUnlocks
  progressUnlockByTab
  progressUnlockBySection
  getQuestCurrenciesInTab

  tutorialSectionIdWithReward
  tutorialSectionId
  isSameTutorialSectionId

  mkHasReceivedAllRewards

  COMMON_TAB
  EVENT_TAB
  PROMO_TAB
  ACHIEVEMENTS_TAB
  PERSONAL_TAB

  DAILY_SECTION

  onWatchQuestAd
  SPEED_UP_AD_COST
}
