from "%globalsDarg/darg_library.nut" import *
let { decoratorInProgress, set_current_decorator, buy_decorator, registerHandler
} = require("%appGlobals/pServer/pServerApi.nut")
let { allDecorators, myDecorators } = require("decoratorState.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")

registerHandler("onDecoratorPurchaseResult",
  function onUnitPurchaseResult(res, context) {
    if (res?.error != null)
      return
    let { decId } = context
    set_current_decorator(decId)
  })

function purchaseDecorator(decId, localizedName, bqPurchaseInfo) {
  if (decoratorInProgress.value != null)
    return
  if (decId in myDecorators.value) {
    logerr("Try to purchase own decorator")
    return
  }

  let decor = allDecorators.value?[decId]
  if (decor == null)
    return

  let { price = 0, currencyId = "" } = decor?.price
  if (price <= 0) {
    logerr("Try to purchase decorator without price")
    return
  }

  let purchaseFunc = @()
    buy_decorator(decId, currencyId, price, { id = "onDecoratorPurchaseResult", decId })

  openMsgBoxPurchase(
    loc("shop/needMoneyQuestion",
      { item = colorize(userlogTextColor, localizedName) }),
    decor.price,
    purchaseFunc,
    bqPurchaseInfo)
}

return purchaseDecorator
