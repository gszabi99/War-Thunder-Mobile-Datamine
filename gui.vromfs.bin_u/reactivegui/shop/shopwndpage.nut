from "%globalsDarg/darg_library.nut" import *
from "dagor.localize" import doesLocTextExist
from "dagor.workcycle" import clearTimer, setInterval
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/underscore.nut" import arrayByRows, prevIfEqual
from "%appGlobals/pServer/campaign.nut" import purchasesCount, curCampaign, subscriptions
from "%appGlobals/pServer/pServerApi.nut" import shopPurchaseInProgress, schRewardInProgress, personalGoodsInProgress
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/rewardType.nut" import G_PREMIUM, G_CURRENCY, G_ITEM, G_SKIN, unitRewardTypes
from "%appGlobals/unitTags.nut" import getUnitTagsCfg
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/currencyStyles.nut" import gamercardGap
from "%rGui/components/gradientDefComps.nut" import headerGradientWithRightBlock
from "%rGui/components/msgBox.nut" import openMsgBox, msgBoxText
from "%rGui/mainMenu/balanceComps.nut" import mkItemsBalance
from "%rGui/mainMenu/gamercard.nut" import mkCurrenciesBtns
from "%rGui/seasonScene/seasonSceneState.nut" import openShopByGoods
from "%rGui/shop/goodsPreviewState.nut" import openGoodsPreview, openSubsPreview
from "%rGui/shop/goodsStates.nut" import PURCHASING, DELAYED, HAS_PURCHASES, IS_ACTIVE, HAS_UPGRADE, NOT_READY
from "%rGui/shop/goodsView/goods.nut" import mkGoods
from "%rGui/shop/goodsView/sharedParts.nut" import goodsGap, goodsGlareAnimDuration, mkLimitText, bottomPad,
  mkGoodsTimeProgress
from "%rGui/shop/goodsView/subscriptionCard.nut" import mkSubscriptionCard
from "%rGui/shop/personalGoodsPurchase.nut" import purchasePersonalGoods
from "%rGui/shop/personalGoodsState.nut" import getPersonalGoodsBaseId, pGoodsOffsets, personalGoodsCfg
from "%rGui/shop/platformGoods.nut" import buyPlatformGoods, platformPurchaseInProgress, isGoodsOnlyInternalPurchase
from "%rGui/shop/purchaseGoods.nut" import purchaseGoods
from "%rGui/shop/rewardsToShopGoods.nut" import personalGoodsToShopGoods
from "%rGui/shop/schRewardsState.nut" import onSchRewardReceive
from "%rGui/shop/shopCommon.nut" import getGoodsType
from "%rGui/shop/shopConst.nut" import SGT_UNIT, SGT_BLUEPRINTS, SGT_SKIN
from "%rGui/shop/shopState.nut" import curCategoryId, sortGoods, shopGoods, goodsLinks, subsGroups,
  curShopId, goodsByShop, onTabChange, getGoodsShopId,
  mkShopCurrenciesAndItemsList
from "%rGui/shop/shopWndConst.nut" import categoryGap, titleGap, goodsPerRow, titleH
from "%rGui/state/profilePremium.nut" import activeInternalSubs


const soonPersonalGoodsDelay = 7.0
const goodsGlareRepeatDelay = 3
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

function purchaseFunc(goods) {
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

function mkItemRefillClick(id, shopId, curCatId) {
  let has = @(g) null != (g?.rewards ?? g?.goods ?? []).findvalue(@(r) r.id == id && r.gType == G_ITEM)
  let category = goodsByShop.get()?[shopId].findindex(@(goods) null != goods.findvalue(has))
  if (category != null)
    return category == curCatId ? null : @() onTabChange(category, shopId)
  let goods = shopGoods.get().findvalue(@(goods) null != goods.rewards.findvalue(@(r) r.id == id && r.gType == G_ITEM))
  return goods == null || getGoodsShopId(goods) == shopId ? null : @() openShopByGoods(goods)
}

let gamercardShopItemsBalanceBtns = @(shopId, catId, items) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = items.map(@(id) mkItemsBalance(id, mkItemRefillClick(id, shopId.get(), catId.get())))
}

function mkShopHeaderRight(shopId, catId) {
  let list = mkShopCurrenciesAndItemsList(shopId, catId)
  return @() {
    watch = list
    hplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    gap = gamercardGap
    children = [
      gamercardShopItemsBalanceBtns(shopId, catId, list.get().items)
      mkCurrenciesBtns(list.get().currencies).__update({ size = SIZE_TO_CONTENT })
    ]
  }
}

let mkShopGamercard = @(onClose) headerGradientWithRightBlock(
  [
    backButton(onClose)
    {
      rendObj = ROBJ_TEXT
      text = loc("topmenu/store")
    }.__update(fontBigShaded)
  ],
  mkShopHeaderRight(curShopId, curCategoryId))

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
      Watched(endTime)
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

