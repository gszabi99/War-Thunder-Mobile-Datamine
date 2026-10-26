from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/pServerApi.nut" import curUnitInProgress
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/pServer/slots.nut" import curCampaignSlots, curSlots
from "%appGlobals/rewardType.nut" import G_CURRENCY, G_BLUEPRINT, G_UNIT, G_UNIT_UPGRADE
from "%appGlobals/unitsState.nut" import setCurrentUnit
from "%rGui/components/currencyComp.nut" import mkCurrencyComp
from "%rGui/components/discountTag.nut" import discountTag
from "%rGui/components/modalWnd.nut" import modalWndHeader
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/components/scrollArrows.nut" import mkScrollArrow, scrollArrowImageSmall
from "%rGui/components/textButton.nut" import textButtonPrimary, textButtonCommon
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlateBg, mkRewardPlateImage, mkProgressLabel, mkProgressBar,
  mkRewardTextLabel, mkRewardPlateTexts, mkRewardPlate, mkRewardUnitFlag, getRewardPlateSize
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_MEDIUM, REWARD_STYLE_SMALL
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo, shopGoodsToRewardsViewInfo, sortRewardsViewInfo,
  isRewardEmpty, getBlueprintBarColor
from "%rGui/shop/discounts.nut" import calculateNewGoodsDiscount, discountsToApply, applyDiscount
from "%rGui/shop/shopState.nut" import allShopGoods
from "%rGui/shop/unseenPurchasesState.nut" import unseenPurchaseUnitPlateKey
from "%rGui/slotBar/slotBarState.nut" import openSelectUnitToSlotWnd, canOpenSelectUnitWithModal
from "%rGui/unit/components/unitPlateComp.nut" import unitPlateWidth, mkSingleUnitPlate


const textColor = 0xFFE0E0E0

const padding = hdpx(50)
const minWidthWnd = hdpx(900)
const maxHeightContent = hdpx(400)


let tapToContinueText = {
  rendObj = ROBJ_TEXT
  color = textColor
  text = loc("TapAnyToContinue")
  vplace = ALIGN_BOTTOM
}.__update(fontSmall)

let mkBlueprintsProgress = @(available, total, color) {
  size = FLEX
  valign = ALIGN_BOTTOM
  children = [
    mkProgressBar(available, total, color)
    mkProgressLabel(available, total, REWARD_STYLE_SMALL)
  ]
}

let exceedBlueprintsProgress = @(count, targetCount, color)
  mkBlueprintsProgress(targetCount + count, targetCount, color)

function mkBlueprintPlate(reward, available = null) {
  let plateBg = mkRewardPlateBg(reward, REWARD_STYLE_MEDIUM)
  let plateImage = mkRewardPlateImage(reward, REWARD_STYLE_MEDIUM)
  return @() {
    watch = serverConfigs
    children = [
      plateBg
      plateImage
      mkBlueprintsProgress(available ?? reward.count, reward.count, getBlueprintBarColor(reward.id, serverConfigs.get()))
      mkRewardUnitFlag(serverConfigs.get()?.allUnits?[reward.id], REWARD_STYLE_MEDIUM)
    ]
  }
}

function mkUnitPlate(reward) {
  let plateBg = mkRewardPlateBg(reward, REWARD_STYLE_MEDIUM)
  let plateImage = mkRewardPlateImage(reward, REWARD_STYLE_MEDIUM)
  let plateTexts = mkRewardPlateTexts(reward, REWARD_STYLE_MEDIUM)
  return @() {
    watch = serverConfigs
    children = [
      plateBg
      plateImage
      plateTexts
      mkRewardUnitFlag(serverConfigs.get()?.allUnits?[reward.id], REWARD_STYLE_MEDIUM)
    ]
  }
}

let fromCtor = {
  [G_BLUEPRINT] = function(reward) {
    let plateBg = mkRewardPlateBg(reward, REWARD_STYLE_MEDIUM)
    let plateImage = mkRewardPlateImage(reward, REWARD_STYLE_MEDIUM)
    let textLabel = reward.count < 0 ? mkRewardTextLabel(-reward.count, REWARD_STYLE_SMALL) : null
    return @() {
      watch = serverConfigs
      children = [
        plateBg
        plateImage
        reward.count >= 0
          ? exceedBlueprintsProgress(reward.count, serverConfigs.get()?.allBlueprints[reward.id].targetCount ?? 1,
              getBlueprintBarColor(reward.id, serverConfigs.get()))
          : textLabel
        mkRewardUnitFlag(serverConfigs.get()?.allUnits?[reward.id], REWARD_STYLE_MEDIUM)
      ]
    }
  },

  [G_CURRENCY] = @(reward) mkRewardPlate(reward, REWARD_STYLE_MEDIUM),

  [G_UNIT] = mkUnitPlate,
}

