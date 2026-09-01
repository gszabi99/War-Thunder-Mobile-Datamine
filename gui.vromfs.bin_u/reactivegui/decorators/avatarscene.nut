from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/underscore.nut" import arrayByRows
import "%darg/helpers/hoverHoldAction.nut" as hoverHoldAction
import "%appGlobals/decorators/avatars.nut" as getAvatarImage
from "%appGlobals/pServer/pServerApi.nut" import set_current_decorator, unset_current_decorator, decoratorInProgress
from "%appGlobals/pServer/seasonCurrencies.nut" import currencyToFullId
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/currencyComp.nut" import mkCurrencyComp
from "%rGui/components/currencyStyles.nut" import CS_COMMON, CS_INCREASED_ICON
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonPrimary, textButtonPricePurchase
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/decorators/decoratorState.nut" import chosenAvatar, allAvatars, availAvatars, unseenDecorators,
  markDecoratorSeen, markDecoratorsSeen, isShowAllDecorators
from "%rGui/decorators/decoratorsPkg.nut" import choosenMark
from "%rGui/decorators/mkDecoratorUnlockProgress.nut" import mkDecoratorUnlockProgress
import "%rGui/decorators/purchaseDecorator.nut" as purchaseDecorator
from "%rGui/options/optionsStyle.nut" import contentWidthFull
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_PROFILE, PURCH_TYPE_DECORATOR, mkBqPurchaseInfo
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import hoverColor


const gap = hdpx(15)
const avatarSize = hdpxi(200)
const listPaddingVert = hdpx(30)

const maxDecInRow = 9
let columns = min((contentWidthFull / (gap + avatarSize)).tointeger(), maxDecInRow)

let chosenAvatarName = Computed(@() chosenAvatar.get()?.name ?? "")
let isDecoratorInProgress = Computed(@() decoratorInProgress.get() != null)
let selectedAvatarName = Watched(chosenAvatarName.get())

let buySelectedAvatar = @()
  purchaseDecorator(selectedAvatarName.get(), loc("decorator/avatar"),
    mkBqPurchaseInfo(PURCH_SRC_PROFILE, PURCH_TYPE_DECORATOR, selectedAvatarName.get()))

function applySelectedAvatar() {
  let selAvatar = selectedAvatarName.get()
  if (selAvatar == "")
    unset_current_decorator("avatar")
  else if (selAvatar in availAvatars.get())
    set_current_decorator(selAvatar)
  else if ((allAvatars.get()?[selAvatar]?.price.price ?? 0) > 0)
    buySelectedAvatar()
}

let header = {
  rendObj = ROBJ_TEXT
  text = loc("decorator/avatar/header")
}.__update(fontMedium)

