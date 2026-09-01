from "%rGui/style/gamercardStyle.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/currenciesState.nut" import WP, GOLD, PLATINUM
from "%appGlobals/pServer/campaign.nut" import curCampaign, campConfigs, purchasesCount, todayPurchasesCount,
  goodsLimitReset
from "%appGlobals/pServer/profile.nut" import playerLevelInfo, campMyUnits
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/pServer/seasonCurrencies.nut" import sortByCurrencyId
import "%appGlobals/pServer/unreleasedUnits.nut" as unreleasedUnits
from "%appGlobals/rewardType.nut" import G_CURRENCY
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%appGlobals/userstats/serverTimeDay.nut" import serverTimeDay, dayOffset
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/currencyStyles.nut" import gamercardGap
from "%rGui/components/gradientDefComps.nut" import doubleSideGradient
from "%rGui/components/levelBlockPkg.nut" import mkLevelBg, mkProgressLevelBg, playerExpColor, rotateCompensate,
  levelProgressBarWidth
from "%rGui/components/starLevel.nut" import starLevelSmall
from "%rGui/components/unseenMark.nut" import priorityUnseenMark, unseenSize
from "%rGui/decorators/decoratorState.nut" import myNameWithFrame, myAvatarImage, hasUnseenDecorators
from "%rGui/decorators/decoratorsPkg.nut" import mkTitle
from "%rGui/event/buyEventCurrenciesState.nut" import openBuyEventCurrenciesWnd
from "%rGui/mainMenu/balanceComps.nut" import mkCurrencyBalance
import "%rGui/mainMenu/premIconWithTimeOnChange.nut" as premIconWithTimeOnChange
from "%rGui/options/accountOptionsScene.nut" import accountOptionsScene
from "%rGui/shop/goodsPreviewState.nut" import openGoodsPreview
from "%rGui/shop/goodsUtils.nut" import getGoodsByCurrencyId
from "%rGui/shop/shopCommon.nut" import SC_GOLD, SC_WP, SC_PLATINUM
from "%rGui/shop/shopState.nut" import openShopWnd, shopGoods, soonGoods
from "%rGui/state/profilePremium.nut" import havePremium
from "%rGui/style/gradients.nut" import gradCircularSmallHorCorners, gradCircCornerOffset
from "%rGui/style/stdColors.nut" import textColor, premiumTextColor, hoverColor
from "%rGui/unit/components/unitLevelComp.nut" import mkUnitLevelBlock
from "%rGui/unit/hangarUnit.nut" import hangarUnit


const nextLevelBorderColor = 0xFFDADADA
const nextLevelBgColor = 0xFF464646
const nextLevelTextColor = 0xFFFFFFFF

let profileStateFlags = Watched(0)


let openCfg = {
  [WP] = @() openShopWnd(SC_WP),
  [GOLD] = @() openShopWnd(SC_GOLD),
  [PLATINUM] = @() openShopWnd(SC_PLATINUM),
}

let openBuyCurrencyWnd = @(curId) openCfg?[curId] ?? @() openBuyEventCurrenciesWnd(curId)

let ownHangarUnit = Computed(@() hangarUnit.get()?.__merge(campMyUnits.get()?[hangarUnit.get()?.name] ?? {}))

let textParams = {
  rendObj = ROBJ_TEXT
}.__update(fontSmallShaded)

let avatar = @() {
  watch = [myAvatarImage, hasUnseenDecorators]
  rendObj = ROBJ_IMAGE
  size = [avatarSize, avatarSize]
  image = Picture($"{myAvatarImage.get()}:{avatarSize}:{avatarSize}:P")
  halign = ALIGN_RIGHT
  children = {
    pos = [unseenSize[0] / 2, -unseenSize[1] / 2]
    children = hasUnseenDecorators.get() ? priorityUnseenMark : null
  }
}

let name =  @() textParams.__merge({
  watch = [havePremium, myNameWithFrame]
  vplace = ALIGN_CENTER
  text = myNameWithFrame.get() ?? ""
  color = havePremium.get() ? premiumTextColor : textColor
})

let starLevelOvr = {
  pos = const [pw(40), ph(40)]
  transform = { rotate = -45 }
}

