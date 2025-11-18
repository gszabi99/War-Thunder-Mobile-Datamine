from "%globalsDarg/darg_library.nut" import *
let { fabs } = require("math")
let { get_time_msec } = require("dagor.time")
let { setTimeout, setInterval, clearTimer } = require("dagor.workcycle")
let { getPlayerMapPos, worldPosToMapPos } = require("guiTacticalMap")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { hudWhiteColor } = require("%rGui/style/hudColors.nut")

let MARKER_TYPE = {
  RADIO_SPEAKER = 1
  CAPTURE_POINT_MARK = 2
  ATTENTION_MARK = 3
}

let POS_UPDATE_INTERVAL = 0.3
let UNNOTICABLE_MAP_POS_CHANGE = 0.0005
let FADE_TIME = 1.0

let mapMarkers = mkWatched(persist, "mapMarkers", {})
let usedCounterId = mkWatched(persist, "usedCounterId", 0)

function reset() {
  mapMarkers.set({})
  usedCounterId.set(0)
}
isInBattle.subscribe(@(v) v ? null : reset())

let isMapPosValid = @(p) p != null && p.x >= 0 && p.x <= 1 && p.y >= 0 && p.y <= 1

let mkMapMarkerComp = @(id, mapPos, iconOvr) {
  key = $"mapMark{id}"
  size = 0
  pos = [pw(mapPos.x * 100), ph(mapPos.y * 100)]
  children = {
    key = $"mapMarkImg{id}"
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    opacity = 0
    transform = {}
  }.__update(iconOvr)
}

function ctorMarkAttention(size, data) {
  let { id, mapPos, startTimeMs, endTimeMs } = data
  if (!isMapPosValid(mapPos))
    return null
  let startDelay = (startTimeMs - get_time_msec()) / 1000.0
  let totalTime = (endTimeMs - startTimeMs) / 1000.0
  return mkMapMarkerComp(id, mapPos, {
    size = [size, size]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#map_mark_attention.svg:{size}:{size}:P")
    color = hudWhiteColor
    animations = [
      { prop = AnimProp.rotate, from = 0 to = 360, duration = 3.0,
          play = true, easing = InOutQuad, delay = startDelay, loop = true }
      { prop = AnimProp.opacity, from = 0, to = 1, duration = FADE_TIME,
          play = true, easing = InOutQuad, delay = startDelay }
      { prop = AnimProp.opacity, from = 1, to = 1, duration = totalTime - (FADE_TIME * 2),
          play = true, easing = InOutQuad, delay = startDelay + FADE_TIME }
      { prop = AnimProp.opacity, from = 1, to = 0, duration = FADE_TIME,
          play = true, easing = InOutQuad, delay = startDelay + totalTime - FADE_TIME }
    ]
  })
}

let attentionMarkBase = {
  showSec = 10.0
  isDuplicate = @(p1, p2) p1.worldCoords.x == p2.worldCoords.x &&
    p1.worldCoords.y == p2.worldCoords.y && p1.worldCoords.z == p2.worldCoords.z
  getMapPos = @(params) worldPosToMapPos(params.worldCoords)
}

let markerTypes = {
  [MARKER_TYPE.RADIO_SPEAKER] = {
    showSec = 5.0
    isDuplicate = @(p1, p2) p1.playerId == p2.playerId
    getMapPos = @(params) getPlayerMapPos(params.playerId)
    function ctor(data) {
      let { id, mapPos, startTimeMs, endTimeMs } = data
      if (!isMapPosValid(mapPos))
        return null
      let startDelay = (startTimeMs - get_time_msec()) / 1000.0
      let totalTime = (endTimeMs - startTimeMs) / 1000.0
      let size = evenPx(32)
      return mkMapMarkerComp(id, mapPos, {
        size = [size, size]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#map_mark_speaker.svg:{size}:{size}:P")
        color = 0xC0C0C0C0
        animations = [
          { prop = AnimProp.scale, from = [0.3, 0.3] to = [1, 1], duration = 1.0,
              play = true, easing = OutCubic, delay = startDelay, loop = true }
          { prop = AnimProp.opacity, from = 0, to = 1, duration = FADE_TIME,
              play = true, easing = InOutQuad, delay = startDelay }
          { prop = AnimProp.opacity, from = 1, to = 1, duration = totalTime - FADE_TIME,
              play = true, easing = InOutQuad, delay = startDelay + FADE_TIME }
        ]
      })
    }
  },
  [MARKER_TYPE.CAPTURE_POINT_MARK] = attentionMarkBase.__merge({
    ctor = @(data) ctorMarkAttention(evenPx(48), data)
  }),
  [MARKER_TYPE.ATTENTION_MARK] = attentionMarkBase.__merge({
    ctor = @(data) ctorMarkAttention(evenPx(40), data)
  }),
}

let removeMapMarker = @(id) id not in mapMarkers.get() ? null
  : mapMarkers.mutate(@(t) t.$rawdelete(id))

function addMapMarker(markerType, params) {
  mapMarkers.mutate(function(mm) {
    let nowMs = get_time_msec()
    let mCfg = markerTypes[markerType]
    let { isDuplicate, getMapPos, showSec } = mCfg
    foreach (data in mm.filter(@(v) v.markerType == markerType))
      if (isDuplicate(data.params, params))
        mm.$rawdelete(data.id)
    let id = usedCounterId.get() + 1
    usedCounterId.set(id)
    mm[id] <- {
      id
      markerType
      params
      mapPos = getMapPos(params)
      startTimeMs = nowMs
      endTimeMs = nowMs + (showSec * 1000).tointeger()
    }
    setTimeout(showSec, @() removeMapMarker(id))
  })
}

foreach (data in mapMarkers.get()) {
  let { id, endTimeMs } = data
  let timeLeftMs = endTimeMs - get_time_msec()
  if (timeLeftMs <= 0)
    removeMapMarker(id)
  else
    setTimeout(timeLeftMs / 1000.0, @() removeMapMarker(id))
}

function updateMarkerPositions() {
  local hasChanges = false
  let newMapPositions = {}
  foreach (data in mapMarkers.get()) {
    let { id, mapPos, markerType, params } = data
    let newPos = markerTypes[markerType].getMapPos(params)
    newMapPositions[id] <- newPos
    let isNewValid = isMapPosValid(newPos)
    let isOldValid = isMapPosValid(mapPos)
    if (isNewValid != isOldValid
        || (isNewValid && isOldValid && max(fabs(newPos.x - mapPos.x), fabs(newPos.y - mapPos.y)) > UNNOTICABLE_MAP_POS_CHANGE))
      hasChanges = true
  }
  if (!hasChanges)
    return
  mapMarkers.mutate(function(mm) {
    foreach(id, data in mm)
      data.mapPos = newMapPositions[id]
  })
}

let isNeedPosUpdateTimer = keepref(Computed(@() mapMarkers.get().len() != 0))
isNeedPosUpdateTimer.subscribe(function(v) {
  clearTimer(updateMarkerPositions)
  if (v)
    setInterval(POS_UPDATE_INTERVAL, updateMarkerPositions)
})

let tacticalMapMarkersLayer = @() {
  watch = mapMarkers
  size = flex()
  clipChildren = true
  children = mapMarkers.get().values().map(@(data) markerTypes[data.markerType].ctor(data))
}

return {
  MARKER_TYPE
  addMapMarker

  tacticalMapMarkersLayer
}
