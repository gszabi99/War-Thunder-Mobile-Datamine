from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { onlineBattleBlockCurrencyId, balance, PLATINUM, GOLD
} = require("%appGlobals/currenciesState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { SC_GOLD, SC_PLATINUM } = require("%rGui/shop/shopCommon.nut")
let { openShopWnd } = require("%rGui/shop/shopState.nut")
let { badTextColor2, highlightTextColor } = require("%rGui/style/stdColors.nut")


let MSG_ID = "negativeBalanceWarning"

let currencyStoreCategory = {
  [PLATINUM] = SC_PLATINUM,
  [GOLD] = SC_GOLD,
}

function showNegativeBalanceWarning() {
  if (!isLoggedIn.get() || onlineBattleBlockCurrencyId.get() == null)
    return false

  let currencyId = onlineBattleBlockCurrencyId.get()
  let amount = balance.get()?[currencyId] ?? 0
  let amountText = loc($"shop/item/{currencyId}/amount", { amount, amountTxt = colorize(badTextColor2, amount) })
  openMsgBox({
    uid = MSG_ID
    text = loc("revoking_fraudulent_purchases",
      { amountText = colorize(highlightTextColor, amountText) })
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "purchase", styleId = "PRIMARY", isDefault = true,
        cb = @() openShopWnd(currencyStoreCategory?[currencyId])
      }
    ]
  })
  return true
}

eventbus_subscribe("showNegativeBalanceWarning", @(_) showNegativeBalanceWarning())

return showNegativeBalanceWarning