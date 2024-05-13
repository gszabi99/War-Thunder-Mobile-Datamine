from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { setTimeout } = require("dagor.workcycle")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { INDICATOR_TYPE, indicatorTypes } = require("hudIndicatorTypes.nut")

let hudIndicatorsState = mkWatched(persist, "hudIndicatorsState", {})
let usedCounterId = mkWatched(persist, "usedCounterId", 0)

function reset() {
  hudIndicatorsState.set({})
  usedCounterId.set(0)
}
isInBattle.subscribe(@(v) v ? null : reset())

let removeHudIndicator = @(id) id not in hudIndicatorsState.get() ? null
  : hudIndicatorsState.mutate(@(v) v.$rawdelete(id))

function addHudIndicator(indicatorType, params) {
  hudIndicatorsState.mutate(function(his) {
    let nowMs = get_time_msec()
    let mCfg = indicatorTypes[indicatorType]
    let { isDuplicate, showSec } = mCfg
    foreach (data in his.filter(@(v) v.indicatorType == indicatorType))
      if (isDuplicate(data.params, params))
        his.$rawdelete(data.id)
    let id = usedCounterId.get() + 1
    usedCounterId.set(id)
    his[id] <- {
      id
      indicatorType
      params
      startTimeMs = nowMs
      endTimeMs = nowMs + (showSec * 1000).tointeger()
    }
    setTimeout(showSec, @() removeHudIndicator(id))
  })
}

foreach (data in hudIndicatorsState.get()) {
  let { id, endTimeMs } = data
  let timeLeftMs = endTimeMs - get_time_msec()
  if (timeLeftMs <= 0)
    removeHudIndicator(id)
  else
    setTimeout(timeLeftMs / 1000.0, @() removeHudIndicator(id))
}

return {
  INDICATOR_TYPE
  addHudIndicator

  hudIndicatorsState
  indicatorTypes
}
