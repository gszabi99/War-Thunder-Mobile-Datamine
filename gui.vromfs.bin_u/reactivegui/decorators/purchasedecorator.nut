from "%globalsDarg/darg_library.nut" import *
let { decoratorInProgress, set_current_decorator, buy_decorator, registerHandler
} = require("%appGlobals/pServer/pServerApi.nut")
let { currencyToFullId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { allDecorators, myDecorators } = require("%rGui/decorators/decoratorState.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")

registerHandler("onDecoratorPurchaseResult",
  function onUnitPurchaseResult(res, context) {
    if (res?.error != null)
      return
    let { decId } = context
    set_current_decorator(decId)
  })

function purchaseDecorator(decId, localizedName, bqInfo) {
  if (decoratorInProgress.get() != null)
    return
  if (decId in myDecorators.get()) {
    logerr("Try to purchase own decorator")
    return
  }

  let decor = allDecorators.get()?[decId]
  if (decor == null)
    return

  let { price = 0, currencyId = "" } = decor?.price
  if (price <= 0) {
    logerr("Try to purchase decorator without price")
    return
  }
  let currencyFullId = currencyToFullId.get()?[currencyId] ?? currencyId

  openMsgBoxPurchase({
    text = loc("shop/needMoneyQuestion",
      { item = colorize(userlogTextColor, localizedName) }),
    price = { price, currencyId = currencyFullId },
    purchase = @() buy_decorator(decId, currencyFullId, price, { id = "onDecoratorPurchaseResult", decId }),
    bqInfo
  })
}

return purchaseDecorator
