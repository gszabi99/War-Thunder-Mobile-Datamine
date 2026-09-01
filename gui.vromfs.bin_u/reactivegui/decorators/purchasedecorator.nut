from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/pServerApi.nut" import decoratorInProgress, set_current_decorator, buy_decorator,
  registerHandler
from "%appGlobals/pServer/seasonCurrencies.nut" import currencyToFullId
from "%rGui/decorators/decoratorState.nut" import allDecorators, myDecorators
from "%rGui/shop/msgBoxPurchase.nut" import openMsgBoxPurchase
from "%rGui/style/stdColors.nut" import userlogTextColor


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
