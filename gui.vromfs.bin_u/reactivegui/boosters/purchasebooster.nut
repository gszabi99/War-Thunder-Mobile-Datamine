from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/campaign.nut" import campConfigs
from "%appGlobals/pServer/pServerApi.nut" import boosterInProgress, buy_booster
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/shop/msgBoxPurchase.nut" import openMsgBoxPurchase
from "%rGui/style/stdColors.nut" import userlogTextColor


function purchaseBooster(id, localizedName, bqInfo) {
  if (boosterInProgress.get() != null)
    return

  let booster = campConfigs.get()?.allBoosters[id]
  if (booster == null)
    return

  let { battlesLeft = 0 } = servProfile.get()?.boosters[id]
  let { price = 0, currencyId = "", effect = "", limit = 0 } = booster
  if (limit > 0 && limit <= battlesLeft) {
    logerr("Try to purchase booster with limit")
    return
  }

  if (price <= 0) {
    logerr("Try to purchase booster without price")
    return
  }
  openMsgBoxPurchase({
    text = loc("shop/needMoneyQuestion",
      { item = colorize(userlogTextColor, localizedName) }),
    price = { price, currencyId },
    limitCountText = limit <= 0 ? null : $"{battlesLeft}/{limit}"
    purchase = @() buy_booster(effect, currencyId, price),
    bqInfo
  })
}

return purchaseBooster