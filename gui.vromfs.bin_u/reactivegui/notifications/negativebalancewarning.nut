from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { SC_GOLD } = require("%rGui/shop/shopCommon.nut")
let { openShopWnd } = require("%rGui/shop/shopState.nut")

let MSG_ID = "negativeBalanceWarning"

function showNegativeBalanceWarning() {
  if (!isLoggedIn.value)
    return

  openMsgBox({
    uid = MSG_ID
    text = loc("revoking_fraudulent_purchases")
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "purchase", styleId = "PRIMARY", isDefault = true,
        cb = @() openShopWnd(SC_GOLD)
      }
    ]
  })
}

eventbus_subscribe("showNegativeBalanceWarning", @(_) showNegativeBalanceWarning())