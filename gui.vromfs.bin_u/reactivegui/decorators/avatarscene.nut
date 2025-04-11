from "%globalsDarg/darg_library.nut" import *
let { arrayByRows } = require("%sqstd/underscore.nut")
let { currencyToFullId } = require("%appGlobals/pServer/seasonCurrencies.nut")
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
let listPaddingVert = hdpx(30)

let maxDecInRow = 9
let columns = min((contentWidthFull / (gap + avatarSize)).tointeger(), maxDecInRow)

let chosenAvatarName = Computed(@() chosenAvatar.get()?.name ?? "")
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
        selectedAvatarName.set(name)
      else if (isSelected.value && !isChoosen.value
          && decoratorInProgress.get() != (name != "" ? name : "avatar"))
        applySelectedAvatar()
    }
    onHover = name == "" ? null : hoverHoldAction("markDecoratorsSeen", name, markDecoratorSeen)
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
  let { price = null } = allAvatars.get()?[selectedAvatarName.get()]
  let currencyFullId = currencyToFullId.get()?[price?.currencyId] ?? price?.currencyId
  let canBuy = (price?.price ?? 0) > 0
  let canEquip = selectedAvatarName.get() in availAvatars.get() || selectedAvatarName.get() == ""
  let isCurrent = selectedAvatarName.get() == chosenAvatarName.get()
  return {
    watch = [selectedAvatarName, chosenAvatarName, availAvatars, allAvatars, currencyToFullId]
    size = [flex(), defButtonHeight]
    flow = FLOW_HORIZONTAL
    gap = hdpx(50)
    children = isCurrent ? null
      : canEquip
        ? textButtonPrimary(loc("mainmenu/btnEquip"), applySelectedAvatar,
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
  let showRowsAbove = 1.5
  let onAttach = @()
    scrollHandler.scrollToY(listPaddingVert + ((avatarSize + gap) * (chosenRow - showRowsAbove)))

  return {
    key = listKey
    watch = [availAvatars, allAvatars, isShowAllDecorators]
    padding = [listPaddingVert, 0]
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
  size = flex()
  flow = FLOW_VERTICAL
  gap
  onAttach = @() selectedAvatarName.set(chosenAvatarName.get())
  onDetach = @() markDecoratorsSeen(unseenDecorators.value.filter(@(_, id) id in availAvatars.value).keys())
  children = [
    header
    makeVertScroll(avatarsList, { scrollHandler })
    footer
  ]
  animations = wndSwitchAnim
}

return decorationNameWnd