let arrowIcon = {
  rendObj = ROBJ_IMAGE
  size = const [hdpx(100), hdpx(70)]
  vplace = ALIGN_CENTER
  image = Picture($"ui/gameuiskin#arrow_icon.svg:{hdpx(100)}:{hdpx(70)}:P")
}

let mkConvertRow = @(fromPlate, toPlate) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  children = [
    {
      size = FLEX_H
      halign = ALIGN_CENTER
      children = fromPlate
    }
    arrowIcon
    {
      size = FLEX_H
      halign = ALIGN_CENTER
      children = toPlate
    }
  ]
}

let isUnitByBlueprints = @(conv) conv.from.gType == G_BLUEPRINT
  && (conv.to.gType == G_UNIT || conv.to.gType == G_UNIT_UPGRADE)

let mkGoodsViewInfo = @(goods, count) getRewardsViewInfo([{
  id = goods.id
  gType = goods.gType
  count
  subId = goods.subId
}])[0]

function mkUnitButton(unitInfo, myUnits, cUnitInProgress, cSlots, cCampaignSlots) {
  if (unitInfo?.unit == null)
    return null
  let btnOvr = { ovr = { size = [unitPlateWidth, hdpx(70)], margin = const [hdpx(10),0,0,0] } }
  if (cCampaignSlots != null) {
    let onClick = @() openSelectUnitToSlotWnd(unitInfo.id, unseenPurchaseUnitPlateKey(unitInfo.id))
    return cSlots.findindex(@(slot) slot.name == unitInfo.id) == null
      ? textButtonPrimary(utf8ToUpper(loc("mainmenu/btnEquip")), onClick, btnOvr)
      : textButtonCommon(utf8ToUpper(loc("mainmenu/btnEquipped")), null, btnOvr)
  }

  return cUnitInProgress == null && unitInfo.id in myUnits && !myUnits[unitInfo.id].isCurrent
    ? textButtonPrimary(utf8ToUpper(loc("mainmenu/btnEquip")), @() setCurrentUnit(unitInfo.id), btnOvr)
    : null
}

let mkReceivedUnitPlate = @(unitName, isUpgraded, key) @() {
  watch = serverConfigs
  key
  children = mkSingleUnitPlate(serverConfigs.get()?.allUnits?[unitName].__merge({ isUpgraded }))
}

let mkReceivedUnitButton = @(unitName) function() {
  let unit = serverConfigs.get()?.allUnits?[unitName]
  return {
    watch = [serverConfigs, campMyUnits, curUnitInProgress, curSlots, curCampaignSlots, curCampaign]
    hplace = ALIGN_RIGHT
    children = unit?.campaign != curCampaign.get() ? null
      : mkUnitButton({ id = unitName, unit }, campMyUnits.get(), curUnitInProgress.get(), curSlots.get(),
          curCampaignSlots.get())
  }
}

function mkUnitByBlueprintsRow(conv, hasUnitButton) {
  let { from, to } = conv
  return {
    flow = FLOW_VERTICAL
    children = [
      {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = hdpx(20)
        children = [
          mkBlueprintPlate(mkGoodsViewInfo(from, from.count))
          arrowIcon
          mkReceivedUnitPlate(to.id, to.gType == G_UNIT_UPGRADE,
            hasUnitButton ? unseenPurchaseUnitPlateKey(to.id) : null)
        ]
      }
      hasUnitButton ? mkReceivedUnitButton(to.id) : null
    ]
  }
}


let mkVerticalPannableArea = verticalPannableAreaCtor(maxHeightContent, [hdpx(10), hdpx(90)])
let scrollHandler = ScrollHandler()
let unitsScrollHandler = ScrollHandler()

let mkScrollArrowsBlock = @(handler) {
  size = const [SIZE_TO_CONTENT, maxHeightContent]
  hplace = ALIGN_CENTER
  children = [
    mkScrollArrow(handler, MR_T, scrollArrowImageSmall)
    mkScrollArrow(handler, MR_B, scrollArrowImageSmall)
  ]
}
let scrollArrowsBlock = mkScrollArrowsBlock(scrollHandler)
let unitsScrollArrowsBlock = mkScrollArrowsBlock(unitsScrollHandler)

