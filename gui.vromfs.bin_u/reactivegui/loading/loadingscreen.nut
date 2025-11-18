from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { wndSwitchAnim, wndSwitchTrigger } = require("%rGui/style/stdAnimations.nut")
let { screensList } = require("%globalsDarg/loading/loadingScreensCfg.nut")
let { loadingAnimBg, isLoadinAnimBgAttached, curScreenId, screenWeights
} = require("%globalsDarg/loading/loadingAnimBg.nut")
let { register_command } = require("console")
let { isInLoadingScreen, isMissionLoading } = require("%appGlobals/clientState/clientState.nut")
let { gradientLoadingTip } = require("%rGui/loading/mkLoadingTip.nut")
let { mkTitleLogo } = require("%globalsDarg/components/titleLogo.nut")
let { addFpsLimit, removeFpsLimit } = require("%rGui/guiFpsLimit.nut")

let lastLoadingBgShow = Watched(get_time_msec())
let missionScreenIdx = Watched(0)

local missionScreen = null
function setMissionLoadingScreen(screen) {
  missionScreen = screen
  missionScreenIdx.set(missionScreenIdx.get() + 1)
}

function updateWeights(campaign) {
  let commonCamp = getCampaignPresentation(campaign).campaign
  return screenWeights.set(screensList
    .filter(@(v) campaign == null || (v?.camp.contains(commonCamp) ?? true))
    .map(@(s) s.weight))
}
updateWeights(curCampaign.get())
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
    lastLoadingBgShow.set(get_time_msec())
  else if (lastLoadingBgShow.get() - get_time_msec() < 300)
    anim_skip(wndSwitchTrigger)
})

let ordered = screensList.keys()
ordered.sort()
register_command(function() {
  let idx = ordered.indexof(curScreenId.get()) ?? -1
  curScreenId.set(ordered[(idx + 1) % ordered.len()])
  log($"Set to loading screen '{curScreenId.get()}'")
}, "ui.debug.loadingNext")
register_command(function(id) {
  if (id not in screensList)
    return log($"Loading screen '{id}' does not exists")
  curScreenId.set(id)
  return log($"Set to loading screen '{id}'")
}, "ui.debug.loadingSet")
register_command(@() isInLoadingScreen.set(!isInLoadingScreen.get()), "ui.debug.loadingScreen")
register_command(function() {
  isMissionLoading.set(!isMissionLoading.get() || !isInLoadingScreen.get())
  isInLoadingScreen.set(true)
}, "ui.debug.missionLoading")

return {
  loadingScreen
  loadingAnimBg
  gradientLoadingTip
  setMissionLoadingScreen
}