from "%globalsDarg/darg_library.nut" import *
let { openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let { havePremium } = require("%rGui/state/profilePremium.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { WP, GOLD, WARBOND, EVENT_KEY } = require("%appGlobals/currenciesState.nut")
let { SC_GOLD, SC_WP, SC_CONSUMABLES } = require("%rGui/shop/shopCommon.nut")
let { openShopWnd, hasUnseenGoodsByCategory, isShopOpened } = require("%rGui/shop/shopState.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { mkDropMenuBtn } = require("%rGui/components/mkDropDownMenu.nut")
let { getTopMenuButtons, topMenuButtonsGenId } = require("%rGui/mainMenu/topMenuButtonsList.nut")
let { mkLevelBg, mkProgressLevelBg, playerExpColor,
  levelProgressBarWidth, levelProgressBorderWidth, rotateCompensate
} = require("%rGui/components/levelBlockPkg.nut")
let accountOptionsScene = require("%rGui/options/accountOptionsScene.nut")
let { itemsOrder } = require("%appGlobals/itemsState.nut")
let { mkCurrencyBalance, mkItemsBalance } = require("balanceComps.nut")
let { gamercardGap } = require("%rGui/components/currencyStyles.nut")
let { textColor, premiumTextColor, hoverColor } = require("%rGui/style/stdColors.nut")
let { gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let premIconWithTimeOnChange = require("premIconWithTimeOnChange.nut")
let { openExpWnd } = require("%rGui/mainMenu/expWndState.nut")
let { mkTitle } = require("%rGui/decorators/decoratorsPkg.nut")
let { myNameWithFrame, myAvatarImage, hasUnseenDecorators } = require("%rGui/decorators/decoratorState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { openBuyWarbondsWnd, openBuyEventKeysWnd } = require("%rGui/event/buyEventCurrenciesState.nut")
let { doubleSideGradient } = require("%rGui/components/gradientDefComps.nut")
let { mkUnitLevelBlock } = require("%rGui/unit/components/unitLevelComp.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")

let avatarSize       = hdpx(96)
let profileGap       = hdpx(45)

let levelHolderSize          = hdpx(60)
let levelHolderPlace         = avatarSize - levelHolderSize / 2

let gamercardHeight  = avatarSize + levelHolderSize / 2

let levelStateFlags = Watched(0)
let profileStateFlags = Watched(0)

let openBuyCurrencyWnd = {
  [WP] = @() openShopWnd(SC_WP),
  [GOLD] = @() openShopWnd(SC_GOLD),
  [WARBOND] = openBuyWarbondsWnd,
  [EVENT_KEY] = openBuyEventKeysWnd
}

let needShopUnseenMark = Computed(@() hasUnseenGoodsByCategory.value.findindex(@(category) category == true))

let textParams = {
  rendObj = ROBJ_TEXT
  fontFxColor = Color(0, 0, 0, 255)
  fontFxFactor = 50
  fontFx = FFT_GLOW
}.__update(fontSmall)

let avatar = @() {
  watch = [myAvatarImage, hasUnseenDecorators]
  rendObj = ROBJ_IMAGE
  size = [avatarSize, avatarSize]
  image = Picture($"{myAvatarImage.value}:{avatarSize}:{avatarSize}:P")
  halign = ALIGN_RIGHT
  children = hasUnseenDecorators.value ? priorityUnseenMark : null
}

let name =  @() textParams.__merge({
  watch = [havePremium, myNameWithFrame]
  vplace = ALIGN_CENTER
  text = myNameWithFrame.value ?? ""
  color = havePremium.value ? premiumTextColor : textColor
})

let levelUpReadyAnim = { prop = AnimProp.opacity, duration = 3.0, easing = CosineFull, play = true, loop = true }

let function levelBlock(ovr = {}, needShowMexLevel = false) {
  let { exp, nextLevelExp, level, isReadyForLevelUp } = playerLevelInfo.value
  let isMaxLevel = nextLevelExp == 0 || needShowMexLevel
  let levelNextText = isReadyForLevelUp ? (level + 1).tostring() : ""
  let needLevelUpBtn = isReadyForLevelUp
  return {
    watch = playerLevelInfo
    valign = ALIGN_CENTER
    pos = [levelHolderPlace, levelHolderPlace]
    children = [
      mkProgressLevelBg({
        key = playerLevelInfo.value
        pos = [levelHolderSize * rotateCompensate, 0]
        opacity = 1.0,
        animations = isReadyForLevelUp
          ? [ levelUpReadyAnim.__merge({ from = 0.5, to = 1.0 }) ]
          : null
        children = {
          size = isMaxLevel
            ? flex()
            : [((levelProgressBarWidth - levelProgressBorderWidth * 2) * clamp(exp, 0, nextLevelExp) / nextLevelExp).tointeger(),flex()]
          rendObj = ROBJ_SOLID
          color = playerExpColor
        }
      })
      @() mkLevelBg({
        ovr = {
          size = [levelHolderSize, levelHolderSize]
          watch = levelStateFlags
          onElemState = @(sf) levelStateFlags(sf)
          behavior = isMaxLevel ? null : Behaviors.Button
          onClick = openExpWnd
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
              text = level
              pos = [0, isMaxLevel ? -hdpx(2) : 0]
              animations = isReadyForLevelUp
                ? [ levelUpReadyAnim.__merge({ from = 1.0, to = 0.0 }) ]
                : null
              transform = {
                rotate = -45
                scale = levelStateFlags.value & S_ACTIVE ? [0.8, 0.8] : [1, 1]
              }
            })
            isReadyForLevelUp
              ? textParams.__merge({
                key = playerLevelInfo.value
                text = levelNextText
                opacity = 0.0
                transform = {
                  rotate = -45
                }
                animations = [ levelUpReadyAnim.__merge({ from = 0.0, to = 1.0 }) ]
              })
              : null
          ]
        }
      })
      needLevelUpBtn
        ? {
            size = [levelHolderSize + levelProgressBarWidth + 2 * levelProgressBorderWidth, flex()]
            hplace = ALIGN_LEFT
            behavior = Behaviors.Button
            onClick = openLvlUpWndIfCan
          }
        : null
    ]
  }.__update(ovr)
}


let hoverBg = {
  vplace = ALIGN_CENTER
  size = [pw(150), ph(130)]
  color = 0x8052C4E4
  opacity =  0.5
  rendObj = ROBJ_9RECT
  image = gradCircularSmallHorCorners
  screenOffs = hdpx(100)
  texOffs = gradCircCornerOffset
}

let gamercardProfile = {
  children = [
    @() {
      watch = profileStateFlags
      size = flex()
      children = profileStateFlags.value & S_HOVER ? hoverBg : null
    }
    {
      flow = FLOW_HORIZONTAL
      size = [SIZE_TO_CONTENT, avatarSize]
      gap = profileGap
      behavior = Behaviors.Button
      onElemState = @(sf) profileStateFlags(sf)
      onClick = @() accountOptionsScene()
      sound = { click  = "meta_profile_button" }
      children = [
        avatar
        {
          flow = FLOW_VERTICAL
          vplace = ALIGN_CENTER
          children = [
            name
            mkTitle(fontTinyAccented)
          ]
        }
      ]
    }
    levelBlock
  ]
}

let function platoonOrUnitTitle(unit) {
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
            maxWidth = hdpx(600)
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

let mkLeftBlockUnitCampaign = @(backCb, keyHintText, unit = null) @() {
  watch = hangarUnit
  size = [ SIZE_TO_CONTENT, gamercardHeight ]
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_LEFT
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = [
    backCb != null ? backButton(backCb, { vplace = ALIGN_CENTER }) : null
    gamercardUnitLevelLine(unit ?? hangarUnit.value, keyHintText)
  ]
}

let dropMenuBtn = mkDropMenuBtn(getTopMenuButtons, topMenuButtonsGenId)

let function mkImageBtn(image, onClick, children = null, ovr = {}) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = [hdpxi(65), hdpxi(60)]
    onElemState = @(sf) stateFlags(sf)
    behavior = Behaviors.Button
    rendObj = ROBJ_IMAGE
    onClick
    color = stateFlags.value & S_HOVER ? hoverColor : 0xFFFFFFFF
    image = Picture($"{image}:{hdpxi(65)}:{hdpxi(60)}:P")
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    children
  }.__update(ovr)
}

let shopBtn = mkImageBtn("ui/gameuiskin#icon_shop.svg", openBuyCurrencyWnd[GOLD],
  @() {
    watch = needShopUnseenMark
    pos = [hdpx(5), -hdpx(5)]
    hplace = ALIGN_RIGHT
    children = needShopUnseenMark.value ? priorityUnseenMark : null
  },
  { sound = { click  = "meta_shop_buttons" } } )

let rightBlock = @(){
  watch = isShopOpened
  size = [ SIZE_TO_CONTENT, avatarSize ]
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = [
    !isShopOpened.value ? shopBtn : null
    premIconWithTimeOnChange
    mkCurrencyBalance(WP, openBuyCurrencyWnd[WP])
    mkCurrencyBalance(GOLD, openBuyCurrencyWnd[GOLD])
    dropMenuBtn
  ]
}

let mkGamercard = @(backCb = null) {
  size = [ saSize[0], gamercardHeight ]
  hplace = ALIGN_CENTER
  children = [
    mkLeftBlock(backCb)
    rightBlock
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
    @(){
      watch = isShopOpened
      size = [ SIZE_TO_CONTENT, avatarSize ]
      flow = FLOW_HORIZONTAL
      hplace = ALIGN_RIGHT
      valign = ALIGN_CENTER
      gap = gamercardGap
      children = [
        !isShopOpened.value ? shopBtn : null
        premIconWithTimeOnChange
        mkCurrencyBalance(WP, @() openShopWnd(SC_WP))
        mkCurrencyBalance(GOLD, @() openShopWnd(SC_GOLD))
      ]
    }
}

let mkGamercardUnitCampaign = @(backCb, keyHintText){
  size = [ saSize[0], gamercardHeight ]
  hplace = ALIGN_CENTER
  children = [
    mkLeftBlockUnitCampaign(backCb, keyHintText)
    gamercardWithoutLevelBlock
  ]
}

let gamercardItemsBalanceBtns = @(){
  watch = itemsOrder
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = itemsOrder.value.map(@(id) mkItemsBalance(id, @() openShopWnd(SC_CONSUMABLES)))
}

let mkCurrenciesBtns = @(currencies, ovr = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = currencies.map(@(c) mkCurrencyBalance(c, openBuyCurrencyWnd[c]))
}.__update(ovr)

let gamercardBalanceBtns = mkCurrenciesBtns([WP, GOLD])

return {
  levelBlock
  mkLeftBlock
  mkLeftBlockUnitCampaign
  gamercardWithoutLevelBlock
  mkGamercard
  mkGamercardUnitCampaign
  gamercardItemsBalanceBtns
  gamercardHeight
  gamercardBalanceNotButtons
  gamercardBalanceBtns
  mkCurrenciesBtns
}
