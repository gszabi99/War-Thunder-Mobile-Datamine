from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")

let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { isProfileReceived, curCampaign,
  isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")

let { requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { isTutorialActive } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let { TUTORIAL_AFTER_REWARD_ID } = require("%rGui/tutorial/tutorialConst.nut")
let { completedTutorials } = require("%rGui/tutorial/completedTutorials.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")


let UNITS_STATUS = {
  UNITS_INITIAL = null,
  UNITS_AVAILABLE = true,
  UNITS_UNAVAILABLE = false
}

let unitToShowAsReceived = Watched(null)
let needShowTutorialAfterReward = Watched(false)
let prevState = Watched(null)
let unitsStatus = keepref(Computed(function() {
  if (!isProfileReceived.get() || !isCampaignWithUnitsResearch.get())
    return UNITS_STATUS.UNITS_INITIAL
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
  let { battles = 0, offlineBattles = 0 } = servProfile.get()?.sharedStatsByCampaign[curCampaign.get()]
  return unitsStatus.get() == UNITS_STATUS.UNITS_AVAILABLE
    && !needShowTutorialAfterReward.get()
    && !needShow.get()
    && !(completedTutorials.get()?[TUTORIAL_AFTER_REWARD_ID] ?? false)
    && (battles == 0 && offlineBattles == 0)
}))

unitsStatus.subscribe(function(v) {
  let { prevCampaign = null, hasUnitsPrev = null } = prevState.get()
  if (prevCampaign == null || prevCampaign != curCampaign.get())
    return prevState.set({ prevCampaign = curCampaign.get(), hasUnitsPrev = v })
  if (hasUnitsPrev == false && v == UNITS_STATUS.UNITS_AVAILABLE)
    unitToShowAsReceived.set(campMyUnits.get().findvalue(@(u) u.name in (serverConfigs.get()?.unitResearchExp ?? {})))
})
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
