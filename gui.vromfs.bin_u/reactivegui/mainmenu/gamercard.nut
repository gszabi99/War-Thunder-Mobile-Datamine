from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/gamercardStyle.nut" import *
let { openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let { havePremium } = require("%rGui/state/profilePremium.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { WP, GOLD, PLATINUM, orderByCurrency } = require("%appGlobals/currenciesState.nut")
let { SC_GOLD, SC_WP, SC_PLATINUM, SC_FEATURED } = require("%rGui/shop/shopCommon.nut")
let { openShopWnd, hasUnseenGoodsByCategory } = require("%rGui/shop/shopState.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { mkLevelBg, mkProgressLevelBg, playerExpColor, rotateCompensate, levelProgressBarWidth
} = require("%rGui/components/levelBlockPkg.nut")
let accountOptionsScene = require("%rGui/options/accountOptionsScene.nut")
let { itemsOrder } = require("%appGlobals/itemsState.nut")
let { mkCurrencyBalance, mkItemsBalance } = require("balanceComps.nut")
let { gamercardGap } = require("%rGui/components/currencyStyles.nut")
let { textColor, premiumTextColor } = require("%rGui/style/stdColors.nut")
let { gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let premIconWithTimeOnChange = require("premIconWithTimeOnChange.nut")
let { openExpWnd } = require("%rGui/mainMenu/expWndState.nut")
let { mkTitle } = require("%rGui/decorators/decoratorsPkg.nut")
let { myNameWithFrame, myAvatarImage, hasUnseenDecorators } = require("%rGui/decorators/decoratorState.nut")
let { priorityUnseenMark, unseenSize } = require("%rGui/components/unseenMark.nut")
let { openBuyEventCurrenciesWnd } = require("%rGui/event/buyEventCurrenciesState.nut")
let { doubleSideGradient } = require("%rGui/components/gradientDefComps.nut")
let { mkUnitLevelBlock } = require("%rGui/unit/components/unitLevelComp.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { curCampaign, isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let { getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let { starLevelSmall } = require("%rGui/components/starLevel.nut")
let { CS_GAMERCARD, CS_COMMON } = require("%rGui/components/currencyComp.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")


let nextLevelBorderColor = 0xFFDADADA
let nextLevelBgColor = 0xFF464646
let nextLevelTextColor = 0xFFFFFFFF
let receivedExpProgressColor = 0xFFFFFFFF
let levelUpTextColor = 0xFF000000

let levelStateFlags = Watched(0)
let nextLevelStateFlags = Watched(0)
let profileStateFlags = Watched(0)


let openCfg = {
  [WP] = @() openShopWnd(SC_WP),
  [GOLD] = @() openShopWnd(SC_GOLD),
  [PLATINUM] = @() openShopWnd(SC_PLATINUM),
}

let openBuyCurrencyWnd = @(curId) openCfg?[curId] ?? @() openBuyEventCurrenciesWnd(curId)

let needShopUnseenMark = Computed(@() hasUnseenGoodsByCategory.value.findindex(@(category) category == true))

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
  text = myNameWithFrame.value ?? ""
  color = havePremium.value ? premiumTextColor : textColor
})

let levelUpReadyAnim = { prop = AnimProp.opacity, duration = 3.0, easing = CosineFull, play = true, loop = true }
let levelUpReadyAnimsCur = [ levelUpReadyAnim.__merge({ from = 1.0, to = 0.0 }) ]
let levelUpReadyAnimsNext = [ levelUpReadyAnim.__merge({ from = 0.0, to = 1.0 }) ]

let starLevelOvr = {
  pos = [pw(40), ph(40)]
  transform = { rotate = -45 }
}

let levelBlock = @(ovr = {}, progressOvr = {}, needTargetLevel = false) function() {
  let { exp, nextLevelExp, level, isReadyForLevelUp, starLevel, isNextStarLevel, historyStarLevel,
    isStarProgress, isMaxLevel
  } = playerLevelInfo.value
  let progresOffset = levelHolderSize * rotateCompensate
  let onLevelClick = isReadyForLevelUp ? openLvlUpWndIfCan
    : !isMaxLevel && !isCampaignWithUnitsResearch.get() ? openExpWnd
    : null
  let showStarLevel = max(starLevel, historyStarLevel)
  let nextStarLevel = isStarProgress ? starLevel + 1 : 0
  return {
    watch = [playerLevelInfo, isCampaignWithUnitsResearch]
    valign = ALIGN_CENTER
    pos = [levelHolderPlace, levelHolderPlace]
    padding = [0, progresOffset]
    children = [
      mkProgressLevelBg({
        key = playerLevelInfo.value
        opacity = 1.0,
        animations = isReadyForLevelUp
          ? [ levelUpReadyAnim.__merge({ from = 0.5, to = 1.0 }) ]
          : null
        children = {
          size = isMaxLevel || isReadyForLevelUp ? flex() : [pw(clamp(99.0 * exp / nextLevelExp, 0, 99)), flex()]
          rendObj = ROBJ_SOLID
          color = playerExpColor
        }
      }.__update(progressOvr))
      @() mkLevelBg({
        ovr = {
          watch = levelStateFlags
          size = [levelHolderSize, levelHolderSize]
          pos = [-progresOffset, 0]
          onElemState = @(sf) levelStateFlags(sf)
          behavior = onLevelClick != null ? Behaviors.Button : null
          onClick = onLevelClick
          sound = { click  = "meta_profile_button" }
          color = levelStateFlags.value & S_HOVER ? 0xDD52C4E4 : 0xFF000000
          transform = {
            rotate = 45
            scale = levelStateFlags.value & S_ACTIVE ? [0.8, 0.8] : [1, 1]
          }
        }
        childOvr = {
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = [
            @() textParams.__merge({
              watch = levelStateFlags
              key = playerLevelInfo.value
              text = level - starLevel
              animations = isReadyForLevelUp && !isNextStarLevel ? levelUpReadyAnimsCur : null
              transform = {
                rotate = -45
                scale = levelStateFlags.value & S_ACTIVE ? [0.8, 0.8] : [1, 1]
              }
            })
            isReadyForLevelUp && !isNextStarLevel
              ? textParams.__merge({
                  key = playerLevelInfo.value
                  text = level + 1
                  opacity = 0.0
                  transform = {
                    rotate = -45
                  }
                  animations = levelUpReadyAnimsNext
                })
              : null
            starLevelSmall(showStarLevel,
              isReadyForLevelUp && nextStarLevel != showStarLevel
                ? starLevelOvr.__merge({ animations = levelUpReadyAnimsCur })
                : starLevelOvr)
            isReadyForLevelUp && nextStarLevel != showStarLevel
              ? starLevelSmall(nextStarLevel, starLevelOvr.__merge({ animations = levelUpReadyAnimsNext }))
              : null
          ]
        }
      })
      !needTargetLevel || isMaxLevel ? null
        : @() mkLevelBg({
            ovr = {
              watch = nextLevelStateFlags
              size = [levelHolderSize, levelHolderSize]
              hplace = ALIGN_RIGHT
              pos = [progresOffset, 0]
              onElemState = @(sf) nextLevelStateFlags(sf)
              behavior = onLevelClick != null ? Behaviors.Button : null
              onClick = onLevelClick
              color = nextLevelStateFlags.value & S_HOVER ? 0xDD52C4E4 : 0xFF000000
              transform = {
                rotate = 45
                scale = nextLevelStateFlags.value & S_ACTIVE ? [0.8, 0.8] : [1, 1]
              }
            }
            childOvr = {
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
              fillColor = isReadyForLevelUp ? receivedExpProgressColor : nextLevelBgColor
              borderColor = nextLevelBorderColor
              children = [
                @() textParams.__merge({
                  watch = nextLevelStateFlags
                  key = playerLevelInfo.value
                  text = level - starLevel + (isStarProgress ? 0 : 1)
                  color = isReadyForLevelUp ? levelUpTextColor : nextLevelTextColor
                  transform = {
                    rotate = -45
                    scale = nextLevelStateFlags.value & S_ACTIVE ? [0.8, 0.8] : [1, 1]
                  }
                })
                starLevelSmall(nextStarLevel, starLevelOvr)
              ]
            }
          })
      !isReadyForLevelUp ? null
        : {
            size = flex()
            hplace = ALIGN_LEFT
            behavior = Behaviors.Button
            onClick = openLvlUpWndIfCan
          }
    ]
  }.__update(ovr)
}


let hoverBg = {
  size = [pw(120), flex()]
  color = 0x8052C4E4
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
      size = [levelProgressBarWidth + avatarSize, flex()]
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
  let text = getPlatoonOrUnitName(unit, loc)
  return {
    minWidth = hdpx(500)
    children = [
      {
        margin = [0, 0, 0, evenPx(84)]
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        pos = [0, -hdpx(20)]
        gap = hdpx(20)
        children = [
          !isElite ? null : {
            size = [hdpx(90), hdpx(40)]
            rendObj = ROBJ_IMAGE
            keepAspect = KEEP_ASPECT_FIT
            image = Picture("ui/gameuiskin#icon_premium.svg")
          }
          {
            rendObj = ROBJ_TEXT
            color = isElite ? premiumTextColor : textColor
            fontFx = FFT_GLOW
            fontFxColor = 0xFF000000
            fontFxFactor = hdpx(64)
            text
          }.__update(fontSmall)
        ]
      }
      mkUnitLevelBlock(unit)
    ]
  }
}

let gamercardUnitLevelLine = @(unit, keyHintText){
  children = [
    platoonOrUnitTitle(unit)
    {
      size = [0, 0]
      children = doubleSideGradient.__merge(
        {
          padding = [hdpx(5), hdpx(50)]
          pos = [hdpx(30) hdpx(55)]
          children = @(){
            watch = curCampaign
            halign = ALIGN_LEFT
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            maxWidth = hdpx(700)
            text = (unit?.level ?? -1) == unit?.levels.len() || unit?.isUpgraded || unit?.isPremium
              ? loc($"gamercard/levelCamp/maxLevel/{curCampaign.value}")
              : loc(keyHintText)
          }.__update(fontVeryTiny)
        })
    }
  ]
}

let mkLeftBlock = @(backCb) {
  size = [ SIZE_TO_CONTENT, gamercardHeight ]
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_LEFT
  gap = gamercardGap
  children = [
    backCb != null ? backButton(backCb, { vplace = ALIGN_CENTER }) : null
    gamercardProfile
  ]
}

let mkLeftBlockUnitCampaign = @(backCb, keyHintText, unit = hangarUnit) @() {
  watch = unit
  size = [ SIZE_TO_CONTENT, gamercardHeight ]
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_LEFT
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = [
    backCb != null ? backButton(backCb, { vplace = ALIGN_CENTER }) : null
    unit.get() == null ? null : gamercardUnitLevelLine(unit.get(), keyHintText)
  ]
}

function mkShopImage(style) {
  let iconSize = style.iconSize
  return @() {
    watch = needShopUnseenMark
    rendObj = ROBJ_IMAGE
    size = [iconSize, iconSize]
    vplace = ALIGN_CENTER
    color = 0xFFFFFFFF
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"ui/gameuiskin#icon_shop.svg:{iconSize}:{iconSize}:P")
    children = needShopUnseenMark.get() ? priorityUnseenMark : null
  }
}

let mkShopText = @(style) {
  rendObj = ROBJ_TEXT
  text = utf8ToUpper(loc("topmenu/store"))
  color = style.textColor
  fontFxColor = style.fontFxColor
  fontFxFactor = style.fontFxFactor
  fontFx = style.fontFx
}.__update(style.fontStyle)

function shopBtn() {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    behavior = Behaviors.Button
    onClick = @() openShopWnd(SC_FEATURED)
    onElemState = @(sf) stateFlags.set(sf)
    sound = { click  = "meta_shop_buttons" }
    children = [
      {
        size = flex()
        vplace = ALIGN_CENTER
        padding = [hdpx(3), 0]
        children = stateFlags.get() & S_HOVER ? hoverBg : null
      }
      {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = hdpx(12)
        children = [
          mkShopImage(CS_COMMON)
          mkShopText(CS_GAMERCARD)
        ]
      }
    ]
  }
}

