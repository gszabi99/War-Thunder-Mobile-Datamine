from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/underscore.nut" import arrayByRows
import "%darg/helpers/hoverHoldAction.nut" as hoverHoldAction
from "%appGlobals/decorators/nickFrames.nut" import frameNick
from "%appGlobals/pServer/pServerApi.nut" import set_current_decorator, unset_current_decorator, decoratorInProgress
from "%appGlobals/pServer/seasonCurrencies.nut" import currencyToFullId
from "%appGlobals/profileStates.nut" import myUserName
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/currencyComp.nut" import mkCurrencyComp
from "%rGui/components/currencyStyles.nut" import CS_SMALL
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonPrimary, textButtonPricePurchase
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/decorators/decoratorState.nut" import chosenNickFrame, allFrames, availNickFrames, unseenDecorators,
  markDecoratorSeen, markDecoratorsSeen, isShowAllDecorators
from "%rGui/decorators/decoratorsPkg.nut" import choosenMark
from "%rGui/decorators/mkDecoratorUnlockProgress.nut" import mkDecoratorUnlockProgress
import "%rGui/decorators/purchaseDecorator.nut" as purchaseDecorator
from "%rGui/options/optionsStyle.nut" import contentWidthFull
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_PROFILE, PURCH_TYPE_DECORATOR, mkBqPurchaseInfo
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import hoverColor


const gap = hdpx(15)
let squareSize = [hdpx(163), hdpx(151)]
const listPaddingVert = hdpx(30)
let CS_DECORATORS = CS_SMALL.__merge({
  iconSize = hdpxi(30)
  fontStyle = fontTiny
})

const maxDecInRow = 9
let columns = min((contentWidthFull / (gap + squareSize[0])).tointeger(), maxDecInRow)

let chosenFrameName = Computed(@() chosenNickFrame.get()?.name ?? "")
let isDecoratorInProgress = Computed(@() decoratorInProgress.get() != null)
let selectedFrameName = Watched(chosenFrameName.get())

chosenFrameName.subscribe(@(v) markDecoratorSeen(v))

let buySelectedDecorator = @()
  purchaseDecorator(selectedFrameName.get(), frameNick("", selectedFrameName.get()),
    mkBqPurchaseInfo(PURCH_SRC_PROFILE, PURCH_TYPE_DECORATOR, selectedFrameName.get()))

function applySelectedDecorator() {
  let selFrame = selectedFrameName.get()
  if (selFrame == "")
    unset_current_decorator("nickFrame")
  else if (selFrame in availNickFrames.get())
    set_current_decorator(selFrame)
  else if ((allFrames.get()?[selFrame]?.price.price ?? 0) > 0)
    buySelectedDecorator()
}

let header = {
  flow = FLOW_VERTICAL
  children = [
    @() {
      watch = [myUserName, selectedFrameName]
      valign = ALIGN_CENTER
      rendObj = ROBJ_TEXT
      text = frameNick(myUserName.get(), selectedFrameName.get())
    }.__update(fontMedium)
    {
      rendObj = ROBJ_TEXT
      text = loc("decorators/chooseDecoratorName")
      padding = const [hdpx(40), 0,0,0]
    }.__update(fontMedium)
  ]
}

