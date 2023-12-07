from "%globalsDarg/darg_library.nut" import *
let { setTimeout, resetTimeout, setInterval, clearTimer } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let random_pick = require("%sqstd/random_pick.nut")
let { mkAnimBg } = require("%globalsDarg/components/mkAnimBg.nut")
let { fallbackLoadingImage, screensList } = require("loadingScreensCfg.nut")

let curScreenId = mkWatched(persist, "curScreenId", null)
let lastAttachedTime = mkWatched(persist, "lastAttachedTime", -1000000)
let isBgAttached = Watched(false)
let screenWeights = Watched(screensList.map(@(s) s.weight))

let function chooseRandomScreen() {
  let weights = clone screenWeights.value
  if (curScreenId.value in weights)
    weights.$rawdelete(curScreenId.value)
  if (weights.len() != 0)
    curScreenId(random_pick(weights))
}

if (curScreenId.value == null)
  chooseRandomScreen()

screenWeights.subscribe(function(_) {
  if (isBgAttached.value)
    return
  if (lastAttachedTime.value + 5000 > get_time_msec())
    resetTimeout(3.0, chooseRandomScreen)
  else
    chooseRandomScreen()
})

isBgAttached.subscribe(function(v) {
  clearTimer(chooseRandomScreen)
  if (v) {
    lastAttachedTime(get_time_msec())
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
  onAttach = @() isBgAttached(true)
  onDetach = @() isBgAttached(false)
  children = mkAnimBg(screensList?[curScreenId.value].mkLayers() ?? [], fallbackLoadingImage)
}

return {
  loadingAnimBg
  isLoadinAnimBgAttached = isBgAttached
  curScreenId
  screenWeights
}
