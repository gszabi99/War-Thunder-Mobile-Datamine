from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDataBlock, blk2SquirrelObjNoArrays } = require("%sqstd/datablock.nut")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")
let { mkBpStagesList, isBpVipActive, isBpCommonActive, hasBpRewardsToReceive, battlePassGoods,
  lastStageBpProgress, bpProgressUnlock
} = require("%rGui/battlePass/battlePassState.nut")
let { mkEpStagesList, isEpVipActive, isEpCommonActive, mkHasEpRewardsToReceive, mkEventPassGoods,
  lastStageEpProgress, curEventId, getEventPassName, EVENT_PASS, eventsPassList
} = require("%rGui/battlePass/eventPassState.nut")
let { mkOPStagesList, isOpVipActive, isOpCommonActive, hasOPRewardsToReceive, operationPassGoods,
  lastStageOpProgress, OP_EVENT_ID
} = require("%rGui/battlePass/operationPassState.nut")
let { subscribeResetProfile } = require("%rGui/account/resetProfileDetector.nut")
let { MAIN_EVENT_ID } = require("%rGui/unlocks/unlocksConst.nut")
let { curEvent, subEventsList } = require("%rGui/event/eventState.nut")


let SEEN_PASSES = "seenPasses"
let BATTLE_PASS = "battle_pass"
let OPERATION_PASS = "operation_pass"

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
  let curEventPassName = playerSelectedScene.get()
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
playerSelectedScene.subscribe(@(_) updateCurEventId())
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