function avatarBtn(item) {
  let { name, price } = item
  let stateFlags = Watched(0)
  let isChoosen = Computed(@() chosenAvatarName.get() == name)
  let isSelected = Computed(@() selectedAvatarName.get() == name)
  let isAvailable = Computed(@() name in availAvatars.get() || name == "")
  let isUnseen = Computed(@() name in unseenDecorators.get())
  return {
    rendObj = ROBJ_SOLID
    color = 0xAA000000
    xmbNode = {}
    behavior = Behaviors.Button
    sound = { click  = "meta_profile_elements" }
    onElemState = @(sf) stateFlags.set(sf)
    size = const [avatarSize, avatarSize]
    function onClick() {
      markDecoratorSeen(name)
      if (!isSelected.get())
        selectedAvatarName.set(name)
      else if (isSelected.get() && !isChoosen.get()
          && decoratorInProgress.get() != (name != "" ? name : "avatar"))
        applySelectedAvatar()
    }
    onHover = name == "" ? null : hoverHoldAction("markDecoratorsSeen", name, markDecoratorSeen)
    transform = {
      scale = stateFlags.get() & S_ACTIVE ? [0.95, 0.95] : [1, 1]
    }
    children = [
      @() {
        watch = isAvailable
        rendObj = ROBJ_IMAGE
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        color = isAvailable.get() ? 0xFFFFFFFF
          : 0xFF707070
        size = const [avatarSize, avatarSize]
        image = Picture($"{getAvatarImage(name)}:{avatarSize}:{avatarSize}:P")
      }.__update(fontBig)
      @() {
        watch = [isChoosen, isSelected, isAvailable, stateFlags, isUnseen]
        size = FLEX
        rendObj = ROBJ_BOX
        borderWidth = hdpx(2)
        borderColor = stateFlags.get() & S_HOVER ? hoverColor
          : (stateFlags.get() & S_ACTIVE) || isSelected.get() ? 0xFFFFFFFF
          : 0xFF4F4F4F
        children = !isAvailable.get()
          ? {
              size = const [hdpx(25),hdpx(32)]
              margin = const [hdpx(10),hdpx(15)]
              rendObj = ROBJ_IMAGE
              color = 0xFFAA1111
              image = Picture($"ui/gameuiskin#lock_icon.svg:{hdpxi(25)}:{hdpxi(32)}:P")
            }
          : isChoosen.get() || isSelected.get()
            ? mkSpinnerHideBlock(isDecoratorInProgress,
              isChoosen.get() ? choosenMark : null)
          : isUnseen.get()
            ? {
                margin = const [hdpx(15), hdpx(20)]
                children = priorityUnseenMark
              }
          : null
      }
      price.price <= 0 || isAvailable.get() ? null
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
  let { price = null } = allAvatars.get()?[selectedAvatarName.get()]
  let currencyFullId = currencyToFullId.get()?[price?.currencyId] ?? price?.currencyId
  let canBuy = (price?.price ?? 0) > 0
  let canEquip = selectedAvatarName.get() in availAvatars.get() || selectedAvatarName.get() == ""
  let isCurrent = selectedAvatarName.get() == chosenAvatarName.get()
  return {
    watch = [selectedAvatarName, chosenAvatarName, availAvatars, allAvatars, currencyToFullId]
    size = [FLEX, defButtonHeight]
    flow = FLOW_HORIZONTAL
    gap = hdpx(50)
    children = isCurrent ? null
      : canEquip
        ? textButtonPrimary(utf8ToUpper(loc("mainmenu/btnEquip")), applySelectedAvatar,
          { hotkeys = ["^J:X | Enter"] })
      : canBuy
        ? textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")),
            mkCurrencyComp(price.price, currencyFullId, CS_INCREASED_ICON),
            buySelectedAvatar)
      : mkDecoratorUnlockProgress(selectedAvatarName.get())
  }
}

let scrollHandler = ScrollHandler()
let listKey = {}

function avatarsList() {
  let avatars = allAvatars.get()
    .filter(@(v, name) isShowAllDecorators.get() || !v.isHidden || (name in availAvatars.get()))
    .map(@(v, name) v.__merge({ name }))
    .values()
    .sort(@(a, b) (b.name in availAvatars.get()) <=> (a.name in availAvatars.get()))
    .insert(0, {
        name = ""
        price = { price = 0, currencyId = "" }
      })

  let chosenRow = (avatars.findindex(@(v) v.name == chosenAvatarName.get()) ?? 0) / columns
  const showRowsAbove = 1.5
  let onAttach = @()
    scrollHandler.scrollToY(listPaddingVert + ((avatarSize + gap) * (chosenRow - showRowsAbove)))

  return {
    key = listKey
    watch = [availAvatars, allAvatars, isShowAllDecorators]
    padding = const [listPaddingVert, 0]
    flow = FLOW_VERTICAL
    gap
    onAttach
    children = arrayByRows(
      avatars.map(avatarBtn),
      columns
    ).map(@(item) {
      flow = FLOW_HORIZONTAL
      gap
      children = item
    })
  }
}

let decorationNameWnd = {
  key = {}
  size = FLEX
  flow = FLOW_VERTICAL
  gap
  onAttach = @() selectedAvatarName.set(chosenAvatarName.get())
  onDetach = @() markDecoratorsSeen(unseenDecorators.get().filter(@(_, id) id in availAvatars.get()).keys())
  children = [
    header
    makeVertScroll(avatarsList, { scrollHandler, xmbNode = XmbContainer({ scrollToEdge = true }) })
    footer
  ]
  animations = wndSwitchAnim
}

return decorationNameWnd
