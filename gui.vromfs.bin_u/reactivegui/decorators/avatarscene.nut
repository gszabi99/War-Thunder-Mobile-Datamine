from "%globalsDarg/darg_library.nut" import *
let { arrayByRows } = require("%sqstd/underscore.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { chosenAvatar, allAvatars, availAvatars, unseenDecorators,
  markDecoratorSeen, markDecoratorsSeen, isShowAllDecorators
} = require("decoratorState.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { set_current_decorator, unset_current_decorator, decoratorInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")
let { textButtonPrimary, textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { contentWidthFull } = require("%rGui/options/optionsStyle.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { choosenMark } = require("decoratorsPkg.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { CS_COMMON, CS_INCREASED_ICON } = require("%rGui/components/currencyStyles.nut")
let purchaseDecorator = require("purchaseDecorator.nut")
let { PURCH_SRC_PROFILE, PURCH_TYPE_DECORATOR, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkDecoratorUnlockProgress } = require("mkDecoratorUnlockProgress.nut")

let gap = hdpx(15)
let avatarSize = hdpxi(200)

let maxDecInRow = 9
let columns = min((contentWidthFull / (gap + avatarSize)).tointeger(), maxDecInRow)
let selectedAvatar = Watched(chosenAvatar.value?.name)

let buySelectedAvatar = @()
  purchaseDecorator(selectedAvatar.value, loc("decorator/avatar"),
    mkBqPurchaseInfo(PURCH_SRC_PROFILE, PURCH_TYPE_DECORATOR, selectedAvatar.value))

function applySelectedAvatar() {
  if (selectedAvatar.value == null) {
    unset_current_decorator("avatar")
    return
  }
  if (selectedAvatar.value in availAvatars.value) {
    set_current_decorator(selectedAvatar.value)
    return
  }
  if ((allAvatars.value?[selectedAvatar.value]?.price.price ?? 0) > 0) {
    buySelectedAvatar()
    return
  }
}

let header = {
  rendObj = ROBJ_TEXT
  text = loc("decorator/avatar/header")
}.__update(fontMedium)

function avatarBtn(item) {
  let name = item[0]
  let price = item?[1].price ?? {
    price = 0
    currencyId = ""
  }
  let stateFlags = Watched(0)
  let isChoosen = Computed(@() chosenAvatar.value?.name == name)
  let isSelected = Computed(@() selectedAvatar.value == name)
  let isAvailable = Computed(@() name in availAvatars.value || name == null)
  let isUnseen = Computed(@() name in unseenDecorators.value)
  return {
    rendObj = ROBJ_SOLID
    color = 0xAA000000
    behavior = Behaviors.Button
    sound = { click  = "meta_profile_elements" }
    onElemState = @(sf) stateFlags(sf)
    size = [avatarSize, avatarSize]
    function onClick() {
      markDecoratorSeen(name)
      if (!isSelected.value)
        selectedAvatar(name)
      else if (isSelected.value && !isChoosen.value
          && decoratorInProgress.value != (name ?? "avatar"))
        applySelectedAvatar()
    }
    onHover = name == null ? null : hoverHoldAction("markDecoratorsSeen", name, markDecoratorSeen)
    transform = {
      scale = stateFlags.value & S_ACTIVE ? [0.95, 0.95] : [1, 1]
    }
    children = [
      @() {
        watch = isAvailable
        rendObj = ROBJ_IMAGE
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        color = isAvailable.value ? 0xFFFFFFFF
          : 0xFF707070
        size = [avatarSize, avatarSize]
        image = Picture($"{getAvatarImage(name)}:{avatarSize}:{avatarSize}:P")
      }.__update(fontBig)
      @() {
        watch = [isChoosen, isSelected, isAvailable, stateFlags, isUnseen]
        size = flex()
        rendObj = ROBJ_BOX
        borderWidth = hdpx(2)
        borderColor = stateFlags.value & S_HOVER ? hoverColor
          : (stateFlags.value & S_ACTIVE) || isSelected.value ? 0xFFFFFFFF
          : 0xFF4F4F4F
        children = !isAvailable.value
          ? {
              size =[hdpx(25),hdpx(32)]
              margin = [hdpx(10),hdpx(15)]
              rendObj = ROBJ_IMAGE
              color = 0xFFAA1111
              image = Picture($"ui/gameuiskin#lock_icon.svg:{hdpxi(25)}:{hdpxi(32)}:P")
            }
          : isChoosen.value || isSelected.value
            ? mkSpinnerHideBlock(Computed(@() decoratorInProgress.value != null),
              isChoosen.value ? choosenMark : null)
          : isUnseen.value
            ? {
                margin = [hdpx(15), hdpx(20)]
                children = priorityUnseenMark
              }
          : null
      }
      price.price <= 0 || isAvailable.value ? null
        : {
            margin = hdpx(5)
            hplace = ALIGN_LEFT
            vplace = ALIGN_BOTTOM
            children = mkCurrencyComp(price.price, price.currencyId, CS_COMMON)
          }
    ]
  }
}

function footer() {
  let { price = null } = allAvatars.value?[selectedAvatar.value]
  let canBuy = (price?.price ?? 0) > 0
  let canEquip = selectedAvatar.value in availAvatars.value || selectedAvatar.value == null
  let isCurrent = selectedAvatar.value == chosenAvatar.value?.name
  return {
    watch = [selectedAvatar, chosenAvatar, availAvatars, allAvatars]
    size = [flex(), defButtonHeight]
    flow = FLOW_HORIZONTAL
    gap = hdpx(50)
    children = isCurrent ? null
      : canEquip
        ? textButtonPrimary(loc("mainmenu/btnEquip"), applySelectedAvatar,
          { hotkeys = ["^J:X | Enter"] })
      : canBuy
        ? textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")),
            mkCurrencyComp(price.price, price.currencyId, CS_INCREASED_ICON),
            buySelectedAvatar)
      : mkDecoratorUnlockProgress(selectedAvatar.get())
  }
}


let avatarsList = @() {
  watch = [availAvatars, allAvatars, isShowAllDecorators]
  padding = [hdpx(30), 0, hdpx(30), 0]
  flow = FLOW_VERTICAL
  gap
  children = arrayByRows(
    allAvatars.value.filter(@(frame, key) isShowAllDecorators.value || !frame.isHidden || (key in (availAvatars.value)))
      .topairs()
      .sort(@(a,b) (b[0] in availAvatars.value)<=>(a[0] in availAvatars.value))
      .insert(0, [null])
      .map(@(item) avatarBtn(item)),
    columns
  ).map(@(item) {
    flow = FLOW_HORIZONTAL
    gap
    children = item
  })
}

let decorationNameWnd = {
  key = {}
  size = flex()
  flow = FLOW_VERTICAL
  gap
  onDetach = @() markDecoratorsSeen(unseenDecorators.value.filter(@(_, id) id in availAvatars.value).keys())
  children = [
    header
    makeVertScroll(avatarsList)
    footer
  ]
  animations = wndSwitchAnim
}

return decorationNameWnd
