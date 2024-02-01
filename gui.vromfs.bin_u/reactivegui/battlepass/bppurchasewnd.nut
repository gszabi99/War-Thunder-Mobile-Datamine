from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("math")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { registerScene, setSceneBg } = require("%rGui/navState.nut")
let { isBPPurchaseWndOpened, closeBPPurchaseWnd, curStage, sendBpBqEvent,
  isBpPurchased, bpPurchasedUnlock, bpPaidRewardsUnlock, battlePassGoods, bpIconActive
} = require("battlePassState.nut")
let { buyPlatformGoods } = require("%rGui/shop/platformGoods.nut")
let purchaseGoods = require("%rGui/shop/purchaseGoods.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getRewardsViewInfo, joinViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")

let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let battlePassSeason = require("battlePassSeason.nut")
let { mkRewardPlate } = require("%rGui/rewards/rewardPlateComp.nut")
let { bpCardStyle } = require("bpCardsStyle.nut")
let { textButtonPricePurchase, buttonStyles } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = buttonStyles
let { mkPriceExtText, mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { doubleSideGradient } = require("%rGui/components/gradientDefComps.nut")

let { boxSize, boxGap } = bpCardStyle
let rewardsListGap = 1.5 * boxGap
let bigGap = 2 * boxGap
let bpIconSize = hdpxi(400)
let blocksGap = isWidescreen ? 3 * boxGap : boxGap
//allow rewards a bit go out of safeArea
let rewardSlotsInRow = (saSize[0] - bpIconSize + boxGap + boxSize / 2) / (boxSize + boxGap)

let header = {
  size = [flex(), gamercardHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    backButton(closeBPPurchaseWnd)
    battlePassSeason
  ]
}

let mkRewardInstant = @(vInfo) mkRewardPlate(vInfo, bpCardStyle)

let rangeText = @(range) range[0] == range[1] ? range[0].tostring()
  : $"{range[0]}-{range[1]}"

let mkRewardWithProgress = @(vInfo) {
  flow = FLOW_VERTICAL
  gap = hdpx(5)
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      valign = ALIGN_BOTTOM
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("mainmenu/rank/short")
        }.__update(fontVeryTiny)
        {
          hplace = ALIGN_RIGHT
          rendObj = ROBJ_TEXT
          text = rangeText(vInfo.sRange)
        }.__update(fontTiny)
      ]
    }
    mkRewardPlate(vInfo, bpCardStyle)
  ]
}

function rewardsBlock(text, viewInfo, rewardCtor) {
  if (viewInfo.len() == 0)
    return null

  let totalSlots = viewInfo.reduce(@(res, v) res + v.slots, 0)
  let totalRows = max(1, ceil(totalSlots.tofloat() / rewardSlotsInRow).tointeger())
  let slotsPerRow = ceil(totalSlots.tofloat() / totalRows).tointeger()

  let byRows = array(totalRows).map(@(_) { slotsLeft = slotsPerRow, list = [] })
  foreach(v in viewInfo)
    foreach(idx, row in byRows)
      if (idx >= totalRows - 1 || row.slotsLeft >= v.slots) {
        row.slotsLeft -= v.slots
        row.list.append(v)
        break
      }

  return {
    flow = FLOW_VERTICAL
    gap = boxGap
    halign = ALIGN_CENTER
    children = [
      { rendObj = ROBJ_TEXT, text = $"{text}{colon}" }.__update(fontSmallAccented)
    ]
      .extend(byRows.map(@(row) {
        flow = FLOW_HORIZONTAL
        gap = boxGap
        halign = ALIGN_CENTER
        children = row.list.map(rewardCtor)
      }))
  }
}

function rewardsToViewInfo(rewards, servConfigs) {
  let res = []
  foreach(id, data in rewards) {
    let reward = servConfigs?.userstatRewards[id]
    if (!reward)
      continue
    let viewInfo = getRewardsViewInfo(reward, data.count)
      .map(@(vi) vi.__update({ sRange = data.sRange }))
    joinViewInfo(res, viewInfo,
      function(to, from) {
        to.sRange = [min(to.sRange[0], from.sRange[0]), max(to.sRange[1], from.sRange[1])]
      })
  }
  return res
}

