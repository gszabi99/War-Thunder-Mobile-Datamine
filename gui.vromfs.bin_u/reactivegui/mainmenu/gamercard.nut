from "%globalsDarg/darg_library.nut" import *
let { openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let { myAvatar } = require("%appGlobals/profileStates.nut")
let { havePremium } = require("%rGui/state/profilePremium.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { SC_GOLD, SC_WP } = require("%rGui/shop/shopCommon.nut")
let { openShopWnd, hasUnseenGoodsByCategory, isShopOpened } = require("%rGui/shop/shopState.nut")
let { openContacts } = require("%rGui/contacts/contactsState.nut")
let { requestsToMeUids } = require("%rGui/contacts/contactLists.nut")
let backButton = require("%rGui/components/backButton.nut")
let { mkDropMenuBtn } = require("%rGui/components/mkDropDownMenu.nut")
let { getTopMenuButtons, topMenuButtonsGenId } = require("%rGui/mainMenu/topMenuButtonsList.nut")
let { mkLevelBg, mkProgressLevelBg, maxLevelStarChar, playerExpColor,
  levelProgressBarWidth, levelProgressBorderWidth
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
let { myNameWithFrame } = require("%rGui/decorators/decoratorState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")

let avatarSize       = hdpx(96)
let profileGap       = hdpx(45)

let levelHolderSize          = hdpx(60)
let levelHolderPlace         = avatarSize - levelHolderSize / 2

let gamercardHeight  = avatarSize + levelHolderSize / 2

let needShopUnseenMark = Computed(@() hasUnseenGoodsByCategory.value.findindex(@(category) category == true))

let textParams = {
  rendObj = ROBJ_TEXT
  fontFxColor = Color(0, 0, 0, 255)
  fontFxFactor = 50
  fontFx = FFT_GLOW
}.__update(fontSmall)

let avatar = @() {
  watch = myAvatar
  rendObj = ROBJ_IMAGE
  size = [avatarSize, avatarSize]
  image = Picture($"!ui/images/avatars/{myAvatar.value}.avif")
}

let name =  @() textParams.__merge({
  watch = [havePremium, myNameWithFrame]
  vplace = ALIGN_CENTER
  text = myNameWithFrame.value ?? ""
  color = havePremium.value ? premiumTextColor : textColor
})

let levelUpReadyAnim = { prop = AnimProp.opacity, duration = 3.0, easing = CosineFull, play = true, loop = true }

let mkLevelBlock = @(canOpenLevelUp) function() {
  let stateFlags = Watched(0)
  let { exp, nextLevelExp, level, isReadyForLevelUp } = playerLevelInfo.value
  let isMaxLevel = nextLevelExp == 0
  let levelNextText = isReadyForLevelUp ? (level + 1).tostring() : ""
  let needLevelUpBtn = canOpenLevelUp && isReadyForLevelUp
  return {
    watch = playerLevelInfo
    size = [levelHolderSize, levelHolderSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    pos = [levelHolderPlace, levelHolderPlace]
    children = [
        !isMaxLevel
        ? mkProgressLevelBg({
            key = playerLevelInfo.value
            pos = [levelHolderPlace - levelProgressBorderWidth, 0]
            opacity = 1.0,
            animations = isReadyForLevelUp
              ? [ levelUpReadyAnim.__merge({ from = 0.5, to = 1.0 }) ]
              : null
            children = {
              size = [((levelProgressBarWidth - levelProgressBorderWidth) * clamp(exp, 0, nextLevelExp) / nextLevelExp).tointeger(),
                flex()]
              rendObj = ROBJ_SOLID
              color = playerExpColor
            }
          })
        : null
      @() mkLevelBg({
        ovr = {
          watch = stateFlags
          onElemState = @(sf) stateFlags(sf)
          behavior = isMaxLevel ? null : Behaviors.Button
          onClick = openExpWnd
          color = stateFlags.value & S_HOVER ? 0xDD52C4E4 : 0xFF000000
          transform = {
            rotate = 45
            scale = stateFlags.value & S_ACTIVE ? [0.8, 0.8] : [1, 1]
          }
        }
      })
      @() textParams.__merge({
        watch = stateFlags
        key = playerLevelInfo.value
        text = isMaxLevel ? maxLevelStarChar : level
        pos = [0, isMaxLevel ? -hdpx(2) : 0]
        animations = isReadyForLevelUp
          ? [ levelUpReadyAnim.__merge({ from = 1.0, to = 0.0 }) ]
          : null
        transform = {
          scale = stateFlags.value & S_ACTIVE ? [0.8, 0.8] : [1, 1]
        }
      })
      isReadyForLevelUp
        ? textParams.__merge({
            key = playerLevelInfo.value
            text = levelNextText
            opacity = 0.0
            animations = [ levelUpReadyAnim.__merge({ from = 0.0, to = 1.0 }) ]
          })
        : null
      needLevelUpBtn
        ? {
            size = [levelHolderSize + levelProgressBarWidth + 2 * levelProgressBorderWidth, flex()]
            hplace = ALIGN_LEFT
            behavior = Behaviors.Button
            onClick = openLvlUpWndIfCan
          }
        : null
    ]
  }
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

let function mkProfileHolder(canOpenLevelUp) {
  let stateFlags = Watched(0)
  return {
    children = [
      @() {
        watch = stateFlags
        size = flex()
        children = stateFlags.value & S_HOVER ? hoverBg : null
      }
      {
        flow = FLOW_HORIZONTAL
        size = [SIZE_TO_CONTENT, avatarSize]
        gap = profileGap
        behavior = Behaviors.Button
        onElemState = @(sf) stateFlags(sf)
        onClick = @() accountOptionsScene()
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
      mkLevelBlock(canOpenLevelUp)
    ]
  }
}

let mkLeftBlock = @(backCb, canOpenLevelUp) {
  size = [ SIZE_TO_CONTENT, gamercardHeight ]
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_LEFT
  gap = gamercardGap
  children = [
    backCb != null ? backButton(backCb, { vplace = ALIGN_CENTER }) : null
    mkProfileHolder(canOpenLevelUp)
  ]
}

let dropMenuBtn = mkDropMenuBtn(getTopMenuButtons, topMenuButtonsGenId)

let function mkImageBtn(image, onClick, children = null) {
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
  }
}

let shopBtn = mkImageBtn("ui/gameuiskin#icon_shop.svg", @() openShopWnd(SC_GOLD),
  @() {
    watch = needShopUnseenMark
    pos = [hdpx(5), -hdpx(5)]
    hplace = ALIGN_RIGHT
    children = needShopUnseenMark.value ? priorityUnseenMark : null
  })

let contactsBtn = mkImageBtn("ui/gameuiskin#icon_contacts.svg", openContacts,
  @() {
    watch = requestsToMeUids
    pos = [hdpx(5), -hdpx(5)]
    hplace = ALIGN_RIGHT
    children = requestsToMeUids.value.len() > 0 ? priorityUnseenMark : null
  })

let rightBlock = @(){
  watch = isShopOpened
  size = [ SIZE_TO_CONTENT, avatarSize ]
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = [premIconWithTimeOnChange]
    .append(
      mkCurrencyBalance(WP, @() openShopWnd(SC_WP))
      mkCurrencyBalance(GOLD, @() openShopWnd(SC_GOLD))
      contactsBtn
      !isShopOpened.value ? shopBtn : null
      dropMenuBtn
    )
}

let mkGamercard = @(backCb = null, canOpenLevelUp = false) {
  size = [ saSize[0], gamercardHeight ]
  hplace = ALIGN_CENTER
  children = [
    mkLeftBlock(backCb, canOpenLevelUp)
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

let gamercardBalanceBtns = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = [
    mkCurrencyBalance(WP, @() openShopWnd(SC_WP))
    mkCurrencyBalance(GOLD, @() openShopWnd(SC_GOLD))
  ]
}

return {
  mkGamercard
  gamercardHeight
  gamercardBalanceNotButtons
  gamercardBalanceBtns
}
