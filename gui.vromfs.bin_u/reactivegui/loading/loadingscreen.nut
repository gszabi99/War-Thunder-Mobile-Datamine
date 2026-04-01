from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { resetTimeout, clearTimer, deferOnce } = require("dagor.workcycle")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curSeasons } = require("%appGlobals/pServer/profileSeasons.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { getServerTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
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

function updateWeights() {
  let campaign = curCampaign.get()
  let commonCamp = getCampaignPresentation(campaign).campaign
  let weights = {}
  let time = getServerTime()
  local timeToUpdate = 0
  foreach (id, screenCfg in screensList) {
    if ((campaign != null && !(screenCfg?.camp.contains(commonCamp) ?? true)))
      continue

    let curSeason = curSeasons.get()?[screenCfg?.timeRange.season]
    let { seasonIdx = null } = screenCfg?.timeRange
    let isActualSeasonIdx = seasonIdx == null || seasonIdx == curSeason?.idx
    let rawStart = screenCfg?.timeRange.start
      ?? (isActualSeasonIdx ? (curSeason?.start ?? 0) : null)
    let rawEnd = screenCfg?.timeRange.end
      ?? (isActualSeasonIdx ? (curSeason?.end ?? 0) : null)
    if (rawEnd == null && rawStart == null)
      continue
    let start = rawStart ?? 0
    let end = rawEnd ?? 0
    if (end != 0 && end <= time)
      continue
    local nextTime = end - time
    if (start > time)
      nextTime = start - time
    else
      weights[id] <- screenCfg.weight
    if (nextTime > 0)
      timeToUpdate = timeToUpdate == 0 ? nextTime : min(timeToUpdate, nextTime)
  }

  if (timeToUpdate <= 0)
    clearTimer(updateWeights)
  else
    resetTimeout(timeToUpdate, updateWeights)

  return screenWeights.set(weights)
}
updateWeights()
curCampaign.subscribe(@(_) deferOnce(updateWeights))
curSeasons.subscribe(@(_) deferOnce(updateWeights))
isServerTimeValid.subscribe(@(_) deferOnce(updateWeights))

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