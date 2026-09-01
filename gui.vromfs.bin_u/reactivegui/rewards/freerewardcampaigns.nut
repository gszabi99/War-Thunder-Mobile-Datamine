from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/clientState/clientState.nut" import isInLoadingScreen
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/campaign.nut" import isProfileReceived, curCampaign, sharedStatsByCampaign
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/mainMenu/mainMenuState.nut" import isInMenuNoModals
from "%rGui/tutorial/completedTutorials.nut" import completedTutorials
from "%rGui/tutorial/tutorialConst.nut" import TUTORIAL_AFTER_REWARD_ID
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import isTutorialActive
from "%rGui/unit/unitPurchaseEffectScene.nut" import requestOpenUnitPurchEffect


let UNITS_STATUS = {
  NOT_INITED = null,
  UNITS_AVAILABLE = true,
  UNITS_UNAVAILABLE = false
}

let unitToShowAsReceived = hardPersistWatched("freeRewardCampaigns.unitToShowAsReceived")
let needShowTutorialAfterReward = hardPersistWatched("freeRewardCampaigns.needShowTutorialAfterReward", false)
let prevState = Watched(null)
let unitsStatus = keepref(Computed(function() {
  if (!isProfileReceived.get())
    return UNITS_STATUS.NOT_INITED
  return campMyUnits.get().findvalue(@(u) u.name in (serverConfigs.get()?.unitResearchExp ?? {})) != null
    ? UNITS_STATUS.UNITS_AVAILABLE
    : UNITS_STATUS.UNITS_UNAVAILABLE
}))
let needShow = keepref(Computed(@() isInMenuNoModals.get()
  && !isInLoadingScreen.get()
  && !isTutorialActive.get()
  && unitToShowAsReceived.get() != null
  && isLoggedIn.get()))
let needShowTutorialAfterLeaveGame = keepref(Computed(function() {
  let { battles = 0, offlineBattles = 0 } = sharedStatsByCampaign.get()
  return unitsStatus.get() == UNITS_STATUS.UNITS_AVAILABLE
    && !needShowTutorialAfterReward.get()
    && !needShow.get()
    && !(completedTutorials.get()?[TUTORIAL_AFTER_REWARD_ID] ?? false)
    && (battles == 0 && offlineBattles == 0)
}))

function updateUnitToShowAsReceived(unitsStatusV) {
  if (unitsStatusV == UNITS_STATUS.NOT_INITED)
    return
  let { prevCampaign = null, hasUnitsPrev = null } = prevState.get()
  if (prevCampaign == null || prevCampaign != curCampaign.get())
    return prevState.set({ prevCampaign = curCampaign.get(), hasUnitsPrev = unitsStatusV })
  if (hasUnitsPrev == false && unitsStatusV == UNITS_STATUS.UNITS_AVAILABLE)
    unitToShowAsReceived.set(campMyUnits.get().findvalue(@(u) u.name in (serverConfigs.get()?.unitResearchExp ?? {})))
}
updateUnitToShowAsReceived(unitsStatus.get())
unitsStatus.subscribe(updateUnitToShowAsReceived)
needShowTutorialAfterLeaveGame.subscribe(@(v) v ? needShowTutorialAfterReward.set(true) : null)

function showReward() {
  if (!needShow.get())
    return
  requestOpenUnitPurchEffect(unitToShowAsReceived.get())
  unitToShowAsReceived.set(null)
  deferOnce(@() needShowTutorialAfterReward.set(true))
}
needShow.subscribe(@(v) v ? deferOnce(showReward) : null)

return { needShowTutorialAfterReward }
