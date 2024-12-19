from "%globalsDarg/darg_library.nut" import *
let { boosterInProgress, buy_booster } = require("%appGlobals/pServer/pServerApi.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")

function purchaseBooster(id, localizedName, bqInfo) {
  if (boosterInProgress.value != null)
    return

  let booster = campConfigs.get()?.allBoosters[id]
  if (booster == null)
    return

  let { price = 0, currencyId = "", effect = ""} = booster
  if (price <= 0) {
    logerr("Try to purchase booster without price")
    return
  }
  openMsgBoxPurchase({
    text = loc("shop/needMoneyQuestion",
      { item = colorize(userlogTextColor, localizedName) }),
    price = { price, currencyId },
    purchase = @() buy_booster(effect, currencyId, price),
    bqInfo
  })
}

return purchaseBooster