let levelBlock = @(ovr = {}, progressOvr = {}, needTargetLevel = false) function() {
  let { exp, nextLevelExp, level, starLevel, historyStarLevel,
    isStarProgress, isMaxLevel
  } = playerLevelInfo.get()
  let progresOffset = levelHolderSize * rotateCompensate
  let showStarLevel = max(starLevel, historyStarLevel)
  let nextStarLevel = isStarProgress ? starLevel + 1 : 0
  return {
    watch = [playerLevelInfo, unreleasedUnits]
    valign = ALIGN_CENTER
    pos = [levelHolderPlace, levelHolderPlace]
    padding = [0, progresOffset]
    children = [
      mkProgressLevelBg({
        key = playerLevelInfo.get()
        children = {
          size = isMaxLevel ? FLEX : [pw(clamp(99.0 * exp / nextLevelExp, 0, 99)), FLEX]
          rendObj = ROBJ_SOLID
          color = playerExpColor
        }
      }.__update(progressOvr))
      mkLevelBg({
        ovr = {
          size = [levelHolderSize, levelHolderSize]
          pos = [-progresOffset, 0]
          color = 0xFF000000
          transform = { rotate = 45 }
        }
        childOvr = {
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = [
            textParams.__merge({
              text = level - starLevel
              transform = { rotate = -45 }
            })
            starLevelSmall(showStarLevel, starLevelOvr)
          ]
        }
      })
      !needTargetLevel || isMaxLevel ? null
        : mkLevelBg({
            ovr = {
              size = [levelHolderSize, levelHolderSize]
              hplace = ALIGN_RIGHT
              pos = [progresOffset, 0]
              color = 0xFF000000
              transform = { rotate = 45 }
            }
            childOvr = {
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
              fillColor = nextLevelBgColor
              borderColor = nextLevelBorderColor
              children = [
                textParams.__merge({
                  text = level - starLevel + (isStarProgress ? 0 : 1)
                  color = nextLevelTextColor
                  transform = { rotate = -45 }
                })
                starLevelSmall(nextStarLevel, starLevelOvr)
              ]
            }
          })
    ]
  }.__update(ovr)
}


let hoverBg = {
  size = const [pw(120), FLEX]
  color = hoverColor
  opacity = 1
  rendObj = ROBJ_9RECT
  image = gradCircularSmallHorCorners
  screenOffs = hdpx(100)
  texOffs = gradCircCornerOffset
}

let gamercardProfile = @() {
  watch = profileStateFlags
  behavior = Behaviors.Button
  onElemState = @(sf) profileStateFlags.set(sf)
  onClick = @() accountOptionsScene()
  sound = { click  = "meta_profile_button" }
  children = [
    {
      size = [levelProgressBarWidth + avatarSize, FLEX]
      children = profileStateFlags.get() & S_HOVER ? hoverBg : null
    }
    {
      flow = FLOW_HORIZONTAL
      size = [SIZE_TO_CONTENT, avatarSize]
      gap = profileGap
      children = [
        avatar
        {
          flow = FLOW_VERTICAL
          vplace = ALIGN_CENTER
          children = [
            name
            mkTitle(fontTinyAccentedShaded)
          ]
        }
      ]
    }
    levelBlock()
  ]
}

function platoonOrUnitTitle(unit) {
  let { isUpgraded = false, isPremium = false } = unit
  let isElite = isUpgraded || isPremium
  let text = getUnitName(unit)
  return {
    minWidth = hdpx(500)
    children = [
      {
        margin = [0, 0, 0, evenPx(84)]
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        pos = const [0, -hdpx(20)]
        gap = hdpx(20)
        children = [
          !isElite ? null : {
            size = const [hdpx(90), hdpx(40)]
            rendObj = ROBJ_IMAGE
            keepAspect = KEEP_ASPECT_FIT
            image = Picture("ui/gameuiskin#icon_premium.svg")
          }
          {
            rendObj = ROBJ_TEXT
            color = isElite ? premiumTextColor : textColor
            text
          }.__update(fontSmallShaded)
        ]
      }
      mkUnitLevelBlock(unit)
    ]
  }
}

function gamercardUnitLevelLine(unit, keyHintText) {
  let maxLevel = Computed(@() unit?.maxLevel ?? campConfigs.get()?.unitLevels[unit?.levelPreset].len() ?? 0) 
  return {
    children = [
      platoonOrUnitTitle(unit)
      {
        size = 0
        children = doubleSideGradient.__merge(
          {
            padding = const [hdpx(5), hdpx(50)]
            pos = const [hdpx(30) hdpx(55)]
            children = @() {
              watch = [curCampaign, maxLevel]
              halign = ALIGN_LEFT
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              maxWidth = hdpx(700)
              text = (unit?.level ?? -1) >= maxLevel.get() || unit?.isUpgraded || unit?.isPremium
                ? loc(getCampaignPresentation(curCampaign.get()).unitLevelMaxLocId)
                : loc(keyHintText)
            }.__update(fontVeryTiny)
          })
      }
    ]
  }
}

