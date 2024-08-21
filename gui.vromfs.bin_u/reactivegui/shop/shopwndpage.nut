from "%globalsDarg/darg_library.nut" import *
let { floor, ceil } = require("%sqstd/math.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { SGT_UNIT, SGT_CONSUMABLES } = require("%rGui/shop/shopConst.nut")
let { curCategoryId, goodsByCategory, sortGoods, openShopWnd, goodsLinks } = require("%rGui/shop/shopState.nut")
let { actualSchRewardByCategory, onSchRewardReceive } = require("schRewardsState.nut")
let { purchasesCount } = require("%appGlobals/pServer/campaign.nut")
let { shopPurchaseInProgress, schRewardInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { PURCHASING, DELAYED, NOT_READY, HAS_PURCHASES } = require("goodsStates.nut")
let { purchaseGoods } = require("purchaseGoods.nut")
let { buyPlatformGoods, platformPurchaseInProgress, isGoodsOnlyInternalPurchase
} = require("platformGoods.nut")
let { mkGoods } = require("%rGui/shop/goodsView/goods.nut")
let { goodsW, goodsH, goodsGap, goodsGlareAnimDuration  } = require("%rGui/shop/goodsView/sharedParts.nut")
let { canShowAds } = require("%rGui/ads/adsState.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { itemsOrderFull } = require("%appGlobals/itemsState.nut")
let { orderByCurrency } = require("%appGlobals/currenciesState.nut")
let premIconWithTimeOnChange = require("%rGui/mainMenu/premIconWithTimeOnChange.nut")
let { mkItemsBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { gamercardGap } = require("%rGui/components/currencyStyles.nut")
let { SC_CONSUMABLES } = require("shopCommon.nut")
let { gamercardHeight, mkLeftBlock, mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { openMsgBox, msgBoxText } = require("%rGui/components/msgBox.nut")


let tabTranslateWithOpacitySwitchAnim = [
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.4, easing = InQuart, play = true }
  { prop = AnimProp.translate, from = [50, 0], to = [0, 0], duration = 0.5, easing = OutQuad, play = true }

  { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.1, easing = OutQuad, playFadeOut = true }
  { prop = AnimProp.translate, from = [0, 0], to = [50, 0], duration = 0.1, easing = OutQuad, playFadeOut = true }
]

let goodsGlareRepeatDelay = 3

let positive = @(id, value) value > 0 ? { id, value } : null
let goodsCompareCfg = [
  @(g) g.units.len() > 0 || (g?.unitUpgrades.len() ?? 0) > 0 ? { canCompare = false } : null,
  @(g) positive("premiumDays", g.premiumDays),
  function(g) {
    if (g.items.len() > 1)
      return { canCompare = false }
    foreach (itemId, count in g.items)
      return positive(itemId, count) // -unconditional-terminated-loop
    return null
  },
  function(g) {
    if (g.currencies.len() > 1)
      return { canCompare = false }
    foreach (id, count in g.currencies)
      return positive(id, count) // -unconditional-terminated-loop
    return null
  }
]

let function goodsNotAvailToPurch(goods){
  if ("ircm_kit" in goods.items && goods.items.len() == 1 && goods.gtype == SGT_CONSUMABLES){
    local canBuyCountermeasure = false
    foreach(unit in myUnits.get()){
      if (getUnitTagsCfg(unit.name ?? "")?.Shop.weapons.countermeasure_launcher_ship != null){
        canBuyCountermeasure = true
        break
      }
    }
    if (!canBuyCountermeasure){
      openMsgBox({
        text = msgBoxText(loc("shop/cantBuyCountermeasure"))
      })
      return true
    }
  }
  return false
}

let function purchaseFunc(goods) {
  if (goodsNotAvailToPurch(goods))
    return
  if (goods.price.price > 0 && goods.price.currencyId != "")
    return purchaseGoods(goods.id)
  buyPlatformGoods(goods.id)
}

let mkGoodsState = @(goods) Computed(function() {
  local res = 0
  let idInProgress = isGoodsOnlyInternalPurchase(goods) ? shopPurchaseInProgress.value
    : platformPurchaseInProgress.value
  if (idInProgress != null) {
    res = res | DELAYED
    if (idInProgress == goods.id)
      res = res | PURCHASING
  }
  foreach(id in goodsLinks.get()?[goods.id] ?? [goods.id])
    if ((purchasesCount.value?[id].count ?? 0) != 0) {
      res = res | HAS_PURCHASES
      break
    }
  return res
})

let mkSchRewardState = @(schReward) Computed(function() {
  local res = schRewardInProgress.value == schReward.id ? PURCHASING : 0
  if (schReward.needAdvert && !canShowAds.value)
    res = res | NOT_READY
  return res
})

function getGoodsCompareData(goods) {
  local res = null
  foreach (calc in goodsCompareCfg) {
    let data = calc(goods)
    if (data == null)
      continue
    if (res != null || !(data?.canCompare ?? true)) //complex goods can't be compared
      return null
    res = data
  }
  return res
}

function mkGoodsListWithBaseValue(goodsListBase) {
  let goodsList = []
  let goodsCompares = {}
  foreach (g in goodsListBase) {
    let goods = clone g
    goodsList.append(goods)
    let data = getGoodsCompareData(goods)
    if (data == null)
      continue
    let { id, value } = data
    if (value == 0)
      continue
    goodsCompares[id] <- (goodsCompares?[id] ?? []).append({ goods, baseValue = data.value })
  }

  foreach (list in goodsCompares) {
    if (list.len() < 2)
      continue
    let byCurrencyId = {}
    foreach (data in list) {
      let { price = null, priceExt = null } = data.goods
      local priceData = (price?.price ?? 0) > 0 ? price : priceExt
      let { currencyId = "" } = priceData
      if (currencyId != "" && (priceData?.price ?? 0) > 0)
        byCurrencyId[currencyId] <- (byCurrencyId?[currencyId] ?? [])
          .append(data.__merge({ pricePerPoint = priceData.price.tofloat() / data.baseValue }))
    }

    foreach (subList in byCurrencyId) {
      if (subList.len() < 2)
        continue
      let worstPrice = subList.reduce(@(res, d) max(res, d.pricePerPoint), 0)
      foreach (data in subList) {
        let viewBaseValue = (data.pricePerPoint / worstPrice * data.baseValue + 0.5).tointeger()
        if (viewBaseValue < data.baseValue)
          data.goods.viewBaseValue <- viewBaseValue
      }
    }
  }

  return goodsList
}

function onGoodsClick(goods) {
  if (goods.gtype == SGT_UNIT)
    openGoodsPreview(goods.id)
  else
    purchaseFunc(goods)
}

let gamercardShopItemsBalanceBtns = @(items) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = items.map(@(id) mkItemsBalance(id, @() openShopWnd(SC_CONSUMABLES)))
}

let mkShopGamercard = @(onClose) function(){
  let currencies = {}
  let items = {}
  local premiumDays = 0
  foreach (goods in goodsByCategory.get()?[curCategoryId.get()] ?? []) {
    if(goods.price.currencyId != "")
      currencies[goods.price.currencyId] <- true
    currencies.__update(goods.currencies)
    items.__update(goods.items)
    premiumDays += goods.premiumDays
  }
  let orderItems = items.keys().sort(@(a,b)
    itemsOrderFull.findindex(@(v) v == a) <=> itemsOrderFull.findindex(@(v) v == b))
  return {
    watch = [ goodsByCategory, curCategoryId ]
    size = [ saSize[0], gamercardHeight ]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = gamercardGap
    children = [
      mkLeftBlock(onClose)
      {size = flex()}
      premiumDays > 0 ? premIconWithTimeOnChange : null
      gamercardShopItemsBalanceBtns(orderItems)
      mkCurrenciesBtns(currencies.keys().sort(@(a, b) orderByCurrency[a] <=> orderByCurrency[b]),
        null,
        {size = SIZE_TO_CONTENT} )
    ]
  }
}

let mkShopPage = @(pageW, pageH) function() {
  let goodsListBase = Computed(@() goodsByCategory.get()?[curCategoryId.get()] ?? [])
  let schReward = Computed(@() actualSchRewardByCategory.get()?[curCategoryId.get()])

  let hasSchReward = schReward.get() != null

  let goodsList = mkGoodsListWithBaseValue(goodsListBase.get())
  goodsList.sort(sortGoods)
  let goodsTotal = goodsList.len() + (hasSchReward ? 1 : 0)
  let maxGoodsPerW = floor((pageW + goodsGap + 1) / (goodsW + goodsGap))
  let maxGoodsPerH = floor((pageH + goodsGap + 1) / (goodsH + goodsGap))
  let goodsPerW = max(min(goodsTotal, maxGoodsPerW, 1), ceil(goodsTotal * 1.0 / maxGoodsPerH))

  let allRows = []
  if (hasSchReward)
    allRows.append(schReward.get())
  allRows.extend(goodsList)
  let rows = arrayByRows(allRows, goodsPerW)

  let resultRows = rows
    .map(@(row, rowIdx) row
      .map(function(good, goodIdx) {
        if (rowIdx == 0 && good == schReward.get())
          return mkGoods(
            good,
            @() onSchRewardReceive(good),
            mkSchRewardState(good),
            {
              delay = goodsGlareRepeatDelay,
              repeatDelay = goodsGlareAnimDuration * rows[0].len()
            }
          )
        return mkGoods(
          good,
          @() onGoodsClick(good),
          mkGoodsState(good),
          {
            delay = goodIdx * goodsGlareAnimDuration + goodsGlareRepeatDelay + rowIdx * goodsGlareAnimDuration / 3
            repeatDelay = goodsGlareAnimDuration * (rows[0].len() - goodIdx) - rowIdx * goodsGlareAnimDuration / 3
          }
        )
      })
    )

  return {
    watch = [ goodsListBase, curCategoryId, schReward ]
    children = {
      key = curCategoryId.get()
      flow = FLOW_VERTICAL
      gap = goodsGap
      children = resultRows.map(@(children) {
        flow = FLOW_HORIZONTAL
        gap = goodsGap
        children
      })
      transform = {}
      animations = tabTranslateWithOpacitySwitchAnim
    }
  }
}

return {
  mkShopPage
  onGoodsClick
  mkGoodsListWithBaseValue
  mkGoodsState
  mkShopGamercard
}
