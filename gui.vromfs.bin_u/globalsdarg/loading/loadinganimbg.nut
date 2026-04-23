from "%globalsDarg/darg_library.nut" import *
let { setTimeout, resetTimeout, setInterval, clearTimer } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let random_pick = require("%sqstd/random_pick.nut")
let { mkAnimBg } = require("%globalsDarg/components/mkAnimBg.nut")
let { screensList } = require("loadingScreensCfg.nut")

let curScreenId = mkWatched(persist, "curScreenId", null)
let lastAttachedTime = mkWatched(persist, "lastAttachedTime", -1000000)
let isBgAttached = Watched(false)
let screenWeights = Watched(screensList.reduce(@(res, s, idx)
  s?.timeRange == null && s.weight > 0.0 ? res.$rawset(idx, s.weight) : res, {}))

local lastChooseWeights = null

function chooseRandomScreen() {
  lastChooseWeights = screenWeights.get()
  let weights = clone screenWeights.get()
  if (curScreenId.get() in weights)
    weights.$rawdelete(curScreenId.get())
  if (weights.len() != 0) {
    let id = random_pick(weights)
    log($"[LOADING] Loading screen set to: {id}")
    curScreenId.set(id)
  }
}

if (curScreenId.get() == null)
  chooseRandomScreen()

screenWeights.subscribe(function(v) {
  if (isBgAttached.get() || lastChooseWeights == v)
    return
  if (lastAttachedTime.get() + 5000 > get_time_msec())
    resetTimeout(3.0, chooseRandomScreen)
  else
    chooseRandomScreen()
})

isBgAttached.subscribe(function(v) {
  clearTimer(chooseRandomScreen)
  if (v) {
    if (curScreenId.get() not in screenWeights.get())
      chooseRandomScreen()
    lastAttachedTime.set(get_time_msec())
    setInterval(17.0, chooseRandomScreen)
  }
  else
    setTimeout(3.0, chooseRandomScreen)
})

let bgKey = {}
let loadingAnimBg = @() {
  watch = curScreenId
  key = bgKey
  size = flex()
  onAttach = @() isBgAttached.set(true)
  onDetach = @() isBgAttached.set(false)
  children = mkAnimBg(screensList?[curScreenId.get()].mkLayers() ?? [])
}

return {
  loadingAnimBg
  isLoadinAnimBgAttached = isBgAttached
  curScreenId
  screenWeights
  chooseRandomScreen
}