function mkSoonPersonalGoodsCard(pGoodsSlot, listLen, animParams) {
  let { baseId, slotId, id } = pGoodsSlot
  let pGoods = Computed(function(prev) {
    let cfg = personalGoodsCfg.get()?[baseId] ?? {}
    let combinations = (cfg?.groups ?? {}).reduce(@(resV, v) resV + (v?.variants.len() ?? 0), 0)
    let idx = (slotId + (pGoodsOffsets.get()?[baseId] ?? 0)) % combinations
    local i = 0
    foreach (groupId, groupCfg in cfg?.groups ?? {}) {
      foreach (varId, variant in groupCfg.variants) {
        if (i++ != idx)
          continue
        let { goods, discountInPercentOvr } = variant
        let { price, discountInPercent, lifeTime } = groupCfg
        return prevIfEqual(prev, pGoodsSlot.__merge({
          groupId, varId, goods, price,
          discountInPercent = discountInPercentOvr ? discountInPercentOvr : discountInPercent,
          lifeTime, meta = cfg.meta, endTime = cfg.timeRange.start, timeRange = cfg.timeRange,
          showTimeBeforeActivate = cfg.showTimeBeforeActivate
        }))
      }
    }
    return prevIfEqual(prev, pGoodsSlot)
  })
  let updatePGoodsOffsetDelayed = @() anim_start($"soonPGoodsAnim")

  return function() {
    let { lifeTime, goods } = pGoods.get()

    let popLocId = $"shop/{getPersonalGoodsBaseId(id)}"
    let pShopGoods = personalGoodsToShopGoods(pGoods.get()).__update({
      endTime = 0  
      isPopular = true
      popularText = loc(doesLocTextExist(popLocId) ? popLocId
        : (personalTextByLifeTime?[lifeTime] ?? popLocId))
    })

    let addChildren = []
    let isWithUnitOrSkin = null != goods.findvalue(@(g) g.gType in unitRewardTypes || g.gType == G_SKIN)
    if (!isWithUnitOrSkin)
      addChildren.append({
        margin = bottomPad
        hplace = ALIGN_RIGHT
        vplace = ALIGN_BOTTOM
        children = mkLimitText(1, 1)
      })
    return {
      watch = pGoods
      key = updatePGoodsOffsetDelayed
      onAttach = slotId == 0 ? @() setInterval(soonPersonalGoodsDelay, updatePGoodsOffsetDelayed) : null
      onDetach = slotId == 0 ? @() clearTimer(updatePGoodsOffsetDelayed) : null
      children = mkGoods(
        pShopGoods,
        @() null,
        Watched(NOT_READY),
        animParams,
        addChildren)
      transform = {}
      animations = [
        { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.8,
          easing = OutQuad, trigger = $"soonPGoodsAnim",
          onFinish = @() pGoodsOffsets.mutate(@(v) v[baseId] <- (v?[baseId] ?? 0) + listLen) }
        { prop = AnimProp.opacity, from = 0.0, to = 1.0, delay = 0.8, duration = 0.4,
          easing = OutQuad, trigger = $"soonPGoodsAnim" }
      ]
    }
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

let mkShopCategoryGoods = kwarg(function mkShopCategoryGoods(categoryCfg,  distances,
  goodsByCategory, soonGoodsByCategory, schRewardsByCategory, soonPGoodsByCategory,
  personalGoodsByCategory, subsByCategory
) {
  let { id = "", title = "", getTitle = null } = categoryCfg
  let goodsListBase = Computed(@() goodsByCategory.get()?[id] ?? [])
  let soonList = Computed(@() soonGoodsByCategory.get()?[id] ?? [])
  let schReward = Computed(@() schRewardsByCategory.get()?[id])
  let personalSoonList = Computed(@() soonPGoodsByCategory.get()?[id] ?? [])
  let personalList = Computed(@() personalGoodsByCategory.get()?[id])
  let subsList = Computed(@() subsByCategory.get()?[id])
  let rowsBefore = Computed(@() distances.get()?[id].rowsBefore ?? 0)
  let headersBefore = Computed(@() distances.get()?[id].headersBefore ?? 0)

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

    foreach (goods in personalSoonList.get())
      allCards.append(
        mkSoonPersonalGoodsCard(goods, personalSoonList.get().len(), mkAnimParams(allCards.len() + animIdxOffset, headers)))

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
      }
    })
  }
})

let mkShopPage = @(curCategoriesCfg, distances, ctx) @() {
  watch = [curCategoriesCfg, ctx.shopIdW]
  children = {
    key = ctx.shopIdW.get()
    flow = FLOW_VERTICAL
    gap = categoryGap
    children = curCategoriesCfg.get().map(@(categoryCfg) mkShopCategoryGoods({
      categoryCfg, distances
      goodsByCategory = ctx.goodsByCategory
      soonGoodsByCategory = ctx.soonGoodsByCategory
      schRewardsByCategory = ctx.schRewardsByCategory
      soonPGoodsByCategory = ctx.soonPGoodsByCategory
      personalGoodsByCategory = ctx.personalGoodsByCategory
      subsByCategory = ctx.subsByCategory
    }))
    transform = {}
    animations = tabTranslateWithOpacitySwitchAnim
  }
}

return {
  mkShopPage
  onGoodsClick
  mkGoodsListWithBaseValue
  mkGoodsState
  mkShopGamercard
  mkShopHeaderRight
}
