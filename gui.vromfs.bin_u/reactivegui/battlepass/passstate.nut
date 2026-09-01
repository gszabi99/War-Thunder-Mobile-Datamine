from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "console" import register_command
from "eventbus" import eventbus_send
from "%sqstd/datablock.nut" import isDataBlock, blk2SquirrelObjNoArrays
from "%appGlobals/loginState.nut" import isSettingsAvailable
from "%rGui/account/resetProfileDetector.nut" import subscribeResetProfile
from "%rGui/battlePass/battlePassState.nut" import mkBpStagesList, isBpVipActive, isBpCommonActive,
  hasBpRewardsToReceive, battlePassGoods, lastStageBpProgress, bpProgressUnlock
from "%rGui/battlePass/eventPassState.nut" import mkEpStagesList, isEpVipActive, isEpCommonActive,
  mkHasEpRewardsToReceive, mkEventPassGoods, lastStageEpProgress, curEventId, getEventPassName, EVENT_PASS,
  eventsPassList
from "%rGui/battlePass/operationPassState.nut" import mkOPStagesList, isOpVipActive, isOpCommonActive,
  hasOPRewardsToReceive, operationPassGoods, lastStageOpProgress, OP_EVENT_ID
from "%rGui/event/eventState.nut" import curEvent, subEventsList
from "%rGui/unlocks/unlocksConst.nut" import MAIN_EVENT_ID


const SEEN_PASSES = "seenPasses"
const BATTLE_PASS = "battle_pass"
const OPERATION_PASS = "operation_pass"

let seenPasses = mkWatched(persist, SEEN_PASSES, {})
let playerSelectedScene = mkWatched(persist, "playerSelectedScene", null)
let passOpenCounter = mkWatched(persist, "passOpenCounter", 0)
let isPassSceneAttached = mkWatched(persist, "isPassSceneAttached", false)

let tabsState = {
  [BATTLE_PASS] = {
    mkStagesList = mkBpStagesList
    lastRewardProgress = lastStageBpProgress
    isVipActive = isBpVipActive
    isCommonActive = isBpCommonActive
    hasReward = hasBpRewardsToReceive
    goods = battlePassGoods
  },
  [EVENT_PASS] = {
    mkStagesList = mkEpStagesList
    lastRewardProgress = lastStageEpProgress
    isVipActive = isEpVipActive
    isCommonActive = isEpCommonActive
    mkHasReward = mkHasEpRewardsToReceive
    mkGoods = mkEventPassGoods
  },
  [OPERATION_PASS] = {
    mkStagesList = mkOPStagesList
    lastRewardProgress = lastStageOpProgress
    isVipActive = isOpVipActive
    isCommonActive = isOpCommonActive
    hasReward = hasOPRewardsToReceive
    goods = operationPassGoods
  },
}

let getTabStateData = @(passName) passName == null ? null
  : passName.startswith(EVENT_PASS) ? tabsState[EVENT_PASS]
  : tabsState?[passName]

function getVisibleTabs(eventId, bpUnlock, passList, subList) {
  let res = []
  if (bpUnlock && eventId == MAIN_EVENT_ID)
    res.append(BATTLE_PASS)
  foreach (ep in passList)
    if (ep.eventId == eventId || subList?[ep.eventId] == eventId)
      res.append(getEventPassName(ep.eventName))
  if (eventId == OP_EVENT_ID)
    res.append(OPERATION_PASS)
  return res
}

let visibleTabs = Computed(@() getVisibleTabs(curEvent.get(), bpProgressUnlock.get(), eventsPassList.get(), subEventsList.get()))

let passPageIdx = Computed(@() visibleTabs.get().indexof(playerSelectedScene.get()) ?? 0)
let passPageId = Computed(@() visibleTabs.get()?[passPageIdx.get()])

function openPassScene(id) {
  if (visibleTabs.get().findindex(@(v) v == id) == null)
    return
  passOpenCounter.set(passOpenCounter.get() + 1)
  playerSelectedScene.set(id)
}

function updateCurEventId() {
  let curEventPassName = passPageId.get()
  let { eventName = null } = eventsPassList.get().findvalue(@(ep) getEventPassName(ep.eventName) == curEventPassName)
  if (eventName != null)
    curEventId.set(eventName)
}

function loadSeenPasses() {
  if (!isSettingsAvailable.get())
    return seenPasses.set({})
  let sBlk = get_local_custom_settings_blk()

  let htBlk = sBlk?[SEEN_PASSES]
  seenPasses.set(isDataBlock(htBlk) ? blk2SquirrelObjNoArrays(htBlk) : {})
}

function markPassesSeen(idsExt) {
  let ids = idsExt.filter(@(passName) passName not in seenPasses.get())
  if (ids.len() == 0)
    return

  seenPasses.mutate(function(v) {
    foreach (id in ids)
      v[id] <- true
  })
  let blk = get_local_custom_settings_blk().addBlock(SEEN_PASSES)
  foreach (id in ids)
    blk[id] = true
  eventbus_send("saveProfile", {})
}

function isPassGoodsUnseen(passes, sPasses) {
  foreach (p in passes)
    if (p?.id != null && p.id not in sPasses)
      return true
  return false
}

function tryMarkPassesSeenByPageId(v) {
  let { goods = null, mkGoods = null } = getTabStateData(v)
  let pageGoods = goods ?? mkGoods?(v)
  if (pageGoods == null || pageGoods.get() == null)
    return

  markPassesSeen(pageGoods.get().reduce(@(res, g) g?.id ? res.append(g.id) : res, []))
}

function closePassScene() {
  tryMarkPassesSeenByPageId(passPageId.get())
  passOpenCounter.set(0)
}

eventsPassList.subscribe(@(_) updateCurEventId())
passPageId.subscribe(@(_) updateCurEventId())
passPageId.subscribe(@(v) v == null ? closePassScene() : tryMarkPassesSeenByPageId(v))

if (seenPasses.get().len() == 0)
  loadSeenPasses()
isSettingsAvailable.subscribe(@(_) loadSeenPasses())

function resetAllPasses() {
  seenPasses.set({})
  get_local_custom_settings_blk().removeBlock(SEEN_PASSES)
  eventbus_send("saveProfile", {})
}

register_command(resetAllPasses, "debug.reset_seen_passes")

subscribeResetProfile(resetAllPasses)


return {
  BATTLE_PASS
  EVENT_PASS
  OPERATION_PASS

  passOpenCounter
  isPassSceneAttached
  openPassScene
  closePassScene

  seenPasses
  isPassGoodsUnseen

  passPageId
  passPageIdx
  playerSelectedScene
  visibleTabs

  getVisibleTabs
  getTabStateData
}