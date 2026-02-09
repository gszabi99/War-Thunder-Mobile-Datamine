from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { unitRewardTypes, statRewardTypes } = require("%appGlobals/rewardType.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { balance, WP, GOLD, PLATINUM } = require("%appGlobals/currenciesState.nut")
let { getBaseCurrency } = require("%appGlobals/config/currencyPresentation.nut")
let { activeOffers } = require("%appGlobals/pServer/campaign.nut")
let { commonTextColor } = require("%rGui/style/stdColors.nut")
let { mkCurrencyComp, CS_NO_BALANCE, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { openMsgBox, msgBoxText, closeMsgBox, wndWidthDefault } = require("%rGui/components/msgBox.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { openShopWndByCurrencyId, shopGoods } = require("%rGui/shop/shopState.nut")
let { openBuyEventCurrenciesWnd } = require("%rGui/event/buyEventCurrenciesState.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { spendingUnlocks } = require("%rGui/unlocks/unlocks.nut")
let { mkQuestDesc } = require("%rGui/shop/msgQuestDesc.nut")


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
  let notEnough = Computed(@() price - (balance.get()?[currencyId] ?? 0))
  notEnough.subscribe(@(v) v <= 0 ? closeMsgBox(NO_BALANCE_UID) : null)
  let replaceTable = {
    ["{price}"] = mkCurrencyComp(price, currencyId), 
    ["{priceDiff}"] = @() { 
      watch = notEnough
      children = mkCurrencyComp(notEnough.get(), currencyId, CS_NO_BALANCE)
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
  let hasBalance = (balance.get()?[currencyId] ?? 0) >= price
  if (hasBalance)
    return false

  showNoBalanceMsg(price, currencyId, bqInfo, onGoToShop, onCancel)
  return true
}

function mkSpendingText(currencyId, goodsId, spendingCountry) {
  let country = spendingCountry != null ? Watched(spendingCountry)
    : Computed(function() {
        let goods = activeOffers.get()?.id == goodsId ? activeOffers.get() : shopGoods.get()?[goodsId]
        let { allUnits = {}, currencyStats = {} } = serverConfigs.get()
        foreach (r in goods?.rewards ?? {}) {
          let country = r.gType in unitRewardTypes ? allUnits?[r.id].country
            : r.gType in statRewardTypes ? currencyStats?[currencyId].findindex(@(v) v == r.id)
            : null
          if (country != null)
            return country
        }
        return null
      })
  return @() {
    watch = [spendingUnlocks, country]
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    children = mkQuestDesc(currencyId, spendingUnlocks.get(), country.get())
  }
}

let msgContent = @(text, priceComp, limitCountText, price, goodsId, hasSpendingStat, spendingCountry) {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(25)
  children = [
    type(text) == "string" ? msgBoxText(text, { size = FLEX_H }) : text
    {
      flow = FLOW_HORIZONTAL
      gap = hdpx(32)
      children = priceComp
    }
    !limitCountText ? null : {
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc("item/balance", {count = limitCountText}))
      color = commonTextColor
    }.__update(fontSmall)
    hasSpendingStat ? mkSpendingText(price.currencyId, goodsId, spendingCountry) : null
  ].filter(@(v) v != null)
}

function openMsgBoxPurchase(
  text,
  price,
  purchase,
  bqInfo,
  title = null,
  onCancel = null,
  purchaseLocId = "msgbox/btn_purchase",
  onGoToShop = null,
  limitCountText = null,
  goodsId = null,
  hasSpendingStat = true,
  spendingCountry = null,
) {
  let priceComp = []
  let priceList = type(price) == "array" ? price : [price]
  foreach(p in priceList) {
    if (showNoBalanceMsgIfNeed(p.price, p.currencyId, bqInfo, onGoToShop, onCancel))
      return

    priceComp.append(
      mkCurrencyComp(decimalFormat(p.price), p.currencyId, CS_INCREASED_ICON)
    )
  }

  openMsgBox({
    uid = PURCHASE_BOX_UID
    text = msgContent(text, priceComp, limitCountText, price, goodsId, hasSpendingStat, spendingCountry),
    buttons = [
      { id = "cancel", cb = onCancel, isCancel = true, key = "purchase_cancel_btn" }
      { text = loc(purchaseLocId), cb = purchase, styleId = "PURCHASE", isDefault = true, key = "purchase_tutor_btn" }
    ],
    title
    wndOvr = { size = [wndWidthDefault, hdpx(750)] }
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
