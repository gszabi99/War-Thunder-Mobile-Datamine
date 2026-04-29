from "%globalsDarg/darg_library.nut" import *
let { doesLocTextExist } = require("dagor.localize")
let { resetTimeout } = require("dagor.workcycle")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { G_PREMIUM, G_CURRENCY, G_ITEM, G_SKIN, unitRewardTypes } = require("%appGlobals/rewardType.nut")
let { SGT_UNIT, SGT_BLUEPRINTS, SGT_SKIN } = require("%rGui/shop/shopConst.nut")
let { curCategoryId, sortGoods, openShopWnd, openShopWndByGoods, shopGoods, goodsLinks, subsGroups, curShopId,
  curShopActualSchRewardsByCategory, curShopGoodsByCategory, curShopPersonalGoodsByCategory,
  curShopSubsByCategory, curShopSoonGoodsByCategory, soonGoodsByShop, goodsIdsByShop,
  curShopSoonPGoodsByCategory, soonPersonalGoodsByShop
} = require("%rGui/shop/shopState.nut")
let { getGoodsType } = require("%rGui/shop/shopCommon.nut")
let { onSchRewardReceive } = require("%rGui/shop/schRewardsState.nut")
let { getPersonalGoodsBaseId, activePersonalGoods, pGoodsOffsetIdx } = require("%rGui/shop/personalGoodsState.nut")
let { purchasePersonalGoods } = require("%rGui/shop/personalGoodsPurchase.nut")
let { purchasesCount, curCampaign, subscriptions } = require("%appGlobals/pServer/campaign.nut")
let { shopPurchaseInProgress, schRewardInProgress, personalGoodsInProgress
} = require("%appGlobals/pServer/pServerApi.nut")
let { PURCHASING, DELAYED, HAS_PURCHASES, IS_ACTIVE, HAS_UPGRADE, NOT_READY
} = require("%rGui/shop/goodsStates.nut")
let { purchaseGoods } = require("%rGui/shop/purchaseGoods.nut")
let { buyPlatformGoods, platformPurchaseInProgress, isGoodsOnlyInternalPurchase
} = require("%rGui/shop/platformGoods.nut")
let { mkGoods } = require("%rGui/shop/goodsView/goods.nut")
let { mkSubscriptionCard } = require("%rGui/shop/goodsView/subscriptionCard.nut")
let { goodsGap, goodsGlareAnimDuration, mkLimitText, bottomPad, mkGoodsTimeProgress
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { openGoodsPreview, openSubsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { itemsOrderFull } = require("%appGlobals/itemsState.nut")
let { sortByCurrencyId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let premIconWithTimeOnChange = require("%rGui/mainMenu/premIconWithTimeOnChange.nut")
let { mkItemsBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { gamercardGap } = require("%rGui/components/currencyStyles.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { openMsgBox, msgBoxText } = require("%rGui/components/msgBox.nut")
let { categoryGap, titleGap, goodsPerRow, titleH } = require("%rGui/shop/shopWndConst.nut")
let { personalGoodsToShopGoods } = require("%rGui/shop/rewardsToShopGoods.nut")
let { activeInternalSubs } = require("%rGui/state/profilePremium.nut")


let soonPersonalGoodsDelay = 7.0
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

let allowedCompare = [G_PREMIUM, G_CURRENCY, G_ITEM].totable()

let personalTextByLifeTime = {
  [3600] = "shop/hourly",
  [24 * 3600] = "shop/daily",
  [7 * 24 * 3600] = "shop/weekly",
}

function openGoodsNotAvailToPurchMsg(goods) {
  if (goods.rewards.len() == 1 && goods.rewards[0].id == "ircm_kit" && goods.rewards[0].gType == G_ITEM) {
    local canBuyCountermeasure = false
    foreach(unit in campMyUnits.get())
      if (getUnitTagsCfg(unit.name ?? "")?.Shop.weapons.countermeasure_launcher_ship != null) {
        canBuyCountermeasure = true
        break
      }
    if (!canBuyCountermeasure) {
      openMsgBox({ text = msgBoxText(loc("shop/cantBuyCountermeasure")) })
      return true
    }
  }
  return false
}

let function purchaseFunc(goods) {
  if (openGoodsNotAvailToPurchMsg(goods))
    return
  if (goods.price.price > 0 && goods.price.currencyId != "")
    return purchaseGoods(goods.id)
  buyPlatformGoods(goods.id)
}

let mkGoodsState = @(goods, addState = 0) Computed(function() {
  local res = addState
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

let getGoodsCompareData = @(goods)
  goods.rewards.len() == 1 && goods.rewards[0].gType in allowedCompare
    ? goods.rewards[0]
    : null

function mkGoodsListWithBaseValue(goodsListBase) {
  let goodsList = []
  let goodsCompares = {}
  foreach (g in goodsListBase) {
    let goods = clone g
    goodsList.append(goods)
    let data = getGoodsCompareData(goods)
    if (data == null)
      continue
    let { id, count } = data
    if (count == 0)
      continue
    goodsCompares[id] <- (goodsCompares?[id] ?? []).append({ goods, baseValue = count })
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
  let gtype = getGoodsType(goods)
  if (gtype == SGT_UNIT || gtype == SGT_BLUEPRINTS || gtype == SGT_SKIN)
    openGoodsPreview(goods.id)
  else
    purchaseFunc(goods)
}

let gamercardShopItemsBalanceBtns = @(items) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = items.map(@(id) mkItemsBalance(id, function() {
    let has = @(g) null != g.rewards.findvalue(@(r) r.id == id && r.gType == G_ITEM)
    let category = curShopGoodsByCategory.get().findindex(@(goods) null != goods.findvalue(has))
      ?? curShopSoonGoodsByCategory.get().findindex(@(goods) null != goods.findvalue(has))
      ?? curShopSoonPGoodsByCategory.get().findindex(@(goods) null != goods.findvalue(has))
    if (category)
      return openShopWnd(category, null, curShopId.get())
    let goods = shopGoods.get().findvalue(@(goods) null != goods.rewards.findvalue(@(r) r.id == id && r.gType == G_ITEM))
    openShopWndByGoods(goods)
  }))
}

let mkShopGamercard = @(onClose) function() {
  let currencies = {}
  let items = {}
  local needShowPremium = false
  let goodsIds = goodsIdsByShop.get()?[curShopId.get()]
  foreach (goodsId in goodsIds?[curCategoryId.get()] ?? {}) {
    let goods = activePersonalGoods.get()?[goodsId] ?? shopGoods.get()?[goodsId]
    if (goods == null)
      continue

    if (goods.price.currencyId != "")
      currencies[goods.price.currencyId] <- true
    if ((goods?.rewards.len() ?? 0) != 1)
      continue 
    let { gType, id } = goods.rewards[0]
    if (gType == G_PREMIUM)
      needShowPremium = true
    else if (gType == G_ITEM)
      items[id] <- true
    else if (gType == G_CURRENCY)
      currencies[id] <- true
  }
  foreach (goods in soonGoodsByShop.get()?[curShopId.get()][curCategoryId.get()] ?? {}) {
    if (goods.price.currencyId != "")
      currencies[goods.price.currencyId] <- true
    if (goods.rewards.len() == 1 && goods.rewards[0].gType == G_CURRENCY)
      currencies[goods.rewards[0].id] <- true
  }
  foreach (goods in soonPersonalGoodsByShop.get()?[curShopId.get()][curCategoryId.get()] ?? {})
    if (goods.price.currencyId != "")
      currencies[goods.price.currencyId] <- true
  let orderItems = items.keys().sort(@(a,b)
    itemsOrderFull.findindex(@(v) v == a) <=> itemsOrderFull.findindex(@(v) v == b))
  return {
    watch = [ curCategoryId, curShopId, activePersonalGoods, shopGoods, soonGoodsByShop ]
    size = [ saSize[0], gamercardHeight ]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = gamercardGap
    children = [
      backButton(onClose)
      {size = flex()}
      needShowPremium ? premIconWithTimeOnChange : null
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

let mkSoonGoodsCard = @(goods, animParams) mkGoods(
  goods,
  @() null,
  mkGoodsState(goods, NOT_READY),
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
  let popLocId = $"shop/{getPersonalGoodsBaseId(pGoods.id)}"
  let goods = personalGoodsToShopGoods(pGoods).__update({
    endTime = 0  
    isPopular = true
    popularText = loc(doesLocTextExist(popLocId) ? popLocId
      : (personalTextByLifeTime?[lifeTime] ?? popLocId))
  })

  local addChildren = []
  let isWithUnitOrSkin = null != pGoods.goods.findvalue(@(g) g.gType in unitRewardTypes || g.gType == G_SKIN)
  if (isPurchased) {
    let sec = Computed(@() max(0, endTime - serverTime.get()))
    addChildren.append(mkGoodsTimeProgress(
      Computed(@() clamp(1.0 - sec.get().tofloat() / lifeTime, 0, 1)),
      Computed(@() secondsToHoursLoc(sec.get()))
    ))
  }
  else if (!isWithUnitOrSkin)
    addChildren.append({
      margin = bottomPad
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      children = mkLimitText(1, 1)
    })

  return mkGoods(
    goods,
    @() isWithUnitOrSkin ? openGoodsPreview(goods.id)
      : purchasePersonalGoods(pGoods, goods),
    Computed(@() pGoods.id == personalGoodsInProgress.get() || personalGoodsInProgress.get() == "" ? PURCHASING : 0),
    animParams,
    addChildren)
}

function mkSoonPersonalGoodsCard(pGoods, idx, listLen, animParams) {
  let { lifeTime, timeRange, id, groupId, varId } = pGoods
  let combinationId = $"{groupId}&{varId}"
  let popLocId = $"shop/{getPersonalGoodsBaseId(id)}"
  let goods = personalGoodsToShopGoods(pGoods).__update({
    endTime = 0  
    isPopular = true
    popularText = loc(doesLocTextExist(popLocId) ? popLocId
      : (personalTextByLifeTime?[lifeTime] ?? popLocId))
  })

  let sec = Computed(@() max(0, timeRange.start - serverTime.get()))
  let addChildren = [
    mkGoodsTimeProgress(
      Computed(@() clamp(1.0 - sec.get().tofloat() / lifeTime, 0, 1)),
      Computed(@() secondsToHoursLoc(sec.get()))
    )
  ]
  let isWithUnitOrSkin = null != pGoods.goods.findvalue(@(g) g.gType in unitRewardTypes || g.gType == G_SKIN)
  if (!isWithUnitOrSkin)
    addChildren.append({
      margin = bottomPad
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      children = mkLimitText(1, 1)
    })

  return {
    key = combinationId
    onAttach = idx != 0 ? null : @() resetTimeout(soonPersonalGoodsDelay, @() pGoodsOffsetIdx.modify(@(v) v + listLen))
    children = mkGoods(
      goods,
      @() null,
      Watched(NOT_READY),
      animParams,
      addChildren)
    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.8, easing = OutQuad, play = true }
      { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.4, easing = OutQuad, playFadeOut = true }
    ]
  }
}

let mkSubscriptionCardExt = @(subs, animParams) mkSubscriptionCard(
  subs,
  @() openSubsPreview(subs.id, "shop"),
  Computed(function() {
    local res = (subscriptions.get()?[subs.id].isActive || subs.id in activeInternalSubs.get()) ? IS_ACTIVE : 0
    let group = subsGroups.findvalue(@(g) g.contains(subs.id))
    if (group == null)
      return res
    for (local i = group.len() - 1; i >= 0; i--) {
      local subId = group[i]
      if ((subscriptions.get()?[subId].isActive ?? false) || subId in activeInternalSubs.get()){
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
  let goodsListBase = Computed(@() curShopGoodsByCategory.get()?[id] ?? [])
  let soonList = Computed(@() curShopSoonGoodsByCategory.get()?[id] ?? [])
  let schReward = Computed(@() curShopActualSchRewardsByCategory.get()?[id])
  let personalList = Computed(@() curShopPersonalGoodsByCategory.get()?[id])
  let subsList = Computed(@() curShopSubsByCategory.get()?[id])
  let rowsBefore = Computed(@() distances.get()?[id].rowsBefore ?? 0)
  let headersBefore = Computed(@() distances.get()?[id].headersBefore ?? 0)

  let personalSoonList = Computed(function() {
    let res = []
    let offsetIdx = pGoodsOffsetIdx.get()
    let soonPGoods = curShopSoonPGoodsByCategory.get()?[id] ?? []
    let slotsByBaseId = {}
    foreach (soonPGoodsV in soonPGoods)
      slotsByBaseId[soonPGoodsV.baseId] <- soonPGoodsV.slots
    let soonPGoodsLen = slotsByBaseId.reduce(@(resV, v) resV + v, 0)
    for (local i = 0; i < soonPGoodsLen; i++) {
      let idx = (i + offsetIdx) % soonPGoods.len()
      res.append(soonPGoods[idx])
    }
    return res
  })

  let res = {
    key = id,
    watch = [ goodsListBase, soonList, schReward, curCampaign, personalList, subsList, rowsBefore, headersBefore, personalSoonList ]
  }
  return function() {
    let goodsListByCategory = goodsListBase.get()
    let hasSchReward = schReward.get() != null
    if (goodsListByCategory.len() == 0 && !hasSchReward && !personalList.get() && !subsList.get()
        && soonList.get().len() == 0 && personalSoonList.get().len() == 0)
      return res

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

    foreach (goods in soonList.get())
      allCards.append(
        mkSoonGoodsCard(goods, mkAnimParams(allCards.len() + animIdxOffset, headers)))

    foreach (idx, goods in personalSoonList.get())
      allCards.append(
        mkSoonPersonalGoodsCard(goods, idx, personalSoonList.get().len(), mkAnimParams(allCards.len() + animIdxOffset, headers)))

    let rows = arrayByRows(allCards, goodsPerRow)

    return res.__merge({
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
    })
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
