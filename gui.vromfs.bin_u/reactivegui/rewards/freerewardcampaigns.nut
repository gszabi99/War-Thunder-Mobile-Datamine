from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")

let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { isProfileReceived, curCampaign,
  isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let { requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { isTutorialActive } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")

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
  return myUnits.get().findvalue(@(u) u.name in (serverConfigs.get()?.unitResearchExp ?? {})) != null
    ? UNITS_STATUS.UNITS_AVAILABLE
    : UNITS_STATUS.UNITS_UNAVAILABLE
}))

unitsStatus.subscribe(function(v) {
  let { prevCampaign = null, hasUnitsPrev = null } = prevState.get()
  if (prevCampaign == null || prevCampaign != curCampaign.get())
    return prevState.set({ prevCampaign = curCampaign.get(), hasUnitsPrev = v })
  if (hasUnitsPrev == false && v == UNITS_STATUS.UNITS_AVAILABLE)
    unitToShowAsReceived.set(myUnits.get().findvalue(@(u) u.name in (serverConfigs.get()?.unitResearchExp ?? {})))
})

let needShow = keepref(Computed(@() !hasModalWindows.get()
  && !isInLoadingScreen.get()
  && !isTutorialActive.get()
  && unitToShowAsReceived.get() != null
  && isMainMenuAttached.get()
  && isLoggedIn.get()))

function showReward() {
  if (!needShow.get())
    return
  requestOpenUnitPurchEffect(unitToShowAsReceived.get())
  unitToShowAsReceived.set(null)
  deferOnce(@() needShowTutorialAfterReward.set(true))
}
needShow.subscribe(@(v) v ? deferOnce(showReward) : null)

return { needShowTutorialAfterReward }
