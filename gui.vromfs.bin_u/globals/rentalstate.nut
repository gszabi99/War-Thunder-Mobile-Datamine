from "frp" import Computed
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/pServer/campaign.nut" import campConfigs, abTests, curCampaign
import "%appGlobals/pServer/servProfile.nut" as servProfile


let battleRentInfo = hardPersistWatched("battleRentInfo", null)

let rentals = Computed(@() servProfile.get()?.rentals ?? {})
let rentalCd = Computed(@() abTests.get()?.rentShips == "true" && curCampaign.get() == "ships" ? 23 * 60 * 60
  : (campConfigs.get()?.campaignCfg.rentCooldown ?? 0))


return {
  battleRentInfo
  rentals
  rentalCd
}
