from "%globalsDarg/darg_library.nut" import *
let { balance, WARBOND, EVENT_KEY, WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { mkCurrencyComp, CS_NO_BALANCE, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { openMsgBox, msgBoxText, closeMsgBox } = require("%rGui/components/msgBox.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { openShopWndByCurrencyId } = require("%rGui/shop/shopState.nut")
let { openBuyWarbondsWnd, openBuyEventKeysWnd } = require("%rGui/event/buyEventCurrenciesState.nut")

let NO_BALANCE_UID = "no_balance_msg"

let openBuyWnd = {
  [WP] = @(bqPurchaseInfo) openShopWndByCurrencyId(WP, bqPurchaseInfo),
  [GOLD] = @(bqPurchaseInfo) openShopWndByCurrencyId(GOLD, bqPurchaseInfo),
  [WARBOND] = @(_) openBuyWarbondsWnd(),
  [EVENT_KEY] = @(_) openBuyEventKeysWnd()
}

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  color = 0xFFC0C0C0
  text
}.__update(fontSmall)

let function showNoBalanceMsg(price, currencyId, bqPurchaseInfo, onGoToShop) {
  let canReplenish = currencyId in openBuyWnd
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
      children = !canReplenish ? mkText(loc("insufficientFunds"))
        : loc("shop/askRefillOnNotEnoughMoney")
            .split("\n")
            .map(@(text) {
              flow = FLOW_HORIZONTAL
              minHeight = hdpx(30)
              valign = ALIGN_CENTER
              children = mkTextRow(text.replace("\r", ""), mkText, replaceTable)
            })
    }
    buttons = !canReplenish ? [ { id = "ok", styleId = "PRIMARY", isDefault = true } ]
      : [
          { id = "cancel", isCancel = true }
          { id = "replenish", styleId = "PRIMARY", isDefault = true,
            function cb() {
              openBuyWnd[currencyId](bqPurchaseInfo)
              onGoToShop?()
            }
          }
        ]
  })
}

let function showNoBalanceMsgIfNeed(price, currencyId, bqPurchaseInfo, onGoToShop = null) {
  let hasBalance = (balance.value?[currencyId] ?? 0) >= price
  if (hasBalance)
    return false

  showNoBalanceMsg(price, currencyId, bqPurchaseInfo, onGoToShop)
  return true
}

let msgContent = @(text, priceComp) {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    msgBoxText(text, { size = [flex(), SIZE_TO_CONTENT] })
    {
      flow = FLOW_HORIZONTAL
      gap = hdpx(32)
      children = priceComp
    }
  ]
}

let function openMsgBoxPurchase(text, prices, purchaseFunc, bqPurchaseInfo) {
  let priceComp = []
  let priceList = type(prices) == "array" ? prices : [prices]

  foreach(price in priceList) {
    if (showNoBalanceMsgIfNeed(price.price, price.currencyId, bqPurchaseInfo))
      return

    priceComp.append(
      mkCurrencyComp(price.price, price.currencyId, CS_INCREASED_ICON)
        .__update({ margin = [ hdpx(25), 0, 0, 0 ] })
    )
  }

  openMsgBox({
    text = msgContent(text, priceComp),
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "purchase", cb = purchaseFunc, styleId = "PURCHASE", isDefault = true }
    ]
  })
}

return {
  showNoBalanceMsgIfNeed
  openMsgBoxPurchase
}
