from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { SGT_UNIT, SGT_BLUEPRINTS, SGT_SKIN, SGT_CONSUMABLES } = require("%rGui/shop/shopConst.nut")
let { curCategoryId, goodsByCategory, sortGoods, openShopWnd, goodsLinks, subsByCategory, subsGroups
} = require("%rGui/shop/shopState.nut")
let { actualSchRewardByCategory, onSchRewardReceive } = require("%rGui/shop/schRewardsState.nut")
let { personalGoodsByShopCategory } = require("%rGui/shop/personalGoodsState.nut")
let { purchasePersonalGoods } = require("%rGui/shop/personalGoodsPurchase.nut")
let { purchasesCount, curCampaign, subscriptions } = require("%appGlobals/pServer/campaign.nut")
let { shopPurchaseInProgress, schRewardInProgress, personalGoodsInProgress
} = require("%appGlobals/pServer/pServerApi.nut")
let { PURCHASING, DELAYED, HAS_PURCHASES, IS_ACTIVE, HAS_UPGRADE } = require("%rGui/shop/goodsStates.nut")
let { purchaseGoods } = require("%rGui/shop/purchaseGoods.nut")
let { buyPlatformGoods, platformPurchaseInProgress, isGoodsOnlyInternalPurchase
} = require("%rGui/shop/platformGoods.nut")
let { mkGoods } = require("%rGui/shop/goodsView/goods.nut")
let { mkSubscriptionCard } = require("%rGui/shop/goodsView/subscriptionCard.nut")
let { goodsGap, goodsGlareAnimDuration, mkLimitText, bottomPad, mkGoodsTimeProgress
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { openGoodsPreview, openSubsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { itemsOrderFull } = require("%appGlobals/itemsState.nut")
let { orderByCurrency } = require("%appGlobals/currenciesState.nut")
let { sortByCurrencyId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let premIconWithTimeOnChange = require("%rGui/mainMenu/premIconWithTimeOnChange.nut")
let { mkItemsBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { gamercardGap } = require("%rGui/components/currencyStyles.nut")
let { SC_CONSUMABLES } = require("%rGui/shop/shopCommon.nut")
let { gamercardHeight, mkLeftBlock, mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { openMsgBox, msgBoxText } = require("%rGui/components/msgBox.nut")
let { categoryGap, titleGap, goodsPerRow, titleH } = require("%rGui/shop/shopWndConst.nut")
let rewardsToShopGoods = require("%rGui/shop/rewardsToShopGoods.nut")

let goodsGlareRepeatDelay = 3
let glareRowOffsetMul    = 0.18 * goodsGlareAnimDuration
let glareColOffsetMul    = 0.62 * goodsGlareAnimDuration
let glareHeaderOffsetMul = 0.06 * goodsGlareAnimDuration

let tabTranslateWithOpacitySwitchAnim = [
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.4, easing = InQuart, play = true }
  { prop = AnimProp.translate, from = [50, 0], to = [0, 0], duration = 0.5, easing = OutQuad, play = true }

  { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.1, easing = OutQuad, playFadeOut = true }
  { prop = AnimProp.translate, from = [0, 0], to = [50, 0], duration = 0.1, easing = OutQuad, playFadeOut = true }
]

let positive = @(id, value) value > 0 ? { id, value } : null
let goodsCompareCfg = [
  @(g) g.units.len() > 0 || (g?.unitUpgrades.len() ?? 0) > 0 ? { canCompare = false } : null,
  @(g) positive("premiumDays", g.premiumDays),
  function(g) {
    if (g.items.len() > 1)
      return { canCompare = false }
    foreach (itemId, count in g.items)
      return positive(itemId, count) 
    return null
  },
  function(g) {
    if (g.currencies.len() > 1)
      return { canCompare = false }
    foreach (id, count in g.currencies)
      return positive(id, count) 
    return null
  }
]

let function goodsNotAvailToPurch(goods){
  if ("ircm_kit" in goods.items && goods.items.len() == 1 && goods.gtype == SGT_CONSUMABLES){
    local canBuyCountermeasure = false
    foreach(unit in campMyUnits.get()){
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
  let idInProgress = isGoodsOnlyInternalPurchase(goods) ? shopPurchaseInProgress.get()
    : platformPurchaseInProgress.get()
  if (idInProgress != null) {
    res = res | DELAYED
    if (idInProgress == goods.id)
      res = res | PURCHASING
  }
  foreach(id in goodsLinks.get()?[goods.id] ?? [goods.id])
    if (purchasesCount.get()?[id].isFirstPurchaseBonusReceived ?? false) {
      res = res | HAS_PURCHASES
      break
    }
  return res
})

function getGoodsCompareData(goods) {
  local res = null
  foreach (calc in goodsCompareCfg) {
    let data = calc(goods)
    if (data == null)
      continue
    if (res != null || !(data?.canCompare ?? true)) 
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
  if (goods.gtype == SGT_UNIT || goods.gtype == SGT_BLUEPRINTS || goods.gtype == SGT_SKIN)
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
  foreach (goods in personalGoodsByShopCategory.get()?[curCategoryId.get()] ?? []) {
    if (goods.price.currencyId != "")
      currencies[goods.price.currencyId] <- true
    if (goods.varId in orderByCurrency)
      currencies[goods.varId] <- true
  }
  foreach (goods in goodsByCategory.get()?[curCategoryId.get()] ?? []) {
    if(goods.price.currencyId != "")
      currencies[goods.price.currencyId] <- true
    currencies.__update(goods.currencies)
    if (goods.units.len() == 0
      && goods.unitUpgrades.len() == 0
      && goods.blueprints.len() == 0
      && goods.lootboxes.len() == 0)
        items.__update(goods.items)
    premiumDays += goods.premiumDays
  }
  let orderItems = items.keys().sort(@(a,b)
    itemsOrderFull.findindex(@(v) v == a) <=> itemsOrderFull.findindex(@(v) v == b))
  return {
    watch = [ goodsByCategory, curCategoryId, personalGoodsByShopCategory ]
    size = [ saSize[0], gamercardHeight ]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = gamercardGap
    children = [
      mkLeftBlock(onClose)
      {size = flex()}
      premiumDays > 0 ? premIconWithTimeOnChange : null
      gamercardShopItemsBalanceBtns(orderItems)
      mkCurrenciesBtns(currencies.keys().sort(sortByCurrencyId))
        .__update({ size = SIZE_TO_CONTENT })
    ]
  }
}

function mkAnimParams(idx, headers) {
  let col = idx % goodsPerRow
  let row = idx / goodsPerRow
  return {
    delay = goodsGlareRepeatDelay + col * glareColOffsetMul + row * glareRowOffsetMul + headers * glareHeaderOffsetMul,
    repeatDelay = goodsGlareRepeatDelay
  }
}

let mkGoodsCard = @(goods, animParams) mkGoods(
  goods,
  @() onGoodsClick(goods),
  mkGoodsState(goods),
  animParams
)

let mkSchRewardCard = @(schGoods, animParams) mkGoods(
  schGoods,
  @() onSchRewardReceive(schGoods),
  Computed(@() schGoods.id in schRewardInProgress.get() ? PURCHASING : 0),
  animParams
)

function mkPersonalGoodsCard(pGoods, animParams) {
  let { isPurchased, endTime, lifeTime } = pGoods
  let goods = rewardsToShopGoods(pGoods.goods).__update(
    pGoods,
    {
      endTime = 0  
      isPopular = true
      popularText = loc($"shop/{pGoods.id}")
      meta = {}
    })

  local addChildren = []
  if (isPurchased) {
    let sec = Computed(@() max(0, endTime - serverTime.get()))
    addChildren.append(mkGoodsTimeProgress(
      Computed(@() clamp(1.0 - sec.get().tofloat() / lifeTime, 0, 1)),
      Computed(@() secondsToHoursLoc(sec.get()))
    ))
  }
  else
    addChildren.append({
      margin = bottomPad
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      children = mkLimitText(1, 1)
    })

  return mkGoods(
    goods,
    @() purchasePersonalGoods(pGoods, goods),
    Computed(@() pGoods.id == personalGoodsInProgress.get() || personalGoodsInProgress.get() == "" ? PURCHASING : 0),
    animParams,
    addChildren)
}

let mkSubscriptionCardExt = @(subs, animParams) mkSubscriptionCard(
  subs,
  @() openSubsPreview(subs.id),
  Computed(function() {
    local res = subscriptions.get()?[subs.id].isActive ? IS_ACTIVE : 0
    let group = subsGroups.findvalue(@(g) g.contains(subs.id))
    if (group == null)
      return res
    for (local i = group.len() - 1; i >= 0; i--) {
      local subId = group[i]
      if (subscriptions.get()?[subId].isActive ?? false){
        if (subId == group.top())
          return IS_ACTIVE
        else
          return IS_ACTIVE | HAS_UPGRADE
      }
    }
    return res
  }), animParams
)

function mkShopCategoryGoods(categoryCfg, distances) {
  let { id = "", title = "", getTitle = null } = categoryCfg
  let goodsListBase = Computed(@() goodsByCategory.get()?[id] ?? [])
  let schReward = Computed(@() actualSchRewardByCategory.get()?[id])
  let personalList = Computed(@() personalGoodsByShopCategory.get()?[id])
  let subsList = Computed(@() subsByCategory.get()?[id])
  let rowsBefore = Computed(@() distances.get()?[id].rowsBefore ?? 0)
  let headersBefore = Computed(@() distances.get()?[id].headersBefore ?? 0)
  let watch = [ goodsListBase, schReward, curCampaign, personalList, subsList, rowsBefore, headersBefore ]
  return function() {
    let goodsListByCategory = goodsListBase.get()
    let hasSchReward = schReward.get() != null
    if (goodsListByCategory.len() == 0 && !hasSchReward && !personalList.get() && !subsList.get())
      return { watch }

    let goodsList = mkGoodsListWithBaseValue(goodsListByCategory)
    goodsList.sort(sortGoods)

    let animIdxOffset = rowsBefore.get() * goodsPerRow
    let headers = headersBefore.get()
    let allCards = []
    if (subsList.get())
      foreach (subs in subsList.get())
        allCards.append(
          mkSubscriptionCardExt(subs, mkAnimParams(allCards.len() + animIdxOffset, headers)))
    if (personalList.get())
      foreach (goods in personalList.get())
        allCards.append(
          mkPersonalGoodsCard(goods, mkAnimParams(allCards.len() + animIdxOffset, headers)))
    if (hasSchReward)
      allCards.append(
        mkSchRewardCard(schReward.get(), mkAnimParams(allCards.len() + animIdxOffset, headers)))

    foreach (goods in goodsList)
      allCards.append(
        mkGoodsCard(goods, mkAnimParams(allCards.len() + animIdxOffset, headers)))

    let rows = arrayByRows(allCards, goodsPerRow)

    return {
      key = id
      watch
      children = {
        flow = FLOW_VERTICAL
        gap = titleGap
        children = [
          {
            size = [SIZE_TO_CONTENT, titleH]
            color = 0xFFFFFFFF
            rendObj = ROBJ_TEXT
            text = utf8ToUpper(getTitle?(curCampaign.get()) ?? title)
          }.__update(fontMediumShaded)
          {
            flow = FLOW_VERTICAL
            gap = goodsGap
            children = rows.map(@(children) {
              flow = FLOW_HORIZONTAL
              gap = goodsGap
              children
            })
          }
        ]
        transform = {}
        animations = tabTranslateWithOpacitySwitchAnim
      }
    }
  }
}

let mkShopPage = @(curCategoriesCfg, distances) @() {
  watch = curCategoriesCfg
  flow = FLOW_VERTICAL
  gap = categoryGap
  children = curCategoriesCfg.get().map(@(categoryCfg) mkShopCategoryGoods(categoryCfg, distances))
}

return {
  mkShopPage
  onGoodsClick
  mkGoodsListWithBaseValue
  mkGoodsState
  mkShopGamercard
}
