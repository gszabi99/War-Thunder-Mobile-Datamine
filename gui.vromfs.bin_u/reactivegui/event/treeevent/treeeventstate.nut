from "%globalsDarg/darg_library.nut" import *

let { getBaseCurrency } = require("%appGlobals/config/currencyPresentation.nut")
let { activeUnlocks, unlockProgress, getUnlockPrice } = require("%rGui/unlocks/unlocks.nut")
let { specialEventsWithTree } = require("%rGui/event/eventState.nut")
let { separateEventModes } = require("%rGui/gameModes/gameModeState.nut")
let { getUnlockRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { seenQuests, inactiveEventUnlocks } = require("%rGui/quests/questsState.nut")
let { loadPresetOnce, updatePresetByUnlocks } = require("treeEventUtils.nut")


let defaultMapSize = [2000, 1000]
let defaultPointSize = 50
let defaultGridSize = 200

let openedTreeEventId = mkWatched(persist, "openedTreeEventId")
let openedSubPresetId = mkWatched(persist, "openedSubPresetId")
let selectedElemId = mkWatched(persist, "selectedElemId", null)
let selectedPointId = mkWatched(persist, "selectedPointId", null)

let currentPresetState = Computed(function() {
  let eventId = openedTreeEventId.get()
  if (eventId == null)
    return null
  return updatePresetByUnlocks(eventId, loadPresetOnce(eventId) ?? {})
})
let currentSubPresetState = Computed(function() {
  let eventId = openedSubPresetId.get()
  if (eventId == null)
    return null
  return updatePresetByUnlocks(eventId, loadPresetOnce(eventId) ?? {})
})
let presetPoints = Computed(@() currentPresetState.get()?.points ?? {})
let presetBgElems = Computed(@() currentPresetState.get()?.bgElements ?? [])
let presetBackground = Computed(@() currentPresetState.get()?.bg ?? "")
let presetMapSize = Computed(@() currentPresetState.get()?.mapSize ?? defaultMapSize)
let presetPointSize = Computed(@() currentPresetState.get()?.pointSize ?? defaultPointSize)
let presetGridSize = Computed(@() currentPresetState.get()?.gridSize ?? defaultGridSize)
let presetLines = Computed(@() currentPresetState.get()?.lines ?? [])

let curEventUnlocks = keepref(Computed(@() openedTreeEventId.get() != null
  ? activeUnlocks.get().filter(@(u) u?.meta.event_id == openedTreeEventId.get())
  : {}))

let treeEventPresets = Computed(@() curEventUnlocks.get().filter(@(unlock) unlock?.meta.quest_cluster).keys())

function isPrevUnlockCompleted(id, unlocks, unlockInProgress) {
  if (id == null)
    return true
  let currentUnlock = unlocks?[id]
  let requirements = "requirement" in currentUnlock ? currentUnlock.requirement.split("|").map(@(r) r.strip()) : [""]

  if (requirements.len() == 0 || (requirements.len() == 1 && requirements[0] == ""))
    return true

  foreach (req in requirements)
    if (unlocks?[req].isCompleted || unlockInProgress?[req].isCompleted)
      return true

  return false
}

let mkCompletedPrevElem = @(id) Computed(@() isPrevUnlockCompleted(id, curEventUnlocks.get(), unlockProgress.get()))

let selectedBgElem = Computed(@() presetBgElems.get().findvalue(@(elem) elem.id == selectedElemId.get()))
let selectedBgElemId = Computed(@() selectedBgElem.get()?.id)

let curEventEndsAt = Computed(@() specialEventsWithTree.get()?[openedTreeEventId.get()].endsAt ?? 0)
let curGmList = Computed(@() separateEventModes.get()?[openedTreeEventId.get()] ?? [])

let mkUnlockCompleteState = @(id, unlocks, unlockInProgress) {
  isCompletedPrevQuest = isPrevUnlockCompleted(id, unlocks, unlockInProgress),
  isCompleted = unlocks?[id].isCompleted
}

let mkPresetUnlocksComplete = @(points, bgElems, unlocks, unlockProgressV)
  points.map(@(_, id) mkUnlockCompleteState(id, unlocks, unlockProgressV))
    .__merge(bgElems
      .reduce(@(res, e) (e?.id ?? "") == "" ? res
          : res.$rawset(e.id, mkUnlockCompleteState(e.id, unlocks, unlockProgressV)),
        {}))

let subPresetUnlocksComplete = Computed(function() {
  let { points = {}, bgElements = [] } = currentSubPresetState.get()
  return mkPresetUnlocksComplete(points, bgElements, curEventUnlocks.get(), unlockProgress.get())
})

let presetUnlocksComplete = Computed(@()
  mkPresetUnlocksComplete(presetPoints.get(), presetBgElems.get(), curEventUnlocks.get(), unlockProgress.get()))

let pointsStatusesByPresets = Computed(function () {
  let unlocks = curEventUnlocks.get()
  let res = {}
  foreach (id, unlock in unlocks) {
    let { quest_cluster = false, quest_cluster_id = "" } = unlock?.meta

    if (quest_cluster) {
      if (id not in res)
        res[id] <- {}
      continue
    }
    if (quest_cluster_id != "") {
      if (quest_cluster_id not in res)
        res[quest_cluster_id] <- {}

      let isCompletedPrevQuest = isPrevUnlockCompleted(id, unlocks, unlockProgress.get())
      let isCompleted = isCompletedPrevQuest && !!unlock?.isCompleted
      let isSeen = unlock?.name not in seenQuests.get() && unlock?.name not in inactiveEventUnlocks.get()

      res[quest_cluster_id][id] <- {
        isCompletedPrevQuest
        isCompleted
        isUnseen = (isCompleted && !unlock?.isFinished) || (isSeen && isCompletedPrevQuest && !isCompleted)
      }
    }
  }
  return res
})

let presetsStatuses = Computed(function () {
  let unlocks = curEventUnlocks.get()
  let res = {}
  foreach (id, unlock in unlocks) {
    let { quest_cluster = false } = unlock?.meta

    if (!quest_cluster)
      continue

    let isCompletedPrevQuest = isPrevUnlockCompleted(id, unlocks, unlockProgress.get())
    let price = getUnlockPrice(unlock)
    let isAvailable = isCompletedPrevQuest && ((price.price ?? 0) == 0)
    let isBlocked = !isCompletedPrevQuest

    res[id] <- { price, isAvailable, isBlocked }
  }
  return res
})

openedTreeEventId.subscribe(function(v) {
  if (!v) {
    selectedElemId.set(null)
    selectedPointId.set(null)
    openedSubPresetId.set(null)
  }
})

selectedBgElemId.subscribe(@(v) v != null ? openedSubPresetId.set(v) : null)
function closeSubPreset() {
  selectedElemId.set(null)
  selectedPointId.set(null)
  openedSubPresetId.set(null)
}

function getUnlocksCurrencies(unlocks, sConfigs) {
  let res = []
  foreach (unlock in unlocks) {
    let stage = unlock.stages?[unlock.stage] ?? unlock.stages?[unlock.stages.len() - 1]
    if (stage != null) {
      if (stage?.currencyCode != null) {
        let stageCurrency = getBaseCurrency(stage.currencyCode)
        if ((stage?.price ?? 0) > 0 && !res.contains(stageCurrency))
          res.append(stageCurrency)
      }
      foreach (reward in getUnlockRewardsViewInfo(stage, sConfigs)) {
        let rewardCurrency = getBaseCurrency(reward.id)
        if (reward.rType == "currency" && !res.contains(rewardCurrency))
          res.append(rewardCurrency)
      }
    }
  }
  return res
}

function getFirstOrCurSubPreset() {
  if(treeEventPresets.get().len() == 0)
    return null
  let presets = treeEventPresets.get()
  let presentsInfo = []
  foreach(p in presets) {
    if(p not in curEventUnlocks.get())
      continue
    presentsInfo.append({
      name = p
      price = getUnlockPrice(curEventUnlocks.get()[p])
      isCompleted = curEventUnlocks.get()?[p].isCompleted ?? false
    })
  }
  let sortPresentsInfo = presentsInfo.sort(@(a, b) a.price.price <=> b.price.price)
  local lastCompletedPreset = sortPresentsInfo[0].name
  foreach(i, v in sortPresentsInfo) {
    if(v.isCompleted && !sortPresentsInfo?[i+1].isCompleted)
      lastCompletedPreset = v.name
  }
  return lastCompletedPreset
}

return {
  openedTreeEventId
  isTreeEventWndOpened = Computed(@() openedTreeEventId.get() != null)
  closeTreeEventWnd = @() openedTreeEventId.set(null)
  openTreeEventWnd = @(eventId) openedTreeEventId.set(eventId)
  presetPoints
  presetBgElems
  presetBackground
  presetMapSize
  presetPointSize
  presetLines
  selectedElemId
  selectedPointId
  selectedBgElemId
  curEventEndsAt
  curEventUnlocks
  presetGridSize
  getUnlocksCurrencies
  mkCompletedPrevElem
  curGmList
  treeEventPresets

  presetsStatuses
  pointsStatusesByPresets
  getFirstOrCurSubPreset
  currentSubPresetState
  subPresetUnlocksComplete
  presetUnlocksComplete
  isPrevUnlockCompleted
  openedSubPresetId
  isSubPresetOpened = Computed(@() openedSubPresetId.get() != null)
  closeSubPreset
}
