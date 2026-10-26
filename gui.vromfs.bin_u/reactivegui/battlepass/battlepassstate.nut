from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/pServer/bqClient.nut" import sendCustomBqEvent
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/userstats/serverTime.nut" import getServerTime, isServerTimeValid
from "%appGlobals/timeoutExt.nut" import resetExtTimeout, clearExtTimer
from "%appGlobals/rewardType.nut" import G_BP_GRADE
from "%rGui/unlocks/unlocksConst.nut" import MAIN_EVENT_ID
from "%rGui/event/eventState.nut" import curEvent, eventSeasonIdx
from "%rGui/shop/shopState.nut" import shopGoods


const SREQ_BP_GRADE_EQUAL = 2
const MAX_TIME = 0x7FFFFFFFFFFFFFFF
let activeBattlePassesCfg = Watched({})

let isPurchaseWndOpened = mkWatched(persist, "isPurchaseWndOpened", false)

let curBpId = Computed(@() curEvent.get() == null ? null
  : activeBattlePassesCfg.get().findindex(@(c) c.meta?.event_id == curEvent.get()))

let curBpPages = Computed(@() activeBattlePassesCfg.get()?[curBpId.get()].pages ?? [])
let curBpEndTime = Computed(@() activeBattlePassesCfg.get()?[curBpId.get()].timeRange.end ?? 0)

let battlePasses = Computed(@() servProfile.get()?.battlePasses ?? {})

let curBpGrade = Computed(@() battlePasses.get()?[curBpId.get()].grade ?? 0)
let curBpTotalPoints = Computed(@() battlePasses.get()?[curBpId.get()].totalPoints ?? 0)
let curBpCurPoints = Computed(@() battlePasses.get()?[curBpId.get()].curPoints ?? 0)

function getGradeToClaimByGoods(g, bpId) {
  let { valueInt = null } = g.requirements.findvalue(@(r) r.id == bpId && r.reqType == SREQ_BP_GRADE_EQUAL)
  return valueInt == null ? null
    : valueInt + (g.rewards.findvalue(@(r) r.gType == G_BP_GRADE)?.count ?? 0)
}

let curBpGoods = Computed(@() shopGoods.get()
  .filter(@(g) getGradeToClaimByGoods(g, curBpId.get()) != null)
  .values()
  .sort(@(a, b) getGradeToClaimByGoods(a, curBpId.get()) <=> getGradeToClaimByGoods(b, curBpId.get())
    || a.id <=> b.id))

function getNextTime(curTime, nextTime, start, end) {
  if (start > curTime)
    return min(start, nextTime)
  if (end > curTime)
    return min(end, nextTime)
  return nextTime
}

function updateBattlePasses() {
  if (!isServerTimeValid.get())
    return

  let curTime = getServerTime()
  let { allBattlePasses = {} } = serverConfigs.get()
  let active = {}
  local nextTime = MAX_TIME
  foreach (id, c in allBattlePasses) {
    let { start, end } = c.timeRange
    nextTime = getNextTime(curTime, nextTime, start, end)
    if (start <= curTime && (end <= 0 || end > curTime))
      active[id] <- c
  }

  activeBattlePassesCfg.set(active)

  if (nextTime == MAX_TIME)
    clearExtTimer(updateBattlePasses)
  else
    resetExtTimeout(nextTime - curTime, updateBattlePasses)
}

updateBattlePasses()
serverConfigs.subscribe(@(_) deferOnce(updateBattlePasses))
isServerTimeValid.subscribe(@(_) deferOnce(updateBattlePasses))

curBpId.subscribe(@(_) isPurchaseWndOpened.set(false))
curBpGrade.subscribe(@(_) isPurchaseWndOpened.set(false))

let sendBpBqEvent = @(action) sendCustomBqEvent("battlepass_1", {
  action
  name = $"season_{eventSeasonIdx.get()}"
  isPassPurchased = curBpGrade.get() > 0
})

isPurchaseWndOpened.subscribe(@(v) v ? sendBpBqEvent("bp_purchase_open") : null)

return {
  activeBattlePassesCfg

  battlePasses

  getGradeToClaimByGoods

  sendBpBqEvent

  curBpId
  curBpPages
  curBpGrade
  curBpGoods
  curBpTotalPoints
  curBpCurPoints
  curBpEndTime

  isMainBpActive = Computed(@() null != activeBattlePassesCfg.get().findvalue(@(v) v.meta?.event_id == MAIN_EVENT_ID))

  isPurchaseWndOpened
}