let mkLeftBlock = @(backCb, menuBtn = null) {
  size = [ SIZE_TO_CONTENT, gamercardHeight ]
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_LEFT
  gap = gamercardGap
  children = [
    backCb != null ? backButton(backCb, { vplace = ALIGN_CENTER }) : null
    menuBtn
    gamercardProfile
  ]
}

let mkLeftBlockUnitCampaign = @(backCb, keyHintText, unit = ownHangarUnit, backBtnOvr = {}) @() {
  watch = unit
  size = [ SIZE_TO_CONTENT, gamercardHeight ]
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_LEFT
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = [
    backCb != null ? backButton(backCb, { vplace = ALIGN_CENTER }.__update(backBtnOvr)) : null
    unit.get() == null ? null : gamercardUnitLevelLine(unit.get(), keyHintText)
  ]
}

let mkGamercard = @(menuBtn, backCb = null) {
  size = [ saSize[0], gamercardHeight ]
  hplace = ALIGN_CENTER
  children = [
    mkLeftBlock(backCb, menuBtn)
    {
      size = [ SIZE_TO_CONTENT, avatarSize ]
      flow = FLOW_HORIZONTAL
      hplace = ALIGN_RIGHT
      valign = ALIGN_CENTER
      gap = gamercardGap
      children = [
        premIconWithTimeOnChange
        mkCurrencyBalance(WP, openBuyCurrencyWnd(WP))
        mkCurrencyBalance(GOLD, openBuyCurrencyWnd(GOLD))
        mkCurrencyBalance(PLATINUM, openBuyCurrencyWnd(PLATINUM))
      ]
    }
  ]
}

let gamercardWithoutLevelBlock = {
  size = [ saSize[0], gamercardHeight ]
  hplace = ALIGN_CENTER
  children =
    {
      size = [ SIZE_TO_CONTENT, avatarSize ]
      flow = FLOW_HORIZONTAL
      hplace = ALIGN_RIGHT
      valign = ALIGN_CENTER
      gap = gamercardGap
      children = [
        premIconWithTimeOnChange
        mkCurrencyBalance(WP, @() openShopWnd(SC_WP))
        mkCurrencyBalance(GOLD, @() openShopWnd(SC_GOLD))
      ]
    }
}

let mkGamercardUnitCampaign = @(backCb, keyHintText, unit = ownHangarUnit) {
  size = [ saSize[0], gamercardHeight ]
  hplace = ALIGN_CENTER
  children = [
    mkLeftBlockUnitCampaign(backCb, keyHintText, unit)
    gamercardWithoutLevelBlock
  ]
}

let isGoodsForCurrency = @(g, cId) g.rewards.len() == 1
  && g.rewards[0].gType == G_CURRENCY
  && g.rewards[0].id == cId

let hasCurrencyShop = @(cId, goods, soon) cId in openCfg
  || null != goods.findvalue(@(g) isGoodsForCurrency(g, cId))
  || null != soon.findvalue(@(g) isGoodsForCurrency(g, cId))

function mkCurrencyOpenAction(cId, goods, soon, configs, limitReset, dOffset, servTimeDay, purchCount, todayPurchCount) {
  if (hasCurrencyShop(cId, goods, soon))
    return openBuyCurrencyWnd(cId)
  let goodsId = getGoodsByCurrencyId(cId, goods.__merge(soon), configs, limitReset, dOffset, servTimeDay,
    purchCount, todayPurchCount)?.id
  return goodsId == null ? null : @() openGoodsPreview(goodsId)
}

let mkCurrenciesBtns = @(currencies, noActionCurrencies = {}, ovr = {}) {
  size = FLEX_H
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
  children = @() {
    watch = [shopGoods, soonGoods, serverConfigs, goodsLimitReset, dayOffset, serverTimeDay,
      purchasesCount, todayPurchasesCount]
    flow = FLOW_HORIZONTAL
    halign = ALIGN_RIGHT
    valign = ALIGN_CENTER
    gap = gamercardGap
    children = !currencies ? null
      : [].extend(currencies)
          .sort(@(a, b) sortByCurrencyId(b, a)) 
          .map(@(c) mkCurrencyBalance(c, noActionCurrencies?[c] ? null
            : mkCurrencyOpenAction(c, shopGoods.get(), soonGoods.get(), serverConfigs.get(),
                goodsLimitReset.get(), dayOffset.get(), serverTimeDay.get(), purchasesCount.get(), todayPurchasesCount.get())))
  }
}.__update(ovr)

let gamercardBalanceBtns = mkCurrenciesBtns([WP, GOLD])

return {
  levelBlock
  mkLeftBlock
  mkLeftBlockUnitCampaign
  mkGamercard
  mkGamercardUnitCampaign
  gamercardBalanceBtns
  mkCurrenciesBtns
}
