from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "dagor.workcycle" import resetTimeout
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/pServerApi.nut" import registerHandler, get_clan_progress, receive_clan_progress_reward,
  clanProgressInProgress, clanProgressRewardInProgress
from "%appGlobals/pServer/profileSeasons.nut" import curSeasons
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/timeoutExt.nut" import resetExtTimeout, clearExtTimer
from "%appGlobals/userstats/serverTime.nut" import getServerTime, isServerTimeValid
from "%rGui/clans/currentClanState.nut" import NO_CLAN_ID, currentClanId, myClanJoinTime, myClanFastProgressAccess,
  isReadyToConnect, mkIsTimePassed
from "%rGui/unlocks/unlocks.nut" import activeUnlocks, unseenUnlocks
from "%rGui/unlocks/userstat.nut" import userstatStatsTables


const CLAN_QUEST_META = "weekly_clan_quest"
const CLAN_QUESTS_TAB = "clan"
const CLAN_PROGRESS_ID = "weekly"
const CLAN_PROGRESS_STATS_ID = "on_get_clan_progress"
const CLAN_PROGRESS_REWARD_ID = "on_receive_clan_progress_reward"
const STATS_LIFETIME_MS = 60000
const ERROR_RETRY_MS = 60000
const CLAN_QUESTS_JOIN_DELAY_SEC = 86400

let logC = log_with_prefix("[CLAN_PROGRESS] ")

let clanQuests = Computed(@() activeUnlocks.get().filter(@(u) CLAN_QUEST_META in u?.meta))
let clanQuestsEndsAt = Computed(@()
  userstatStatsTables.get()?.stats[clanQuests.get().findvalue(@(_) true)?.table]["$endsAt"] ?? 0)

let clanProgressCfg = Computed(@() serverConfigs.get()?.allClanProgress[CLAN_PROGRESS_ID])
let curClanSeasonIdx = Computed(function() {
  let { idx = -1, isActive = false } = curSeasons.get()?[clanProgressCfg.get()?.season] ?? {}
  return isActive ? idx : -1
})

let lastClanProgress = Computed(@() servProfile.get()?.lastClanProgress[CLAN_PROGRESS_ID])

let clanQuestsUnlockTime = Computed(function() {
  let joinTime = myClanJoinTime.get()
  if (joinTime == null || myClanFastProgressAccess.get())
    return 0
  return joinTime + CLAN_QUESTS_JOIN_DELAY_SEC
})
let isClanQuestsLocked = Watched(true)

function updateClanQuestsLock() {
  if (!isServerTimeValid.get()) {
    isClanQuestsLocked.set(true)
    clearExtTimer(updateClanQuestsLock)
    return
  }
  let timeLeft = clanQuestsUnlockTime.get() - getServerTime()
  isClanQuestsLocked.set(timeLeft > 0)
  if (timeLeft > 0)
    resetExtTimeout(timeLeft, updateClanQuestsLock)
  else
    clearExtTimer(updateClanQuestsLock)
}
updateClanQuestsLock()
clanQuestsUnlockTime.subscribe(@(_) updateClanQuestsLock())
isServerTimeValid.subscribe(@(_) updateClanQuestsLock())
let getLockStateText = @()
  $"joinTime {myClanJoinTime.get()}, unlockTime {clanQuestsUnlockTime.get()}, fastAccess {myClanFastProgressAccess.get()}"

let receivedClanRewards = Computed(@() servProfile.get()?.receivedClanRewards[CLAN_PROGRESS_ID] ?? {})

let clanStatsBySeason = Watched({})
let isStatsOutdated = Watched(true)
let statsErrorTime = Watched(0)
let canRetryStats = mkIsTimePassed(statsErrorTime, ERROR_RETRY_MS)
local statsTime = 0
local progressShowCount = 0
let invalidateStats = @() isStatsOutdated.set(true)

let statsSeasons = Computed(function() {
  let cur = curClanSeasonIdx.get()
  let isInClan = currentClanId.get() != NO_CLAN_ID
  let { seasonIdx = -1, prevSeasonIdx = -1 } = lastClanProgress.get() ?? {}
  return [cur, cur - 1].filter(@(s) s >= 0 && (isInClan || s == seasonIdx || s == prevSeasonIdx))
})

let needRefreshStats = keepref(Computed(@() isStatsOutdated.get() && statsSeasons.get().len() > 0
  && isReadyToConnect.get() && !isInBattle.get()
  && clanProgressInProgress.get().len() == 0 && canRetryStats.get()))

function onStatsExpired() {
  if (progressShowCount > 0)
    invalidateStats()
}

