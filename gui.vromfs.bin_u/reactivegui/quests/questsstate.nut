from "%globalsDarg/darg_library.nut" import *
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { eventSectionOrder } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { hasVip } = require("%rGui/state/profilePremium.nut")
let { isUserstatMissingData } = require("%rGui/unlocks/userstat.nut")
let { campaignActiveUnlocks, allUnlocksDesc, unlockTables, unlockTablesSeasons, isSeasonPast, unlockProgress,
  emptyProgress, setLastSeenUnlocks, unseenUnlocks, getUnlockAllRewardCurrencies, getAllUnlockCurrencies
} = require("%rGui/unlocks/unlocks.nut")
let { EVENT_PREFIX, COMMON_TAB, EVENT_TAB, PROMO_TAB, ACHIEVEMENTS_TAB, PERSONAL_TAB, DAILY_SECTION, WEEKLY_SECTION,
  PERSONAL_META_MARK, SPEED_UP_AD_COST
} = require("%rGui/unlocks/unlocksConst.nut")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { prevIfEqual } = require("%sqstd/underscore.nut")
let { showAdsForReward, isProviderInited  } = require("%rGui/ads/adsState.nut")
let { playSound } = require("sound_wt")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { speed_up_unlock_progress } = require("%appGlobals/pServer/pServerApi.nut")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")
let adBudget = require("%rGui/ads/adBudget.nut")
let { specialEvents, MAIN_EVENT_ID } = require("%rGui/event/eventState.nut")
let { isSingleViewInfoRewardEmpty } = require("%rGui/rewards/rewardViewInfo.nut")
let { sendBqQuestsReceiveTask } = require("%rGui/quests/bqQuests.nut")


let SEEN_QUESTS = "seenQuests"

let isQuestsAttached = mkWatched(persist, "isQuestsAttached", false)
let rewardsList = Watched(null)
let isRewardsQuestFinished = Watched(false)
let isRewardsListOpen = Computed(@() rewardsList.get() != null)
let tabIdToOpen = Watched(null)
let curTabId = Watched(null)
let curTabParams = Watched({})

let tutorialSectionId = Watched(null)
let isSameTutorialSectionId = Watched(false)
let tutorialQuestBtnKey = Watched(null)

function openRewardsList(rewards, isQuestFinished = false) {
  rewardsList.set(rewards)
  isRewardsQuestFinished.set(isQuestFinished)
}
function closeRewardsList() {
  rewardsList.set(null)
  isRewardsQuestFinished.set(false)
}

let mkEventSectionName = @(day, eventName) "".concat(eventName, "_", EVENT_PREFIX, day)
let mkEventNamedSectionName = @(section, eventName) "".concat(eventName, "_", EVENT_PREFIX, "section_", section)

let inactiveEventUnlocks = Computed(@() allUnlocksDesc.get()
  .filter(@(u) (u?.meta.event_day != null || (u?.meta.section ?? "") != "")
    && !(unlockTables.get()?[u?.table] ?? false)
    && !isSeasonPast(u, unlockTablesSeasons.get()))
  .map(@(u, id) u.__merge(unlockProgress.get()?[id] ?? emptyProgress)))

let eventUnlocksBySection = Computed(function() {
  let res = {}
  let unlocks = {}.__merge(campaignActiveUnlocks.get(), inactiveEventUnlocks.get())
  foreach (name, unlock in unlocks) {
    let { event_id = null, event_day = null, section = null } = unlock?.meta
    if (event_id == null)
      continue
    let sectionId = event_day != null ? mkEventSectionName(event_day, event_id)
      : (section ?? "") != "" ? mkEventNamedSectionName(section, event_id)
      : null
    if (sectionId == null)
      continue
    getSubTable(getSubTable(res, event_id), sectionId)[name] <- unlock
  }
  return res
})

let eventSections = Computed(function(prev) {
  let res = {}
  foreach (eventId, sections in eventUnlocksBySection.get()) {
    let descs = sections.keys().map(function(sectionId) {
      let unlocks = sections[sectionId]
      let { event_day = null, section = null } = unlocks[unlocks.keys()[0]]?.meta
      return event_day != null
        ? {
            name = sectionId
            sortDay = event_day.tointeger()
            section = null
            title = loc("enumerated_day", { number = event_day })
          }
        : { name = sectionId, sortDay = null, section, title = loc($"quests/{section}") }
    })
    descs.sort(@(a, b) (a.sortDay != null) <=> (b.sortDay != null)
      || a.sortDay <=> b.sortDay
      || (eventSectionOrder?[a.section] ?? 1) <=> (eventSectionOrder?[b.section] ?? 1)
      || a.section <=> b.section)

    res[eventId] <- descs
  }
  return prevIfEqual(prev, res)
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
  foreach (descs in eventSections.get())
    foreach (d in descs)
      res[d.name] <- d.title
  return res
})

let questsBySection = Computed(function() {
  let res = {}
  foreach (sections in questsCfg.get())
    foreach (section in sections)
      res[section] <- {}

  foreach (name, u in campaignActiveUnlocks.get())
    if (u?.meta.event_progress)
      continue
    else {
      let eventId = u?.meta.event_id
      if (eventId in res)
        res[eventId][name] <- u
      else
        foreach (section in sectionMetaMarks)
          if (section in u?.meta)
            res[section][name] <- u
    }
  foreach (sections in eventUnlocksBySection.get())
    foreach (sectionId, unlocks in sections)
      res[sectionId] <- unlocks
  return res
})

