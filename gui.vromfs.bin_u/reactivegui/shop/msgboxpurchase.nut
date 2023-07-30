from "%globalsDarg/darg_library.nut" import *
let { balance } = require("%appGlobals/currenciesState.nut")
let { mkCurrencyComp, CS_NO_BALANCE, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { openMsgBox, msgBoxText, closeMsgBox } = require("%rGui/components/msgBox.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { openShopWndByCurrencyId } = require("%rGui/shop/shopState.nut")

let NO_BALANCE_UID = "no_balance_msg"

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  color = 0xFFC0C0C0
  text
}.__update(fontSmall)

let function showNoBalanceMsg(price, currencyId, onGoToShop) {
  let notEnough = Computed(@() price - (balance.value?[currencyId] ?? 0))
  notEnough.subscribe(@(v) v <= 0 ? closeMsgBox(NO_BALANCE_UID) : null)
  let replaceTable = {
    ["{price}"] = mkCurrencyComp(price, currencyId), //warning disable: -forgot-subst
    ["{priceDiff}"] = @() { //warning disable: -forgot-subst
      watch = notEnough
      children = mkCurrencyComp(notEnough.value, currencyId, CS_NO_BALANCE)
    },
  }
  openMsgBox({
    uid = NO_BALANCE_UID
    text = {
      size = flex()
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = loc("shop/askRefillOnNotEnoughMoney")
        .split("\n")
        .map(@(text) {
          flow = FLOW_HORIZONTAL
          minHeight = hdpx(30)
          valign = ALIGN_CENTER
          children = mkTextRow(text.replace("\r", ""), mkText, replaceTable)
        })
    }
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "replenish", isPrimary = true, isDefault = true,
        function cb() {
          openShopWndByCurrencyId(currencyId)
          onGoToShop?()
        }
      }
    ]
  })
}

let function showNoBalanceMsgIfNeed(price, currencyId, onGoToShop = null) {
  let hasBalance = (balance.value?[currencyId] ?? 0) >= price
  if (hasBalance)
    return false

  showNoBalanceMsg(price, currencyId, onGoToShop)
  return true
}

let msgContent = @(text, priceComp) {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    msgBoxText(text, { size = [flex(), SIZE_TO_CONTENT] })
    priceComp
  ]
}

let function openMsgBoxPurchase(text, price, purchaseFunc) {
  if (showNoBalanceMsgIfNeed(price.price, price.currencyId))
    return

  let priceComp = mkCurrencyComp(price.price, price.currencyId, CS_INCREASED_ICON)
    .__update({ margin = [ hdpx(25), 0, 0, 0 ] })
  openMsgBox({
    text = msgContent(text, priceComp),
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "purchase", cb = purchaseFunc, isPurchase = true, isDefault = true }
    ]
  })
}

return {
  showNoBalanceMsgIfNeed
  openMsgBoxPurchase
}
