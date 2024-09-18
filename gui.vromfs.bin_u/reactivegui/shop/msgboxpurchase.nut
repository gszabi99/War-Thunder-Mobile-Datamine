from "%globalsDarg/darg_library.nut" import *
let { balance, WP, GOLD, PLATINUM } = require("%appGlobals/currenciesState.nut")
let { mkCurrencyComp, CS_NO_BALANCE, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { openMsgBox, msgBoxText, closeMsgBox } = require("%rGui/components/msgBox.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { openShopWndByCurrencyId } = require("%rGui/shop/shopState.nut")
let { curEvent } = require("%rGui/event/eventState.nut")
let { openBuyEventCurrenciesWnd } = require("%rGui/event/buyEventCurrenciesState.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")

let NO_BALANCE_UID = "no_balance_msg"
let PURCHASE_BOX_UID = "purchase_msg_box"

let openBuyWnd = {
  [WP] = @(bqPurchaseInfo) openShopWndByCurrencyId(WP, bqPurchaseInfo),
  [GOLD] = @(bqPurchaseInfo) openShopWndByCurrencyId(GOLD, bqPurchaseInfo),
  [PLATINUM] = @(bqPurchaseInfo) openShopWndByCurrencyId(PLATINUM, bqPurchaseInfo),
}

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  color = 0xFFC0C0C0
  text
}.__update(fontSmall)

function showNoBalanceMsg(price, currencyId, bqPurchaseInfo, onGoToShop, cancelFunc = null) {
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
      { id = "cancel", isCancel = true, cb = cancelFunc }
      { id = "replenish", styleId = "PRIMARY", isDefault = true,
        function cb() {
          if (currencyId in openBuyWnd)
            openBuyWnd[currencyId](bqPurchaseInfo)
          else
            openBuyEventCurrenciesWnd(currencyId, curEvent.get())
          onGoToShop?()
        }
      }
    ]
  })
}

function showNoBalanceMsgIfNeed(price, currencyId, bqPurchaseInfo, onGoToShop = null, cancelFunc = null) {
  let hasBalance = (balance.value?[currencyId] ?? 0) >= price
  if (hasBalance)
    return false

  showNoBalanceMsg(price, currencyId, bqPurchaseInfo, onGoToShop, cancelFunc)
  return true
}

let msgContent = @(text, priceComp) {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    type(text) == "string" ? msgBoxText(text, { size = [flex(), SIZE_TO_CONTENT] }) : text
    {
      flow = FLOW_HORIZONTAL
      gap = hdpx(32)
      children = priceComp
    }
  ]
}

function openMsgBoxPurchase(text, prices, purchaseFunc, bqPurchaseInfo, title = null, cancelFunc = null, purchaseLocId = "msgbox/btn_purchase") {
  let priceComp = []
  let priceList = type(prices) == "array" ? prices : [prices]
  foreach(price in priceList) {
    if (showNoBalanceMsgIfNeed(price.price, price.currencyId, bqPurchaseInfo, null, cancelFunc))
      return

    priceComp.append(
      mkCurrencyComp(decimalFormat(price.price), price.currencyId, CS_INCREASED_ICON)
        .__update({ margin = [ hdpx(25), 0, 0, 0 ] })
    )
  }

  openMsgBox({
    uid = PURCHASE_BOX_UID
    text = msgContent(text, priceComp),
    buttons = [
      { id = "cancel", cb = cancelFunc, isCancel = true }
      { text = loc(purchaseLocId), cb = purchaseFunc, styleId = "PURCHASE", isDefault = true, key = "purchase_tutor_btn" }
    ],
    title
  })
}

return {
  showNoBalanceMsgIfNeed
  openMsgBoxPurchase
  PURCHASE_BOX_UID
}
