from "%globalsDarg/darg_library.nut" import *
let logShop = log_with_prefix("[SHOP] ")
let { playSound } = require("sound_wt")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { buy_personal_goods, personalGoodsInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { getGoodsLocName } = require("%rGui/shop/goodsView/goods.nut")
let { PURCH_SRC_SHOP, getPurchaseTypeByGoodsType, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")


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
  function purchase() {
    if (personalGoodsInProgress.get() != null)
      logShop("personalGoodsInProgress")
    else
      buy_personal_goods(goodsId, groupId, varId, currencyId, price, "onShopGoodsPurchase")
  }

  openMsgBoxPurchase({
    text = loc("shop/needMoneyQuestion", { item = colorize(userlogTextColor, getGoodsLocName(shopGoods).replace(" ", nbsp)) }),
    price = { price = price, currencyId },
    purchase,
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_SHOP, getPurchaseTypeByGoodsType(shopGoods.gtype), $"pack {pGoods.id}")
  })
  playSound(currencyId == GOLD ? "meta_products_for_gold" : "meta_products_for_money")
}


return {
  purchasePersonalGoods
}