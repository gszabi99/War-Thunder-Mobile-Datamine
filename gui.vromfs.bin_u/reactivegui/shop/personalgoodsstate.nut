from "%globalsDarg/darg_library.nut" import *
let logShop = log_with_prefix("[SHOP] ")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { playSound } = require("sound_wt")
let { isEqual } = require("%sqstd/underscore.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { check_new_personal_goods, buy_personal_goods, personalGoodsInProgress
} = require("%appGlobals/pServer/pServerApi.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isServerTimeValid, getServerTime } = require("%appGlobals/userstats/serverTime.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { SC_FEATURED } = require("shopConst.nut")
let { PURCH_SRC_SHOP, getPurchaseTypeByGoodsType, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { getGoodsLocName } = require("%rGui/shop/goodsView/goods.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")


let personalGoodsCfg = Computed(@() serverConfigs.get()?.personalGoodsCfg ?? {})
let personalGoods = Computed(@() servProfile.get()?.personalGoods ?? {})
let pGoodsRelevance = Watched({})
let needRefresh = Computed(@() isServerTimeValid.get() && isLoggedIn.get()
  && null != pGoodsRelevance.get().findindex(@(r) !r))
let shouldRefreshRequest = keepref(Computed(@() needRefresh.get() && isInMenu.get()))

let prevIfEqual = @(prev, cur) isEqual(cur, prev) ? prev : cur

function updateRelevance() {
  if (!isServerTimeValid.get()) {
    pGoodsRelevance.set({})
    return
  }

  let time = getServerTime()
  let relevance = {}
  local nextTime = 0
  foreach (goodsId, _ in personalGoodsCfg.get()) {
    let { endTime = 0 } = personalGoods.get()?[goodsId]
    relevance[goodsId] <- endTime > time
    if (endTime > time && (nextTime == 0 || endTime < nextTime))
      nextTime = endTime
  }
  pGoodsRelevance.set(relevance)

  let timeToUpdate = nextTime - time
  if (timeToUpdate <= 0)
    clearTimer(updateRelevance)
  else
    resetTimeout(timeToUpdate, updateRelevance)
}
pGoodsRelevance.whiteListMutatorClosure(updateRelevance)
updateRelevance()

foreach (w in [isServerTimeValid, personalGoodsCfg, personalGoods])
  w.subscribe(@(_) updateRelevance())

let personalGoodsRewards = Computed(function(prev) {
  let res = {}
  foreach (goodsId, cfg in personalGoodsCfg.get()) {
    if (!(pGoodsRelevance.get()?[goodsId] ?? false))
      continue
    let cur = personalGoods.get()?[goodsId]
    if (cur == null)
      continue
    let { groupId, varId } = cur
    let groupCfg = cfg?[groupId]
    if (groupCfg == null)
      continue
    let { price, discountInPercent, variants, lifeTime } = groupCfg
    let { goods = null } = variants?[varId]
    if (goods == null)
      continue
    res[goodsId] <- cur.__merge({ id = goodsId, goods, price, discountInPercent, lifeTime })
  }

  return prevIfEqual(prev, res)
})

let personalGoodsByShopCategory = Computed(@() personalGoodsRewards.get().len() == 0 ? {}
  : {
      [SC_FEATURED] = personalGoodsRewards.get().values().sort(@(a, b) a.endTime <=> b.endTime)
    })

shouldRefreshRequest.subscribe(@(v) v ? check_new_personal_goods() : null)
if (shouldRefreshRequest.get() && personalGoodsInProgress.get() == null)
  check_new_personal_goods()

function purchasePersonalGoods(pGoods, shopGoods) { //shopGoods need only to allow simple use some shop methods, which use other format
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
  function purchaseFunc() {
    if (personalGoodsInProgress.get() != null)
      logShop("personalGoodsInProgress")
    else
      buy_personal_goods(goodsId, groupId, varId, currencyId, price, "onShopGoodsPurchase")
  }

  openMsgBoxPurchase(
    loc("shop/needMoneyQuestion", { item = colorize(userlogTextColor, getGoodsLocName(shopGoods).replace(" ", nbsp)) }),
    { price = price, currencyId },
    purchaseFunc,
    mkBqPurchaseInfo(PURCH_SRC_SHOP, getPurchaseTypeByGoodsType(shopGoods.gtype), $"pack {pGoods.id}"))
  playSound(currencyId == GOLD ? "meta_products_for_gold" : "meta_products_for_money")
}

return {
  personalGoodsRewards
  personalGoodsByShopCategory
  purchasePersonalGoods
}