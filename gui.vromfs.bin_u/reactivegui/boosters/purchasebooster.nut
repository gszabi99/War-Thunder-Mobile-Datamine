from "%globalsDarg/darg_library.nut" import *
let { boosterInProgress, buy_booster } = require("%appGlobals/pServer/pServerApi.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")

function purchaseBooster(id, localizedName, bqPurchaseInfo) {
  if (boosterInProgress.value != null)
    return

  let booster = serverConfigs.get()?.allBoosters[id]
  if (booster == null)
    return

  let { price = 0, currencyId = "", effect = ""} = booster
  if (price <= 0) {
    logerr("Try to purchase booster without price")
    return
  }
  openMsgBoxPurchase(
    loc("shop/needMoneyQuestion",
      { item = colorize(userlogTextColor, localizedName) }),
    {
      price
      currencyId
    },
    @() buy_booster(effect, currencyId, price),
    bqPurchaseInfo)
  }

  return purchaseBooster