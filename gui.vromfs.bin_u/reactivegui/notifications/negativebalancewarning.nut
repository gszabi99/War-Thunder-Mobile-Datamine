from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%appGlobals/currenciesState.nut" import onlineBattleBlockCurrencyId, balance, PLATINUM, GOLD
from "%appGlobals/loginState.nut" import isLoggedIn
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/shop/shopCommon.nut" import SC_GOLD, SC_PLATINUM
from "%rGui/shop/shopState.nut" import openShopWnd
from "%rGui/style/stdColors.nut" import badTextColor2, highlightTextColor


const MSG_ID = "negativeBalanceWarning"

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