function mkMsgConvert(stackDataV, onClick) {
  let unitConversions = stackDataV.filter(isUnitByBlueprints)
  let currencyConversions = stackDataV.filter(@(c) !isUnitByBlueprints(c))
  let lastRowByUnit = {}
  foreach (idx, conv in unitConversions)
    lastRowByUnit[conv.to.id] <- idx
  let mainRewards = {}
  local sum = 0
  local isOnlyBlueprints = true
  foreach(info in currencyConversions) {
    sum = sum + info.to.count
    isOnlyBlueprints = isOnlyBlueprints && info.from.gType == G_BLUEPRINT
    local amount = info.from.count
    mainRewards[info.from.id] <- {
      reward = mkGoodsViewInfo(info.from, amount >= 0 ? amount : -amount)
      toReward = mkGoodsViewInfo(info.to, info.to.count)
    }
  }
  let cont = {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = hdpx(35)
    children = mainRewards
      .map(@(data) mkConvertRow(fromCtor?[data.reward?.rType](data.reward),
        mkRewardPlate(data.toReward, REWARD_STYLE_MEDIUM)))
      .values()
  }
  let unitsCont = {
    size = FLEX_H
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = hdpx(35)
    children = unitConversions.map(@(conv, idx) mkUnitByBlueprintsRow(conv, lastRowByUnit[conv.to.id] == idx))
  }
  return {
    minWidth = minWidthWnd
    padding = const [0,0, padding, 0]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick
    flow = FLOW_VERTICAL
    onAttach = @() canOpenSelectUnitWithModal.set(true)
    onDetach = @() canOpenSelectUnitWithModal.set(false)
    children = [
      modalWndHeader(loc(unitConversions.len() == 0 ? "mainmenu/convert" : "mainmenu/you_received"))
      unitConversions.len() == 0 ? null
        : {
            padding = padding
            children = {
              size = const [minWidthWnd, SIZE_TO_CONTENT]
              children = unitConversions.len() > 2 ? [
                mkVerticalPannableArea(
                  unitsCont,
                  {},
                  { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler = unitsScrollHandler })
                unitsScrollArrowsBlock
              ] : unitsCont
            }
          }
      currencyConversions.len() == 0 ? null
        : {
            flow = FLOW_VERTICAL
            padding = padding
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            children = [
              {
                  size = const [minWidthWnd, SIZE_TO_CONTENT]
                  children = mainRewards.len() > 2 ? [
                    mkVerticalPannableArea(
                      cont,
                      {},
                      { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
                    scrollArrowsBlock
                  ] : cont
              }
              currencyConversions.len() <= 1 ? null
                : {
                    padding = const [hdpx(40), 0]
                    flow = FLOW_HORIZONTAL
                    gap = hdpx(10)
                    halign = ALIGN_CENTER
                    children = [
                      {
                        rendObj = ROBJ_TEXT
                        text = loc("debriefing/total")
                      }.__update(fontSmall)
                      mkCurrencyComp(sum, "gold")
                    ]
                  }
              !isOnlyBlueprints ? null
                : {
                    rendObj = ROBJ_TEXTAREA
                    behavior = Behaviors.TextArea
                    halign = ALIGN_CENTER
                    maxWidth = hdpx(600)
                    text = "\n".concat(loc("mainmenu/convertReward/desc"), loc("mainmenu/convertCourse"))
                    hplace = ALIGN_CENTER
                  }.__update(fontSmall)
            ]
          }
      tapToContinueText
    ]
  }
}

let mkDiscountTag = @(discount, ovr = {}, textOvr = {}) discountTag(discount, {
  hplace = ALIGN_LEFT
  vplace = ALIGN_TOP
  pos = const [0, 0]
  size = const [hdpx(93), hdpx(46)]
  color = 0xFFE00000
}.__update(ovr), { pos = null }.__update(fontTinyAccented, textOvr))

let mkDiscountRow = @(reward = null, prevDiscount = null, discount = null) @() {
  watch = serverConfigs
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  children = !reward
    ? null
    : [
        {
          size = FLEX_H
          halign = ALIGN_CENTER
          children = [
            mkRewardPlate(reward, REWARD_STYLE_MEDIUM)
            {
              size = getRewardPlateSize(reward.slots, REWARD_STYLE_MEDIUM)
              children = mkDiscountTag(prevDiscount)
            }
          ]
        }
        arrowIcon
        {
          size = FLEX_H
          halign = ALIGN_CENTER
          children = [
            mkRewardPlate(reward, REWARD_STYLE_MEDIUM)
            {
              size = getRewardPlateSize(reward.slots, REWARD_STYLE_MEDIUM)
              children = mkDiscountTag(discount, { size = const [hdpx(116), hdpx(58)] }, fontSmallAccented)
            }
          ]
        }
      ]
}

function mkMsgDiscount(stackDataV, onClick) {
  let discountsHeader = modalWndHeader(loc("mainmenu/discounts"))
  return function() {
    let watch = [serverConfigs, allShopGoods, servProfile, discountsToApply]
    let { personalDiscounts = {} } = serverConfigs.get()
    let minDiscountsByGoodsId = {}
    let mainRewards = {}
    let maxMainRewards = {}
    local singleRewards = {}
    foreach(info in stackDataV) {
      let goodsId = personalDiscounts.findindex(@(list) list.findindex(@(v) v.id == info.id) != null)
      let reward = getRewardsViewInfo([info])?[0]

      if (!goodsId || !reward)
        continue

      let goods = allShopGoods.get()?[goodsId]
      if (goods == null)
        continue
      let previewReward = shopGoodsToRewardsViewInfo(goods).sort(sortRewardsViewInfo)?[0]
      if (previewReward && isRewardEmpty([previewReward.__merge({ gType = previewReward.rType })], servProfile.get()))
        continue

      let serverDiscounts = clone personalDiscounts[goodsId]
      let sortedDiscountsByPrice = serverDiscounts.sort(@(a, b) b.price <=> a.price)
      let prevDiscountIdx = (sortedDiscountsByPrice.findindex(@(v) v.id == info.id) ?? -1) - 1

      let prevDiscount = (prevDiscountIdx >= 0 && sortedDiscountsByPrice?[prevDiscountIdx].id in servProfile.get()?.discounts)
        ? calculateNewGoodsDiscount(goods?.price.price ?? 0, goods?.discountInPercent ?? 0,
            sortedDiscountsByPrice?[prevDiscountIdx].price ?? 0)
        : serverConfigs.get()?.allGoods.findvalue(@(v) v.id == goodsId)?.discountInPercent ?? 0

      if (prevDiscount == 0)
        singleRewards[info.id] <- reward.__merge({ goodsId })
      else {
        let mainReward = {
          goodsId
          reward
          discount = applyDiscount(goods, discountsToApply.get()).discountInPercent
          prevDiscount
        }
        mainRewards[info.id] <- mainReward

        if (goodsId not in maxMainRewards || prevDiscount > maxMainRewards[goodsId].prevDiscount)
          maxMainRewards[goodsId] <- mainReward
      }

      if (goodsId in minDiscountsByGoodsId)
        minDiscountsByGoodsId[goodsId] = min(minDiscountsByGoodsId[goodsId], prevDiscount)
      else
        minDiscountsByGoodsId[goodsId] <- prevDiscount
    }

    if (mainRewards.len() == 0 && singleRewards.len() == 0)
      return { watch }

    let agregatedMainRewards = mainRewards.filter(@(data)
      data.goodsId in minDiscountsByGoodsId && data.prevDiscount <= minDiscountsByGoodsId[data.goodsId])

    singleRewards = singleRewards.reduce(function(acc, data) {
      let { goodsId } = data
      if (goodsId in minDiscountsByGoodsId && minDiscountsByGoodsId[goodsId] == 0 && goodsId in maxMainRewards)
        acc[goodsId] <- maxMainRewards[goodsId].reward
      if (goodsId not in acc)
        acc[goodsId] <- data
      return acc
    }, {})

    let needPannableArea = agregatedMainRewards.len() + singleRewards.len() > 2

    let mainContent = {
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = hdpx(35)
      children = agregatedMainRewards.map(@(data) mkDiscountRow(data.reward, data.prevDiscount, data.discount)).values()
    }

    let singleContent = {
      size = FLEX_H
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = hdpx(35)
      children = singleRewards.map(@(reward) mkRewardPlate(reward, REWARD_STYLE_MEDIUM)).values()
    }

    return {
      watch
      minWidth = minWidthWnd
      padding = const [0,0, padding, 0]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      behavior = Behaviors.Button
      onClick
      flow = FLOW_VERTICAL
      children = [
        discountsHeader
        {
          flow = FLOW_VERTICAL
          padding = padding
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          children = [
            {
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              halign = ALIGN_CENTER
              maxWidth = hdpx(600)
              margin = const [0, 0, hdpx(20), 0]
              text = loc("mainmenu/discount/desc")
              hplace = ALIGN_CENTER
            }.__update(fontSmall)
            {
              size = [minWidthWnd, needPannableArea ? maxHeightContent : SIZE_TO_CONTENT]
              children = needPannableArea
                ? [
                    mkVerticalPannableArea(
                      {
                        size = FLEX_H
                        flow = FLOW_VERTICAL
                        children = [
                          mainContent
                          singleContent
                        ]
                      },
                      {},
                      { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
                    scrollArrowsBlock
                  ]
                : [
                    mainContent
                    singleContent
                  ]
            }
          ]
        }
        tapToContinueText
      ]
    }
  }
}

return {
  mkMsgConvert
  mkMsgDiscount
  mkUnitButton
  mkBlueprintPlate
  mkUnitPlate
  arrowIcon
}