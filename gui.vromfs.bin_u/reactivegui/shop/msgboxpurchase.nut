from "%globalsDarg/darg_library.nut" import *
let { balance, WP, GOLD, PLATINUM } = require("%appGlobals/currenciesState.nut")
let { getBaseCurrency } = require("%appGlobals/config/currencyPresentation.nut")
let { mkCurrencyComp, CS_NO_BALANCE, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { openMsgBox, msgBoxText, closeMsgBox } = require("%rGui/components/msgBox.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { openShopWndByCurrencyId } = require("%rGui/shop/shopState.nut")
let { openBuyEventCurrenciesWnd } = require("%rGui/event/buyEventCurrenciesState.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")

let NO_BALANCE_UID = "no_balance_msg"
let PURCHASE_BOX_UID = "purchase_msg_box"

let openBuyWnd = {
  [WP] = @(bqInfo) openShopWndByCurrencyId(WP, bqInfo),
  [GOLD] = @(bqInfo) openShopWndByCurrencyId(GOLD, bqInfo),
  [PLATINUM] = @(bqInfo) openShopWndByCurrencyId(PLATINUM, bqInfo),
}

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  color = 0xFFC0C0C0
  text
}.__update(fontSmall)

function showNoBalanceMsg(price, currencyId, bqInfo, onGoToShop, onCancel = null) {
  let notEnough = Computed(@() price - (balance.value?[currencyId] ?? 0))
  notEnough.subscribe(@(v) v <= 0 ? closeMsgBox(NO_BALANCE_UID) : null)
  let replaceTable = {
    ["{price}"] = mkCurrencyComp(price, currencyId), 
    ["{priceDiff}"] = @() { 
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
      { id = "cancel", isCancel = true, cb = onCancel }
      { id = "replenish", styleId = "PRIMARY", isDefault = true,
        function cb() {
          let cId = getBaseCurrency(currencyId)
          if (cId in openBuyWnd)
            openBuyWnd[cId](bqInfo)
          else
            openBuyEventCurrenciesWnd(cId)
          onGoToShop?()
        }
      }
    ]
  })
}

function showNoBalanceMsgIfNeed(price, currencyId, bqInfo, onGoToShop = null, onCancel = null) {
  let hasBalance = (balance.value?[currencyId] ?? 0) >= price
  if (hasBalance)
    return false

  showNoBalanceMsg(price, currencyId, bqInfo, onGoToShop, onCancel)
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

function openMsgBoxPurchase(text, price, purchase, bqInfo, title = null, onCancel = null, purchaseLocId = "msgbox/btn_purchase", onGoToShop = null) {
  let priceComp = []
  let priceList = type(price) == "array" ? price : [price]
  foreach(p in priceList) {
    if (showNoBalanceMsgIfNeed(p.price, p.currencyId, bqInfo, onGoToShop, onCancel))
      return

    priceComp.append(
      mkCurrencyComp(decimalFormat(p.price), p.currencyId, CS_INCREASED_ICON)
        .__update({ margin = [ hdpx(25), 0, 0, 0 ] })
    )
  }

  openMsgBox({
    uid = PURCHASE_BOX_UID
    text = msgContent(text, priceComp),
    buttons = [
      { id = "cancel", cb = onCancel, isCancel = true }
      { text = loc(purchaseLocId), cb = purchase, styleId = "PURCHASE", isDefault = true, key = "purchase_tutor_btn" }
    ],
    title
  })
}

function closePurchaseAndBalanceBoxes() {
  closeMsgBox(PURCHASE_BOX_UID)
  closeMsgBox(NO_BALANCE_UID)
}

return {
  showNoBalanceMsgIfNeed
  openMsgBoxPurchase = kwarg(openMsgBoxPurchase)
  PURCHASE_BOX_UID
  closePurchaseAndBalanceBoxes
}
