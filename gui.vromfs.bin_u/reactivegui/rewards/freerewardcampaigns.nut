from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")

let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { isProfileReceived, curCampaign,
  isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let { requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { isTutorialActive } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")

let unitToShowAsReceived = Watched(null)
let needShowTutorialAfterReward = Watched(false)
let prevState = Watched(null)
let hasUnits = keepref(Computed(@() (isProfileReceived.get() && isCampaignWithUnitsResearch.get()) ? myUnits.get().len() > 0 : null))

hasUnits.subscribe(function(v) {
  let { prevCampaign = null, hasUnitsPrev = null } = prevState.get()
  if (prevCampaign == null || prevCampaign != curCampaign.get())
    return prevState.set({ prevCampaign = curCampaign.get(), hasUnitsPrev = v })
  if (hasUnitsPrev == false && v == true)
    unitToShowAsReceived.set(myUnits.get().findvalue(@(_) true))
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
