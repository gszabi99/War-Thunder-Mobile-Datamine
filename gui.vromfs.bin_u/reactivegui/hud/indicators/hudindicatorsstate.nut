from "%globalsDarg/darg_library.nut" import *
let { sqrt, pow, fabs } = require("math")
let { get_time_msec } = require("dagor.time")
let { setTimeout, setInterval, clearTimer } = require("dagor.workcycle")
let { get_mplayer_by_id } = require("mission")
let { getPlayerWorldPos } = require("guiTacticalMap")
let { isEqual } = require("%sqstd/underscore.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { isInBattle, localMPlayerId } = require("%appGlobals/clientState/clientState.nut")
let { unitType } = require("%rGui/hudState.nut")
let { INDICATOR_TYPE, indicatorTypes } = require("hudIndicatorTypes.nut")
let { getTitleShowDist } = require("playerIndicator.nut")

let TRACKED_PLAYERS_INFO_UPDATE_INTERVAL_SEC = 0.5
let FAR_DISTANCE_METERS = 100000.0

let isHudIndicatorsAttached = Watched(false)
let hudIndicatorsState = mkWatched(persist, "hudIndicatorsState", {})
let usedIdCounter = mkWatched(persist, "usedIdCounter", 0)

function reset() {
  hudIndicatorsState.set({})
  usedIdCounter.set(0)
}
isInBattle.subscribe(@(v) v ? null : reset())

let removeHudIndicator = @(id) id not in hudIndicatorsState.get() ? null
  : hudIndicatorsState.mutate(@(v) v.$rawdelete(id))

function removeHudIndicatorByParams(indicatorType, paramsPartial) {
  let id = hudIndicatorsState.get().findindex(
    @(v) v.indicatorType == indicatorType && paramsPartial.findvalue(@(val, key) val != v.params?[key]) == null)
  if (id != null)
    removeHudIndicator(id)
}

function addHudIndicator(indicatorType, params) {
  let id = usedIdCounter.get() + 1
  usedIdCounter.set(id)
  hudIndicatorsState.mutate(function(his) {
    let nowMs = get_time_msec()
    let mCfg = indicatorTypes[indicatorType]
    let { isDuplicate, showSec } = mCfg
    let hasTimeout = showSec > 0
    foreach (data in his.filter(@(v) v.indicatorType == indicatorType))
      if (isDuplicate(data.params, params))
        his.$rawdelete(data.id)
    his[id] <- {
      id
      indicatorType
      params
      startTimeMs = nowMs
      endTimeMs = hasTimeout
        ? nowMs + (showSec * 1000).tointeger()
        : -1
    }
    if (hasTimeout)
      setTimeout(showSec, @() removeHudIndicator(id))
  })
  return id
}

foreach (data in hudIndicatorsState.get()) {
  let { id, endTimeMs } = data
  if (endTimeMs == -1)
    continue
  let timeLeftMs = endTimeMs - get_time_msec()
  if (timeLeftMs <= 0)
    removeHudIndicator(id)
  else
    setTimeout(timeLeftMs / 1000.0, @() removeHudIndicator(id))
}

let hudIndicatorsByPlayer = Computed(function() {
  let res = {}
  let indicatorsList = hudIndicatorsState.get().values()
    .sort(@(a, b) a.indicatorType <=> b.indicatorType)
  foreach (v in indicatorsList) {
    let { playerId } = v.params
    if (playerId not in res)
      res[playerId] <- []
    res[playerId].append(v)
  }
  return res
})

let hudIndicatorsByPlayerSorted = Watched([])
let playerTitlesVisibility = Watched({})

let getWorldDistance = @(wp1, wp2) sqrt(pow(fabs(wp1.x - wp2.x), 2) + pow(fabs(wp1.z - wp2.z), 2))

local trackedPlayersInfoCache = {}

function updateTrackedPlayersInfo() {
  let myWPos = getPlayerWorldPos(localMPlayerId.get())
  let hudUnitType = unitType.get()
  let hudIndicatorsByPlayerV = hudIndicatorsByPlayer.get()

  let trackedPlayersInfo = hudIndicatorsByPlayerV.map(function(_, playerId) {
    let { title = "", aircraftName = "" } = get_mplayer_by_id(playerId)
    let prev = trackedPlayersInfoCache?[playerId]
    let unitName = aircraftName
    let uType = unitName != prev?.unitName ? getUnitType(unitName) : prev?.uType
    let wPos = getPlayerWorldPos(playerId)
    let wDist = (myWPos != null && wPos != null) ? getWorldDistance(myWPos, wPos) : FAR_DISTANCE_METERS
    let hasTitle = title != ""
      && (wDist != null ? (wDist <= getTitleShowDist(hudUnitType, uType)) : (prev?.hasTitle ?? false))
    return { playerId, unitName, uType, wPos, wDist, hasTitle }
  })

  let indicatorsSorted = trackedPlayersInfo.values()
    .sort(@(a, b) b.wDist <=> a.wDist || b.playerId <=> a.playerId)
    .map(@(v) { playerId = v.playerId, data = hudIndicatorsByPlayerV[v.playerId] })
  if (!isEqual(hudIndicatorsByPlayerSorted.get(), indicatorsSorted))
    hudIndicatorsByPlayerSorted.set(indicatorsSorted)

  let titleVisibility = trackedPlayersInfo.map(@(v) v.hasTitle)
  if (!isEqual(playerTitlesVisibility.get(), titleVisibility))
    playerTitlesVisibility.set(titleVisibility)

  trackedPlayersInfoCache = trackedPlayersInfo
}

hudIndicatorsByPlayer.subscribe(@(_) updateTrackedPlayersInfo())
let needPlayerInfoUpdateTimer = keepref(Computed(@() isHudIndicatorsAttached.get() && hudIndicatorsByPlayer.get().len() != 0))
needPlayerInfoUpdateTimer.subscribe(@(v) v
  ? setInterval(TRACKED_PLAYERS_INFO_UPDATE_INTERVAL_SEC, updateTrackedPlayersInfo)
  : clearTimer(updateTrackedPlayersInfo))
updateTrackedPlayersInfo()

return {
  INDICATOR_TYPE
  addHudIndicator
  removeHudIndicatorByParams
  isHudIndicatorsAttached
  hudIndicatorsByPlayerSorted
  playerTitlesVisibility
  indicatorTypes
}
