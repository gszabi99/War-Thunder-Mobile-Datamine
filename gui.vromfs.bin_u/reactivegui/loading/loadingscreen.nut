from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.time" import get_time_msec
from "dagor.workcycle" import resetTimeout, clearTimer, deferOnce
from "%appGlobals/clientState/clientState.nut" import isInLoadingScreen, isMissionLoading
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/profileSeasons.nut" import curSeasons
from "%appGlobals/userstats/serverTime.nut" import getServerTime, isServerTimeValid
from "%globalsDarg/components/titleLogo.nut" import mkTitleLogo
from "%globalsDarg/loading/loadingAnimBg.nut" import loadingAnimBg, isLoadinAnimBgAttached, curScreenId, screenWeights
from "%globalsDarg/loading/loadingScreensCfg.nut" import screensList
from "%rGui/guiFpsLimit.nut" import addFpsLimit, removeFpsLimit
from "%rGui/loading/mkLoadingTip.nut" import gradientLoadingTip
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim, wndSwitchTrigger


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

    let { season = null } = screenCfg?.timeRange
    let curSeason = curSeasons.get()?[season]
    if (season != null && curSeason == null)
      continue

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
  size = FLEX
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