function rewardsList() {
  let res = { watch = [bpPurchasedUnlock, bpPaidRewardsUnlock, curStage, serverConfigs] }
  if (bpPaidRewardsUnlock.value == null)
    return res
  let { lastRewardedStage = 0, stages = [] } = bpPaidRewardsUnlock.value

  let rewardsOnPurchase = (bpPurchasedUnlock.value?.stages[0].rewards ?? {})
    .map(@(count) { count, sRange = [0, 0] })
  let rewardsOnProgress = {}
  foreach (idx, s in stages) {
    if (idx < lastRewardedStage)
      continue
    let list = s.progress <= curStage.value ? rewardsOnPurchase : rewardsOnProgress
    foreach(key, count in s.rewards)
      if (key not in list)
        list[key] <- { count, sRange = [s.progress, s.progress] }
      else {
        list[key].count += count
        list[key].sRange[1] = s.progress
      }
  }

  let viewInfoOnPurchase = rewardsToViewInfo(rewardsOnPurchase, serverConfigs.value)
    .sort(sortRewardsViewInfo)
  let viewInfoOnProgress = rewardsToViewInfo(rewardsOnProgress, serverConfigs.value)
    .sort(sortRewardsViewInfo)

  return res.__update({
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = rewardsListGap
    children = [
      rewardsBlock(loc("battlePass/receiveOnPurchase"), viewInfoOnPurchase, mkRewardInstant)
      rewardsBlock(loc("battlePass/receiveOnProgress"), viewInfoOnProgress, mkRewardWithProgress)
    ]
  })
}

let battlePassHeader = {
  rendObj = ROBJ_TEXT
  text = loc("battlePass")
}.__update(fontBig)

let battlePassIcon = @() {
  watch = bpIconActive
  size = [bpIconSize, bpIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"{bpIconActive.get()}:{0}:P")
  fallbackImage = Picture($"ui/gameuiskin#bp_icon_not_active.avif:{0}:P")
  keepAspect = true
}

function buyBlock() {
  let { price = null, priceExt = null } = battlePassGoods.value
  return {
    watch = [isBpPurchased, battlePassGoods]
    size = [flex(), defButtonHeight]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = isBpPurchased.value
        ? {
            rendObj = ROBJ_TEXT
            text = loc("battlePass/alreadyBought")
          }.__update(fontSmall)
      : (price?.price ?? 0) > 0
        ? textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")),
          mkCurrencyComp(price.price, price.currencyId)
          function() {
            sendBpBqEvent("purchase_pass_press")
            purchaseGoods(battlePassGoods.value?.id)
          },
          { ovr = { minWidth = bpIconSize }})
      : (priceExt?.price ?? 0) > 0
        ? textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")),
          mkPriceExtText(priceExt.price, priceExt.currencyId)
          function() {
            sendBpBqEvent("purchase_pass_press")
            buyPlatformGoods(battlePassGoods.value)
          },
          { ovr = { minWidth = bpIconSize }})
      : {
          size = [flex(), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc("error/googleplay/GP_ITEM_UNAVAILABLE")
          halign = ALIGN_CENTER
        }.__update(fontSmall)
  }
}

let rightBlock = {
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_VERTICAL
  gap = { size = flex() }
  children = [
    battlePassIcon
    buyBlock
  ]
}

let content = doubleSideGradient.__merge({
  padding = [boxGap - 0.3 * fontBig.fontSize, bigGap, boxGap, bigGap]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = bigGap
  children = [
    battlePassHeader
    {
      minHeight = bpIconSize + defButtonHeight
      flow = FLOW_HORIZONTAL
      gap = blocksGap
      valign = ALIGN_CENTER
      children = [
        rewardsList
        rightBlock
      ]
    }
  ]
})

let bpPurchaseWnd = {
  key = {}
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    header
    content
  ]
  animations = wndSwitchAnim
}

registerScene("bpPurchaseWnd", bpPurchaseWnd, closeBPPurchaseWnd, isBPPurchaseWndOpened)
setSceneBg("bpPurchaseWnd", "ui/images/bp_bg_01.avif")
