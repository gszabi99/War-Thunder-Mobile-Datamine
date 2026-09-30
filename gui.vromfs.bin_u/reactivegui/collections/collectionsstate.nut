from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/pServerApi.nut" import mark_puzzle_pieces_seen
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/timeoutExt.nut" import resetExtTimeout, clearExtTimer
from "%appGlobals/userstats/serverTime.nut" import isServerTimeValid, getServerTime
from "%rGui/account/resetProfileDetector.nut" import subscribeResetProfile
from "%rGui/event/eventState.nut" import curEvent
from "%rGui/event/treeEvent/eventMapLoader.nut" import mkLoadPreset


const SAVED_PRESETS_PATH = "%appGlobals/config/collections"
const MAX_TIME = 0x7FFFFFFFFFFFFFFF
let activeCollectionsCfg = Watched({})
let openedPuzzleId = mkWatched(persist, "openedPuzzleId")
let seenPiecesExt = hardPersistWatched("collections.seenPiecesExt", {})

let curCollectionId = Computed(@() curEvent.get() == null ? null
  : activeCollectionsCfg.get().findindex(@(c) c.meta?.event_id == curEvent.get()))
let isPuzzleWndOpened = Computed(@() curCollectionId.get() != null && openedPuzzleId.get() != null)

function getNextTime(curTime, nextTime, start, end) {
  if (start > curTime)
    return min(start, nextTime)
  if (end > curTime)
    return min(end, nextTime)
  return nextTime
}

function updateActiveCollections() {
  if (!isServerTimeValid.get())
    return

  let curTime = getServerTime()
  let { allCollections = {} } = serverConfigs.get()
  let active = {}
  local nextTime = MAX_TIME
  foreach (id, c in allCollections) {
    let { start, end } = c.timeRange
    nextTime = getNextTime(curTime, nextTime, start, end)
    if (start <= curTime && (end <= 0 || end > curTime))
      active[id] <- c
  }

  activeCollectionsCfg.set(active)

  if (nextTime == MAX_TIME)
    clearExtTimer(updateActiveCollections)
  else
    resetExtTimeout(nextTime - curTime, updateActiveCollections)
}

updateActiveCollections()
serverConfigs.subscribe(@(_) deferOnce(updateActiveCollections))
isServerTimeValid.subscribe(@(_) deferOnce(updateActiveCollections))

let loadPresetImpl = mkLoadPreset(SAVED_PRESETS_PATH)
let loadCollectionPresetOnce = @(id) loadPresetImpl($"collection_{id}")

function isAllCollectionPiecesReceived(id, sConfigs, sProfile) {
  let col = sProfile?.collections[id]
  let colCfg = sConfigs?.allCollections[id]
  if (col == null || colCfg == null)
    return false

  let { puzzles  = [] } = colCfg
  let { isFinalReceived = false, puzzlePiecesMasks = [] } = col
  return isFinalReceived
    || null == puzzles.findvalue(@(p, i) p.piecesMask != (p.piecesMask & (puzzlePiecesMasks?[i] ?? 0)))
}

let unseenPiecesByCollection = Computed(function() {
  let res = {}
  let ext = seenPiecesExt.get()
  foreach (cId, col in servProfile.get()?.collections ?? {}) {
    if (cId not in activeCollectionsCfg.get())
      continue
    let { puzzlePiecesMasks = [], seenPiecesMasks = [] } = col
    let byPuzzle = {}
    foreach (pId, mask in puzzlePiecesMasks) {
      let unseen = mask & ~((seenPiecesMasks?[pId] ?? 0) | (ext?[cId][pId] ?? 0))
      if (unseen != 0)
        byPuzzle[pId] <- unseen
    }
    if (byPuzzle.len() != 0)
      res[cId] <- byPuzzle
  }
  return res
})

let curUnseenPiecesMasks = Computed(@() unseenPiecesByCollection.get()?[curCollectionId.get()] ?? {})

function hasPuzzleRewardToReceive(col, pCfg, pId) {
  let { piecesMask = 0, rewards = [] } = pCfg
  return rewards.len() != 0 && piecesMask != 0
    && ((col?.puzzleRewardsMask ?? 0) & (1 << pId)) == 0
    && (piecesMask & (col?.puzzlePiecesMasks[pId] ?? 0)) == piecesMask
}

function hasFinalRewardToReceive(col, cfg) {
  let { puzzles = [], finalRewards = [] } = cfg
  let fullMask = (1 << puzzles.len()) - 1
  return finalRewards.len() != 0 && fullMask != 0 && !(col?.isFinalReceived ?? false)
    && ((col?.puzzleRewardsMask ?? 0) & fullMask) == fullMask
}

let rewardsToReceiveByCollection = Computed(function() {
  let res = {}
  let cols = servProfile.get()?.collections ?? {}
  foreach (cId, cfg in activeCollectionsCfg.get()) {
    let col = cols?[cId]
    if (col == null)
      continue
    let puzzles = {}
    foreach (pId, pCfg in cfg?.puzzles ?? [])
      if (hasPuzzleRewardToReceive(col, pCfg, pId))
        puzzles[pId] <- true
    if (puzzles.len() != 0 || hasFinalRewardToReceive(col, cfg))
      res[cId] <- { puzzles }
  }
  return res
})

let curRewardsToReceive = Computed(@() rewardsToReceiveByCollection.get()?[curCollectionId.get()])

let mkCollectionHasUnseen = @(eventId) Computed(function() {
  let cId = activeCollectionsCfg.get().findindex(@(c) c.meta?.event_id == eventId.get())
  return cId != null && (cId in unseenPiecesByCollection.get() || cId in rewardsToReceiveByCollection.get())
})

function markPuzzleSeen(cId, pId) {
  let unseen = unseenPiecesByCollection.get()?[cId][pId] ?? 0
  if (unseen == 0)
    return
  seenPiecesExt.mutate(function(v) {
    if (cId not in v)
      v[cId] <- {}
    v[cId][pId] <- (v[cId]?[pId] ?? 0) | unseen
  })
  mark_puzzle_pieces_seen(cId, pId, unseen)
}

isLoggedIn.subscribe(@(_) seenPiecesExt.set({}))
subscribeResetProfile(@() seenPiecesExt.set({}))

return {
  activeCollectionsCfg
  curCollectionId
  isPuzzleWndOpened
  openedPuzzleId
  curCollectionCfg = Computed(@() activeCollectionsCfg.get()?[curCollectionId.get()])
  curCollection = Computed(@() servProfile.get()?.collections[curCollectionId.get()])
  loadCollectionPresetOnce
  openPuzzle = @(id) openedPuzzleId.set(id)

  isAllCollectionPiecesReceived

  curUnseenPiecesMasks
  curRewardsToReceive
  mkCollectionHasUnseen
  markPuzzleSeen
}