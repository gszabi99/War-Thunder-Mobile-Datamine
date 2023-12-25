from "%globalsDarg/darg_library.nut" import *
let { floor, ceil } = require("%sqstd/math.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { SGT_UNIT } = require("%rGui/shop/shopConst.nut")
let { curCategoryId, goodsByCategory, sortGoods } = require("%rGui/shop/shopState.nut")
let { actualSchRewardByCategory, onSchRewardReceive } = require("schRewardsState.nut")
let { purchasesCount } = require("%appGlobals/pServer/campaign.nut")
let { shopPurchaseInProgress, schRewardInProgress
} = require("%appGlobals/pServer/pServerApi.nut")
let { PURCHASING, DELAYED, NOT_READY, HAS_PURCHASES } = require("goodsStates.nut")
let purchaseGoods = require("purchaseGoods.nut")
let { buyPlatformGoods, platformPurchaseInProgress, isGoodsOnlyInternalPurchase
} = require("platformGoods.nut")
let { mkGoods } = require("%rGui/shop/goodsView/goods.nut")
let { goodsW, goodsH, goodsGap, goodsGlareAnimDuration  } = require("%rGui/shop/goodsView/sharedParts.nut")
let { canShowAds } = require("%rGui/ads/adsState.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")


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
  @(g) positive("wp", g.wp),
  @(g) positive("gold", g.gold),
  @(g) positive("warbond", g?.warbond ?? 0),
  @(g) positive("eventKey", g?.eventKey ?? 0),
  @(g) positive("nybond", g?.nybond ?? 0),
  @(g) positive("premiumDays", g.premiumDays),
  function(g) {
    if (g.items.len() > 1)
      return { canCompare = false }
    foreach (itemId, count in g.items)
      return positive(itemId, count) // -unconditional-terminated-loop
    return null
  },
]

let purchaseFunc = @(goods) goods.price.price > 0 && goods.price.currencyId != ""
  ? purchaseGoods(goods.id)
  : buyPlatformGoods(goods.id)

let mkGoodsState = @(goods) Computed(function() {
  local res = 0
  let idInProgress = isGoodsOnlyInternalPurchase(goods) ? shopPurchaseInProgress.value
    : platformPurchaseInProgress.value
  if (idInProgress != null) {
    res = res | DELAYED
    if (idInProgress == goods.id)
      res = res | PURCHASING
  }
  if ((purchasesCount.value?[goods.id].count ?? 0) != 0)
    res = res | HAS_PURCHASES
  return res
})

let mkSchRewardState = @(schReward) Computed(function() {
  local res = schRewardInProgress.value == schReward.id ? PURCHASING : 0
  if (schReward.needAdvert && !canShowAds.value)
    res = res | NOT_READY
  return res
})

let function getGoodsCompareData(goods) {
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

let function mkGoodsListWithBaseValue(goodsListBase) {
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

let function onGoodsClick(goods) {
  if (goods.gtype == SGT_UNIT)
    openGoodsPreview(goods.id)
  else
    purchaseFunc(goods)
}

let mkShopPage = @(pageW, pageH) function() {
  let goodsList = mkGoodsListWithBaseValue(goodsByCategory.value?[curCategoryId.value] ?? [])
  goodsList.sort(sortGoods)
  let schReward = actualSchRewardByCategory.value?[curCategoryId.value]
  let goodsTotal = goodsList.len() + (schReward == null ? 0 : 1)
  let maxGoodsPerW = floor((pageW + goodsGap + 1) / (goodsW + goodsGap))
  let maxGoodsPerH = floor((pageH + goodsGap + 1) / (goodsH + goodsGap))
  let goodsPerW = max(min(goodsTotal, maxGoodsPerW, 1), ceil(goodsTotal * 1.0 / maxGoodsPerH))
  let rows = arrayByRows(schReward != null ? [schReward].extend(goodsList) : goodsList, goodsPerW)

  let resultRows = rows
    .map(@(row, rowIdx) row
      .map(function(good, goodIdx) {
        if (rowIdx == 0 && good == schReward)
          return mkGoods(schReward, @() onSchRewardReceive(schReward), mkSchRewardState(schReward), {
            delay = goodsGlareRepeatDelay,
            repeatDelay = goodsGlareAnimDuration * rows[0].len()
          })
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
    watch = [ goodsByCategory, curCategoryId, actualSchRewardByCategory ]
    children = {
      key = curCategoryId.value
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
}