let mkGamercard = @(menuBtn, backCb = null) {
  size = [ saSize[0], gamercardHeight ]
  hplace = ALIGN_CENTER
  children = [
    mkLeftBlock(backCb)
    {
      size = [ SIZE_TO_CONTENT, avatarSize ]
      flow = FLOW_HORIZONTAL
      hplace = ALIGN_RIGHT
      valign = ALIGN_CENTER
      gap = gamercardGap
      children = [
        shopBtn()
        premIconWithTimeOnChange
        mkCurrencyBalance(WP, openBuyCurrencyWnd(WP))
        mkCurrencyBalance(GOLD, openBuyCurrencyWnd(GOLD))
        mkCurrencyBalance(PLATINUM, openBuyCurrencyWnd(PLATINUM))
        {
          margin = [0, 0, 0, hdpx(20)]
          children = menuBtn
        }
      ]
    }
  ]
}

let gamercardBalanceNotButtons = @() {
  watch = itemsOrder
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = itemsOrder.value
    .map(@(id) mkItemsBalance(id))
    .append(
      mkCurrencyBalance(WP)
      mkCurrencyBalance(GOLD)
    )
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
        shopBtn()
        premIconWithTimeOnChange
        mkCurrencyBalance(WP, @() openShopWnd(SC_WP))
        mkCurrencyBalance(GOLD, @() openShopWnd(SC_GOLD))
      ]
    }
}

let mkGamercardUnitCampaign = @(backCb, keyHintText, unit = hangarUnit) {
  size = [ saSize[0], gamercardHeight ]
  hplace = ALIGN_CENTER
  children = [
    mkLeftBlockUnitCampaign(backCb, keyHintText, unit)
    gamercardWithoutLevelBlock
  ]
}

let mkCurrenciesBtns = @(currencies, ovr = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = !currencies ? null
    : [].extend(currencies)
        .sort(@(a, b) (orderByCurrency?[b] ?? 0) <=> (orderByCurrency?[a] ?? 0))
        .map(@(c) mkCurrencyBalance(c, openBuyCurrencyWnd(c)))
}.__update(ovr)

let gamercardBalanceBtns = mkCurrenciesBtns([WP, GOLD])

return {
  levelBlock
  mkLeftBlock
  mkLeftBlockUnitCampaign
  gamercardWithoutLevelBlock
  mkGamercard
  mkGamercardUnitCampaign
  gamercardHeight
  gamercardBalanceNotButtons
  gamercardBalanceBtns
  mkCurrenciesBtns
}