function refreshStats() {
  isStatsOutdated.set(false)
  statsTime = get_time_msec()
  resetTimeout(0.001 * STATS_LIFETIME_MS, onStatsExpired)
  let clanId = currentClanId.get()
  foreach (seasonIdx in statsSeasons.get())
    get_clan_progress(CLAN_PROGRESS_ID, seasonIdx, { id = CLAN_PROGRESS_STATS_ID, seasonIdx, clanId })
}

registerHandler(CLAN_PROGRESS_STATS_ID, function(res, context) {
  if (context.clanId != currentClanId.get())
    return
  if (res?.error != null) {
    logC($"get_clan_progress season {context.seasonIdx} error: {res.error}, {getLockStateText()}")
    statsErrorTime.set(get_time_msec())
    invalidateStats()
    return
  }
  let { clanId = NO_CLAN_ID, clanTotal = 0, myTotal = 0 } = res
  logC($"get_clan_progress season {context.seasonIdx}: clan {clanId}, clan total {clanTotal}, my total {myTotal}, {getLockStateText()}")
  clanStatsBySeason.mutate(@(v) v[context.seasonIdx] <- { clanId, clanTotal, myTotal })
})

function resetStats() {
  clanStatsBySeason.set({})
  statsErrorTime.set(0)
  invalidateStats()
}

currentClanId.subscribe(@(_) resetStats())
curClanSeasonIdx.subscribe(@(_) resetStats())
isLoggedIn.subscribe(@(_) resetStats())

let clanQuestsRewardedStages = keepref(Computed(@() clanQuests.get()
  .reduce(@(res, q) res + (q?.lastRewardedStage ?? 0), 0)))
clanQuestsRewardedStages.subscribe(@(_) invalidateStats())

function startClanProgressRefresh() {
  progressShowCount++
  if (get_time_msec() - statsTime >= STATS_LIFETIME_MS)
    invalidateStats()
}

function stopClanProgressRefresh() {
  progressShowCount--
}

if (needRefreshStats.get())
  refreshStats()
needRefreshStats.subscribe(@(v) v ? refreshStats() : null)

function mkSeasonProgress(seasonIdx, isPrevSeason, stages, stats, received) {
  let { clanId = NO_CLAN_ID, clanTotal = 0, myTotal = 0 } = stats ?? {}
  let isEligible = clanId != NO_CLAN_ID && myTotal > 0
  let receivedCount = stages.findindex(@(s) s.value > received) ?? stages.len()
  return {
    name = $"clan_progress_{CLAN_PROGRESS_ID}"
    stages = stages.map(@(s) { progress = s.value, rewards = s.rewards })
    current = clanTotal
    stage = receivedCount + 1
    hasReward = isEligible && (stages?[receivedCount].value ?? (clanTotal + 1)) <= clanTotal
    isLocked = !isEligible
    seasonIdx
    isPrevSeason
    clanId
  }
}

let clanProgress = Computed(function() {
  let stages = clanProgressCfg.get()?.stages
  let cur = curClanSeasonIdx.get()
  if (stages == null || cur < 0)
    return null
  let stats = clanStatsBySeason.get()
  let received = receivedClanRewards.get()
  let mkProgress = @(idx) mkSeasonProgress(idx, idx != cur, stages, stats?[idx], received?[idx.tostring()] ?? 0)
  let prevProgress = mkProgress(cur - 1)
  if (prevProgress.hasReward)
    return prevProgress
  let curProgress = mkProgress(cur)
  return (curProgress.clanId != NO_CLAN_ID || prevProgress.clanId == NO_CLAN_ID) ? curProgress : prevProgress
})

let hasClanProgressReward = Computed(@() clanProgressRewardInProgress.get() == null
  && (clanProgress.get()?.hasReward ?? false))

let hasClanQuestsUnseen = Computed(@() hasClanProgressReward.get()
  || (currentClanId.get() != NO_CLAN_ID && !isClanQuestsLocked.get()
    && null != clanQuests.get().findindex(@(q, id) q.hasReward || id in unseenUnlocks.get())))

function receiveClanProgressReward(progress, idx) {
  let { seasonIdx, stages } = progress
  receive_clan_progress_reward(CLAN_PROGRESS_ID, seasonIdx, stages[idx].progress, CLAN_PROGRESS_REWARD_ID)
}

registerHandler(CLAN_PROGRESS_REWARD_ID, function(res) {
  if (res?.error != null)
    invalidateStats()
})

return {
  CLAN_QUESTS_TAB
  clanQuests
  clanQuestsEndsAt
  isClanQuestsLocked
  clanQuestsUnlockTime
  hasClanQuestsUnseen
  clanProgressCfg
  clanProgress
  hasClanProgressReward
  receiveClanProgressReward
  startClanProgressRefresh
  stopClanProgressRefresh
}