function tagBtn(item) {
  let { name, price } = item
  let stateFlags = Watched(0)
  let isChoosen = Computed(@() chosenFrameName.get() == name)
  let isSelected = Computed(@() selectedFrameName.get() == name)
  let isAvailable = Computed(@() name in availNickFrames.get() || name == "")
  let isUnseen = Computed(@() name in unseenDecorators.get())
  return @() {
    watch = stateFlags
    rendObj = ROBJ_SOLID
    color = 0xAA000000
    xmbNode = {}
    behavior = Behaviors.Button
    sound = { click  = "meta_profile_elements" }
    onElemState = @(sf) stateFlags.set(sf)
    size = squareSize
    function onClick() {
      markDecoratorSeen(name)
      if (!isSelected.get())
        selectedFrameName.set(name)
      else if (isSelected.get() && !isChoosen.get()
          && decoratorInProgress.get() != (name != "" ? name : "nickFrame"))
        applySelectedDecorator()
    }
    onHover = hoverHoldAction("markDecoratorsSeen", name, markDecoratorSeen)
    transform = {
      scale = stateFlags.get() & S_ACTIVE ? [0.95, 0.95] : [1, 1]
    }
    children = [
      @() {
        watch = isAvailable
        rendObj = ROBJ_TEXT
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        color = stateFlags.get() & S_HOVER ? hoverColor
          : isAvailable.get() ? 0xFFFFFFFF
          : 0xFF707070
        size = FLEX
        text = frameNick("", name)
      }.__update(fontBig)
      @() {
        watch = [isChoosen, isSelected, isAvailable, isUnseen]
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
              color = stateFlags.get() & S_HOVER ? hoverColor : 0xFFAA1111
              image =  Picture($"ui/gameuiskin#lock_icon.svg:{hdpxi(25)}:{hdpxi(32)}:P")
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
            children = mkCurrencyComp(price.price, price.currencyId, CS_DECORATORS)
          }
    ]
  }
}

function footer() {
  let { price = null } = allFrames.get()?[selectedFrameName.get()]
  let currencyFullId = currencyToFullId.get()?[price?.currencyId] ?? price?.currencyId
  let canBuy = (price?.price ?? 0) > 0
  let canEquip = selectedFrameName.get() in availNickFrames.get() || selectedFrameName.get() == ""
  let isCurrent = selectedFrameName.get() == chosenFrameName.get()

  return {
    watch = [selectedFrameName, chosenFrameName, allFrames, availNickFrames, currencyToFullId]
    size = [FLEX, defButtonHeight]
    vplace = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    gap
    children = [
      isCurrent ? null
        : canEquip
          ? textButtonPrimary(utf8ToUpper(loc("mainmenu/btnEquip")), applySelectedDecorator,
            { hotkeys = ["^J:X | Enter"] })
        : canBuy
          ? textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")),
              mkCurrencyComp(price.price, currencyFullId),
              buySelectedDecorator)
        : null
      canEquip || canBuy || isCurrent ? null : mkDecoratorUnlockProgress(selectedFrameName.get())
    ]
  }
}

let scrollHandler = ScrollHandler()
let listKey = {}

function framesList() {
  let nickFrames = allFrames.get()
    .filter(@(v, name) isShowAllDecorators.get() || !v.isHidden || (name in availNickFrames.get()))
    .map(@(v, name) v.__merge({ name }))
    .values()
    .sort(@(a, b) (b.name in availNickFrames.get()) <=> (a.name in availNickFrames.get()))
    .insert(0, {
        name = ""
        price = { price = 0, currencyId = "" }
      })

  let chosenRow = (nickFrames.findindex(@(v) v.name == chosenFrameName.get()) ?? 0) / columns
  const showRowsAbove = 1.5
  let onAttach = @()
    scrollHandler.scrollToY(listPaddingVert + ((squareSize[1] + gap) * (chosenRow - showRowsAbove)))

  return {
    key = listKey
    watch = [availNickFrames, allFrames, isShowAllDecorators]
    padding = const [listPaddingVert, 0]
    flow = FLOW_VERTICAL
    gap
    onAttach
    children = arrayByRows(
      nickFrames.map(tagBtn),
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
  onAttach = @() selectedFrameName.set(chosenFrameName.get())
  onDetach = @() markDecoratorsSeen(unseenDecorators.get().filter(@(_, id) id in availNickFrames.get()).keys())
  children = [
    header
    makeVertScroll(framesList, { scrollHandler, xmbNode = XmbContainer({ scrollToEdge = true }) })
    footer
  ]
  animations = wndSwitchAnim
}

return decorationNameWnd
