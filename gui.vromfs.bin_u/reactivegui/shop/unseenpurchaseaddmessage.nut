from "%globalsDarg/darg_library.nut" import *

let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { G_CURRENCY, G_BLUEPRINT, G_UNIT } = require("%appGlobals/rewardType.nut")
let { mkRewardPlateBg, mkRewardPlateImage, mkProgressLabel, mkProgressBar, mkRewardTextLabel, mkRewardPlateTexts,
  mkRewardPlate, mkRewardUnitFlag, getRewardPlateSize
} = require("%rGui/rewards/rewardPlateComp.nut")
let { modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { REWARD_STYLE_MEDIUM, REWARD_STYLE_SMALL } = require("%rGui/rewards/rewardStyles.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { getRewardsViewInfo, shopGoodsToRewardsViewInfo, sortRewardsViewInfo, isRewardEmpty } = require("%rGui/rewards/rewardViewInfo.nut")
let { allShopGoods, calculateNewGoodsDiscount } = require("%rGui/shop/shopState.nut")
let { discountTag } = require("%rGui/components/discountTag.nut")


let textColor = 0xFFE0E0E0

let padding = hdpx(50)
let minWidthWnd = hdpx(900)
let maxHeightContent = hdpx(400)


let mkTapToContinueText = @() {
  rendObj = ROBJ_TEXT
  color = textColor
  text = loc("TapAnyToContinue")
  vplace = ALIGN_BOTTOM
}.__update(fontSmall)

let exceedBlueprintsProgress = @(count, targetCount) {
  size = flex()
  valign = ALIGN_BOTTOM
  children = [
    mkProgressBar(targetCount + count, targetCount)
    mkProgressLabel(targetCount + count, targetCount, REWARD_STYLE_SMALL)
  ]
}

let fromCtor = {
  [G_BLUEPRINT] = @(reward) @() {
    watch = serverConfigs
    children = [
      mkRewardPlateBg(reward, REWARD_STYLE_MEDIUM)
      mkRewardPlateImage(reward, REWARD_STYLE_MEDIUM)
      reward.count >= 0
        ? exceedBlueprintsProgress(reward.count, serverConfigs.get()?.allBlueprints[reward.id].targetCount ?? 1)
        : mkRewardTextLabel(-reward.count, REWARD_STYLE_SMALL)
      mkRewardUnitFlag(serverConfigs.get()?.allUnits?[reward.id], REWARD_STYLE_MEDIUM)
    ]
  },

  [G_CURRENCY] = @(reward) mkRewardPlate(reward, REWARD_STYLE_MEDIUM),

  [G_UNIT] = @(reward) @() {
    watch = serverConfigs
    children = [
      mkRewardPlateBg(reward, REWARD_STYLE_MEDIUM)
      mkRewardPlateImage(reward, REWARD_STYLE_MEDIUM)
      mkRewardPlateTexts(reward, REWARD_STYLE_MEDIUM)
      mkRewardUnitFlag(serverConfigs.get()?.allUnits?[reward.id], REWARD_STYLE_MEDIUM)
    ]
  },
}

let mkConvertRow = @(reward, toReward) @() {
  watch = serverConfigs
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  children = [
    {
      size = FLEX_H
      halign = ALIGN_CENTER
      children = fromCtor?[reward?.rType](reward)
    }
    {
      rendObj = ROBJ_IMAGE
      size = const [hdpx(100), hdpx(70)]
      vplace = ALIGN_CENTER
      image = Picture($"ui/gameuiskin#arrow_icon.svg:{hdpx(100)}:{hdpx(70)}:P")
    }
    {
      size = FLEX_H
      halign = ALIGN_CENTER
      children = mkRewardPlate(toReward, REWARD_STYLE_MEDIUM)
    }
  ]
}


let mkVerticalPannableArea = verticalPannableAreaCtor(maxHeightContent, [hdpx(10), hdpx(90)])
let scrollHandler = ScrollHandler()

let scrollArrowsBlock = {
  size = const [SIZE_TO_CONTENT, maxHeightContent]
  hplace = ALIGN_CENTER
  children = [
    mkScrollArrow(scrollHandler, MR_T, scrollArrowImageSmall)
    mkScrollArrow(scrollHandler, MR_B, scrollArrowImageSmall)
  ]
}

function mkMsgConvert(stackDataV, onClick) {
  let mainRewards = {}
  local sum = 0
  local isOnlyBlueprints = true
  foreach(info in stackDataV) {
    sum = sum + info.to.count
    isOnlyBlueprints = isOnlyBlueprints && info.from.gType == G_BLUEPRINT
    local amount = info.from.count
    mainRewards[info.from.id] <- {
      reward = getRewardsViewInfo([{
        id = info.from.id
        gType = info.from.gType
        count = amount >= 0 ? amount : -amount
        subId = info.from.subId
      }])[0],
      toReward = getRewardsViewInfo([{
        id = info.to.id
        gType = info.to.gType
        count = info.to.count
        subId = info.to.subId
      }])[0]
    }
  }
  let cont = {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = hdpx(35)
    children = mainRewards.map(@(data) mkConvertRow(data.reward, data.toReward)).values()
  }
  return {
    minWidth = minWidthWnd
    padding = [0,0, padding, 0]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick
    flow = FLOW_VERTICAL
    children = [
      modalWndHeader(loc("mainmenu/convert"))
      {
        flow = FLOW_VERTICAL
        padding = padding
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          {
              size = [minWidthWnd, SIZE_TO_CONTENT]
              children = mainRewards.len() > 2 ? [
                mkVerticalPannableArea(
                  cont,
                  {},
                  { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
                scrollArrowsBlock
              ] : cont
          }
          stackDataV.len() <= 1 ? null
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
      mkTapToContinueText()
    ]
  }
}

let mkDiscountTag = @(discount, ovr = {}, textOvr = {}) discountTag(discount, {
  hplace = ALIGN_LEFT
  vplace = ALIGN_TOP
  pos = [0, 0]
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
        {
          rendObj = ROBJ_IMAGE
          size = const [hdpx(100), hdpx(70)]
          vplace = ALIGN_CENTER
          image = Picture($"ui/gameuiskin#arrow_icon.svg:{hdpx(100)}:{hdpx(70)}:P")
        }
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

    let goods = allShopGoods.get()?[goodsId] ?? {}
    let previewReward = shopGoodsToRewardsViewInfo(goods).sort(sortRewardsViewInfo)?[0]

    if (previewReward && isRewardEmpty([previewReward.__merge({ gType = previewReward.rType })], servProfile.get()))
      continue

    let serverDiscounts = clone personalDiscounts[goodsId]
    let sortedDiscountsByPrice = serverDiscounts.sort(@(a, b) b.price <=> a.price)
    let prevDiscountIdx = (sortedDiscountsByPrice.findindex(@(v) v.id == info.id) ?? -1) - 1

    let prevDiscount = (prevDiscountIdx >= 0 && sortedDiscountsByPrice?[prevDiscountIdx].id in servProfile.get()?.discounts)
      ? calculateNewGoodsDiscount(goods?.price.price ?? 0, goods?.discountInPercent ?? 0,
          sortedDiscountsByPrice?[prevDiscountIdx].price ?? 0)
      : campConfigs.get()?.allGoods.findvalue(@(v) v.id == goodsId)?.discountInPercent ?? 0

    if (prevDiscount == 0)
      singleRewards[info.id] <- reward.__merge({ goodsId })
    else {
      let mainReward = {
        goodsId
        reward
        discount = goods?.discountInPercent
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
    return onClick()

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
    minWidth = minWidthWnd
    padding = [0,0, padding, 0]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick
    flow = FLOW_VERTICAL
    children = [
      modalWndHeader(loc("mainmenu/discounts"))
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
            children = needPannableArea ? [
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
            ] : [
                  mainContent
                  singleContent
                ]
          }
        ]
      }
      mkTapToContinueText()
    ]
  }
}

return {
  mkMsgConvert
  mkMsgDiscount
}