let progressUnlockByTab = Computed(function() {
  let res = {}
  foreach(unlock in campaignActiveUnlocks.get())
    if ("event_progress" in unlock?.meta) {
      let { event_id = MAIN_EVENT_ID } = unlock.meta
      let key = event_id == MAIN_EVENT_ID ? EVENT_TAB
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

let getStarsTotalNonUpdatable = @(unlock) (
  progressUnlockByTab.get()?[unlock?.tabId] ?? progressUnlockBySection.get()?[unlock?.sectionId]
)?.current ?? 0

let tutorialSectionIdWithReward = Computed(@() questsCfg.get()?[EVENT_TAB]
  .findvalue(@(section) null != questsBySection.get()?[section].findvalue(@(r) r.hasReward)))

function getQuestCurrenciesInTab(tabId, qCfg, qBySection, pUnlockBySection, pUnlockByTab, statsTables, sConfigs) {
  let currencies = {}
  if (tabId in pUnlockByTab)
    currencies.__update(getAllUnlockCurrencies(pUnlockByTab[tabId], sConfigs, statsTables))
  qCfg?[tabId].each(function(s) {
    if (s in pUnlockBySection)
      currencies.__update(getAllUnlockCurrencies(pUnlockBySection[s], sConfigs, statsTables))
    qBySection?[s].each(@(q) currencies.__update(getAllUnlockCurrencies(q, sConfigs, statsTables)))
  })
  return currencies.keys()
}

function getQuestNextRewardCurrenciesInTab(tabId, qCfg, qBySection, pUnlockBySection, pUnlockByTab, sConfigs) {
  let currencies = {}
  if (tabId in pUnlockByTab)
    currencies.__update(getUnlockAllRewardCurrencies(pUnlockByTab[tabId], sConfigs))
  qCfg?[tabId].each(function(s) {
    if (s in pUnlockBySection)
      currencies.__update(getUnlockAllRewardCurrencies(pUnlockBySection[s], sConfigs))
    qBySection?[s].each(@(q) currencies.__update(getUnlockAllRewardCurrencies(q, sConfigs)))
  })
  return currencies
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

function moveSeenQuestsFromCloudToUserstat() { 
  if (!isSettingsAvailable.get() || isUserstatMissingData.get())
    return

  let blk = get_local_custom_settings_blk()
  let htBlk = blk?[SEEN_QUESTS]
  if (!isDataBlock(htBlk))
    return

  let res = {}
  eachParam(htBlk, @(isSeen, id) isSeen ? res[id] <- isSeen : null)
  if (res.len() == 0) {
    blk.removeBlock(SEEN_QUESTS)
    return
  }

  setLastSeenUnlocks(res.keys())
  blk.removeBlock(SEEN_QUESTS)
  eventbus_send("saveProfile", {})
}

moveSeenQuestsFromCloudToUserstat()
isSettingsAvailable.subscribe(@(v) v ? moveSeenQuestsFromCloudToUserstat() : null)
isUserstatMissingData.subscribe(@(v) v ? null : moveSeenQuestsFromCloudToUserstat())

function saveSeenQuests(names) {
  foreach (unlockName in names) {
    let unlock = allUnlocksDesc.get()?[unlockName]
    if ((unlock?.personal ?? "") != "" && unlockName in unseenUnlocks.get())
      sendBqQuestsReceiveTask(unlock)
  }

  setLastSeenUnlocks(names)
}

let hasUnseenQuestsBySection = Computed(@() questsBySection.get().map(@(quests)
  null != quests.findindex(@(v, id) id not in inactiveEventUnlocks.get() && (id in unseenUnlocks.get() || v.hasReward))))

let saveSeenQuestsForSection = @(sectionId) !hasUnseenQuestsBySection.get()?[sectionId] ? null
  : saveSeenQuests(questsBySection.get()?[sectionId].filter(@(v) !v.hasReward).keys())

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


return {
  isQuestsAttached

  rewardsList
  isRewardsQuestFinished
  isRewardsListOpen
  openRewardsList
  closeRewardsList

  tabIdToOpen
  curTabId
  curTabParams
  questsBySection

  unseenUnlocks
  saveSeenQuests
  hasUnseenQuestsBySection
  saveSeenQuestsForSection

  questsCfg
  sectionsCfg
  inactiveEventUnlocks
  progressUnlockByTab
  progressUnlockBySection
  getQuestCurrenciesInTab
  getQuestNextRewardCurrenciesInTab

  tutorialSectionIdWithReward
  tutorialSectionId
  isSameTutorialSectionId
  tutorialQuestBtnKey

  mkHasReceivedAllRewards

  getStarsTotalNonUpdatable

  COMMON_TAB
  EVENT_TAB
  PROMO_TAB
  ACHIEVEMENTS_TAB
  PERSONAL_TAB

  DAILY_SECTION

  onWatchQuestAd
  SPEED_UP_AD_COST
}
