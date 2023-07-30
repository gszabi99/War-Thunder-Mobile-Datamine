// warning disable: -file:forbidden-function
from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { abTests } = require("%appGlobals/pServer/campaign.nut")

let OT_ONLY_LOGIN = "only_after_login"
let OT_ONLY_BANNER = "only_by_banner"
let OT_ENTER_MAINMENU = "enter_mainmenu"
let OT_NEW_OFFER = "on_any_new_offer"

let dbgShowPrice = mkWatched(persist, "dbgShowPrice", false)
let showPriceOnBanner = Computed(@() (abTests.value?.showPriceOnBanner == "true") != dbgShowPrice.value)

let dbgOpenType = mkWatched(persist, "dbgOpenType", null)
let offerOpenType = Computed(@() dbgOpenType.value ?? abTests.value?.offerOpenType ?? OT_ONLY_BANNER)

register_command(function() {
  dbgShowPrice(!dbgShowPrice.value)
  dlog("Show price on banner: ", showPriceOnBanner.value)
}, "debug.offer.showPriceToggle")

let dbgOrder = [OT_ONLY_LOGIN, OT_ENTER_MAINMENU, OT_NEW_OFFER, OT_ONLY_BANNER]

register_command(function() {
  let idx = dbgOrder.indexof(dbgOpenType.value) ?? -1
  dbgOpenType(dbgOrder[(idx + 1) % dbgOrder.len()])
  dlog("Offer open type: ", offerOpenType.value)
}, "debug.offer.openTypeToggle")

register_command(function() {
  dlog("Show price on banner: ", showPriceOnBanner.value)
  dlog("Offer open type: ", offerOpenType.value)
}, "debug.offer.getMyABTestsInfo")

return {
  OT_ONLY_LOGIN
  OT_ENTER_MAINMENU
  OT_NEW_OFFER
  OT_ONLY_BANNER

  showPriceOnBanner
  offerOpenType
}