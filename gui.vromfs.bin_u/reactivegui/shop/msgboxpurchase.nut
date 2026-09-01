from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
import "%darg/helpers/mkTextRow.nut" as mkTextRow
from "%appGlobals/config/currencyPresentation.nut" import getBaseCurrency
from "%appGlobals/currenciesState.nut" import balance, WP, GOLD, PLATINUM
from "%appGlobals/pServer/campaign.nut" import activeOffers, purchasesCount, todayPurchasesCount, goodsLimitReset
from "%appGlobals/pServer/seasonCurrencies.nut" import currencyToFullId
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/rewardType.nut" import unitRewardTypes, statRewardTypes, G_CURRENCY
from "%appGlobals/userstats/serverTimeDay.nut" import serverTimeDay, dayOffset
from "%rGui/components/currencyComp.nut" import mkCurrencyComp, CS_NO_BALANCE, CS_INCREASED_ICON
from "%rGui/components/msgBox.nut" import openMsgBox, msgBoxText, closeMsgBox, wndWidthDefault
from "%rGui/event/buyEventCurrenciesState.nut" import openBuyEventCurrenciesWnd
from "%rGui/shop/goodsPreviewState.nut" import openGoodsPreview
from "%rGui/shop/goodsUtils.nut" import getGoodsByCurrencyId
from "%rGui/shop/msgQuestDesc.nut" import mkQuestDesc
from "%rGui/shop/shopState.nut" import openShopWndByCurrencyId, shopGoods
from "%rGui/style/stdColors.nut" import commonTextColor
from "%rGui/textFormatByLang.nut" import decimalFormat
from "%rGui/unlocks/unlocks.nut" import spendingUnlocks
from "types" import String, Array


const NO_BALANCE_UID = "no_balance_msg"
const PURCHASE_BOX_UID = "purchase_msg_box"

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
  let balanceId = Computed(@() currencyToFullId.get()?[currencyId] ?? currencyId)
  let notEnough = Computed(@() price - (balance.get()?[balanceId.get()] ?? 0))
  notEnough.subscribe(@(v) v <= 0 ? closeMsgBox(NO_BALANCE_UID) : null)
  let replaceTable = {
    ["{price}"] = mkCurrencyComp(price, currencyId), 
    ["{priceDiff}"] = @() { 
      watch = notEnough
      children = mkCurrencyComp(notEnough.get(), currencyId, CS_NO_BALANCE)
    },
  }
  let cId = getBaseCurrency(currencyId)
  let hasCurrencyInShop = shopGoods.get().filter(@(g) g.rewards.len() == 1
    && g.rewards[0].gType == G_CURRENCY
    && g.rewards[0].id == cId).len() > 0
  let goodsId = getGoodsByCurrencyId(cId, shopGoods.get(), serverConfigs.get(),
    goodsLimitReset.get(), dayOffset.get(), serverTimeDay.get(), purchasesCount.get(), todayPurchasesCount.get()
  )?.id
  let replenishCb = cId in openBuyWnd ? @() openBuyWnd[cId](bqInfo)
    : hasCurrencyInShop ? @() openBuyEventCurrenciesWnd(cId)
    : goodsId != null ? @() openGoodsPreview(goodsId)
    : null

  openMsgBox({
    uid = NO_BALANCE_UID
    text = {
      size = FLEX
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = loc(replenishCb != null ? "shop/askRefillOnNotEnoughMoney" : "shop/noBalanceMsg")
        .split("\n")
        .map(@(text) {
          flow = FLOW_HORIZONTAL
          minHeight = hdpx(30)
          valign = ALIGN_CENTER
          children = mkTextRow(text.replace("\r", ""), mkText, replaceTable)
        })
    }
    buttons = replenishCb != null ? [
      { id = "cancel", isCancel = true, cb = onCancel }
      { id = "replenish", styleId = "PRIMARY", isDefault = true,
        function cb() {
          replenishCb()
          onGoToShop?()
        }
      }
    ]
    : [
      { id = "ok", isCancel = true, cb = onCancel }
    ]
  })
}

function showNoBalanceMsgIfNeed(price, currencyId, bqInfo, onGoToShop = null, onCancel = null) {
  let balanceId = currencyToFullId.get()?[currencyId] ?? currencyId
  let hasBalance = (balance.get()?[balanceId] ?? 0) >= price
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

let msgContent = @(text, priceComp, limitCountText, price, goodsId, spendingCountry) {
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(25)
  children = [
    text instanceof String ? msgBoxText(text, { size = FLEX_H }) : text
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
    mkSpendingText(price.currencyId, goodsId, spendingCountry)
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
  spendingCountry = null,
) {
  let priceComp = []
  let priceList = price instanceof Array ? price : [price]
  foreach(p in priceList) {
    if (showNoBalanceMsgIfNeed(p.price, p.currencyId, bqInfo, onGoToShop, onCancel))
      return

    priceComp.append(
      mkCurrencyComp(decimalFormat(p.price), p.currencyId, CS_INCREASED_ICON)
    )
  }

  openMsgBox({
    uid = PURCHASE_BOX_UID
    text = msgContent(text, priceComp, limitCountText, priceList[0], goodsId, spendingCountry),
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
