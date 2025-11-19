from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDataBlock, blk2SquirrelObjNoArrays } = require("%sqstd/datablock.nut")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")
let { bpProgressUnlock } = require("%rGui/battlePass/battlePassState.nut")
let { eventsPassList, EVENT_PASS, getEventPassName, curEventId } = require("%rGui/battlePass/eventPassState.nut")
let { OPProgressUnlock } = require("%rGui/battlePass/operationPassState.nut")

let SEEN_PASSES = "seenPasses"
let BATTLE_PASS = "battle_pass"
let OPERATION_PASS = "operation_pass"

let seenPasses = mkWatched(persist, SEEN_PASSES, {})
let playerSelectedScene = mkWatched(persist, "playerSelectedScene", null)
let passOpenCounter = mkWatched(persist, "passOpenCounter", 0)

let visibleTabs = Computed(function() {
  let res = []
  if (bpProgressUnlock.get())
    res.append(BATTLE_PASS)
  foreach (ep in eventsPassList.get())
    res.append(getEventPassName(ep.eventName))
  if (OPProgressUnlock.get())
    res.append(OPERATION_PASS)
  return res
})

let passPageIdx = Computed(@() visibleTabs.get().indexof(playerSelectedScene.get()) ?? 0)
let passPageId = Computed(@() visibleTabs.get()?[passPageIdx.get()])

function openPassScene(id) {
  if (visibleTabs.get().findindex(@(v) v == id) == null)
    return
  passOpenCounter.set(passOpenCounter.get() + 1)
  playerSelectedScene.set(id)
}

function closePassScene() {
  passOpenCounter.set(0)
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
  return passes.len() == 0
}

eventsPassList.subscribe(@(_) updateCurEventId())
playerSelectedScene.subscribe(@(_) updateCurEventId())
passPageId.subscribe(@(v) v == null ? closePassScene() : null)

if (seenPasses.get().len() == 0)
  loadSeenPasses()
isSettingsAvailable.subscribe(@(_) loadSeenPasses())

register_command(function() {
  seenPasses.set({})
  get_local_custom_settings_blk().removeBlock(SEEN_PASSES)
  eventbus_send("saveProfile", {})
}, "debug.reset_seen_passes")


return {
  BATTLE_PASS
  EVENT_PASS
  OPERATION_PASS

  passOpenCounter
  openPassScene
  closePassScene

  seenPasses
  markPassesSeen
  isPassGoodsUnseen

  passPageId
  passPageIdx
  playerSelectedScene
  visibleTabs
}