let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { campConfigs, abTests, curCampaign } = require("%appGlobals/pServer/campaign.nut")


let battleRentInfo = sharedWatched("battleRentInfo", @() null)

let rentals = Computed(@() servProfile.get()?.rentals ?? {})
let rentalCd = Computed(@() abTests.get()?.rentShips == "true" && curCampaign.get() == "ships_new" ? 23 * 60 * 60
  : (campConfigs.get()?.campaignCfg.rentCooldown ?? 0))


return {
  battleRentInfo
  rentals
  rentalCd
}
