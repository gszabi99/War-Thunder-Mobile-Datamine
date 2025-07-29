from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { wndSwitchAnim, wndSwitchTrigger } = require("%rGui/style/stdAnimations.nut")
let { screensList } = require("%globalsDarg/loading/loadingScreensCfg.nut")
let { loadingAnimBg, isLoadinAnimBgAttached, curScreenId, screenWeights
} = require("%globalsDarg/loading/loadingAnimBg.nut")
let { register_command } = require("console")
let { isInLoadingScreen, isMissionLoading } = require("%appGlobals/clientState/clientState.nut")
let { gradientLoadingTip } = require("mkLoadingTip.nut")
let { mkTitleLogo } = require("%globalsDarg/components/titleLogo.nut")
let { addFpsLimit, removeFpsLimit } = require("%rGui/guiFpsLimit.nut")

let lastLoadingBgShow = Watched(get_time_msec())
let missionScreenIdx = Watched(0)

local missionScreen = null
function setMissionLoadingScreen(screen) {
  missionScreen = screen
  missionScreenIdx.set(missionScreenIdx.get() + 1)
}

let updateWeights = @(campaign) screenWeights(screensList
  .filter(@(v) campaign == null || (v?.camp.contains(campaign) ?? true))
  .map(@(s) s.weight))
updateWeights(curCampaign.value)
curCampaign.subscribe(updateWeights)

let lsKey = {}
let loadingScreen = @() {
  watch = [isMissionLoading, missionScreenIdx]
  key = lsKey
  onAttach = @() addFpsLimit(lsKey)
  onDetach = @() removeFpsLimit(lsKey)
  size = flex()
  children = (isMissionLoading.get() ? missionScreen : null)
    ?? [
         loadingAnimBg
         mkTitleLogo({ margin = saBordersRv })
         gradientLoadingTip
       ]
  animations = wndSwitchAnim
}

isLoadinAnimBgAttached.subscribe(function(v) {
  if (!v)
    lastLoadingBgShow(get_time_msec())
  else if (lastLoadingBgShow.value - get_time_msec() < 300)
    anim_skip(wndSwitchTrigger)
})

let ordered = screensList.keys()
ordered.sort()
register_command(function() {
  let idx = ordered.indexof(curScreenId.value) ?? -1
  curScreenId(ordered[(idx + 1) % ordered.len()])
  log($"Set to loading screen '{curScreenId.value}'")
}, "ui.debug.loadingNext")
register_command(function(id) {
  if (id not in screensList)
    return log($"Loading screen '{id}' does not exists")
  curScreenId(id)
  return log($"Set to loading screen '{id}'")
}, "ui.debug.loadingSet")
register_command(@() isInLoadingScreen(!isInLoadingScreen.get()), "ui.debug.loadingScreen")
register_command(function() {
  isMissionLoading(!isMissionLoading.get() || !isInLoadingScreen.get())
  isInLoadingScreen(true)
}, "ui.debug.missionLoading")

return {
  loadingScreen
  loadingAnimBg
  gradientLoadingTip
  setMissionLoadingScreen
}