from "%globalsDarg/darg_library.nut" import *
from "sound_wt" import playSound
from "%appGlobals/currenciesState.nut" import GOLD
from "%appGlobals/pServer/pServerApi.nut" import buy_personal_goods, personalGoodsInProgress
from "%appGlobals/pServer/seasonCurrencies.nut" import currencyToFullId
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_SHOP, getPurchaseTypeByGoodsType, mkBqPurchaseInfo
from "%rGui/shop/goodsView/goods.nut" import getGoodsLocName
from "%rGui/shop/msgBoxPurchase.nut" import openMsgBoxPurchase
from "%rGui/shop/shopCommon.nut" import getGoodsType
from "%rGui/style/stdColors.nut" import userlogTextColor


let logShop = log_with_prefix("[SHOP] ")


function purchasePersonalGoods(pGoods, shopGoods) { 
  logShop($"User tries to purchase: {pGoods.id}")
  if (personalGoodsInProgress.get() != null)
    return logShop($"ERROR: personalGoodsInProgress: {personalGoodsInProgress.get()}")

  let { isPurchased, goodsId, groupId, varId } = pGoods
  if (isPurchased) {
    logShop("Already purchased")
    openMsgBox({ text = loc("shop/personalGoods/alreadyBought") })
    return
  }

  let { price, currencyId } = pGoods.price
  let currencyFullId = currencyToFullId.get()?[currencyId] ?? currencyId
  function purchase() {
    if (personalGoodsInProgress.get() != null)
      logShop("personalGoodsInProgress")
    else
      buy_personal_goods(goodsId, groupId, varId, currencyFullId, price, "onShopGoodsPurchase")
  }

  openMsgBoxPurchase({
    text = loc("shop/needMoneyQuestion", { item = colorize(userlogTextColor, getGoodsLocName(shopGoods).replace(" ", nbsp)) }),
    price = { price = price, currencyId = currencyFullId },
    purchase,
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_SHOP, getPurchaseTypeByGoodsType(getGoodsType(shopGoods)), $"pack {pGoods.id}")
  })
  playSound(currencyId == GOLD ? "meta_products_for_gold" : "meta_products_for_money")
}


return {
  purchasePersonalGoods
}