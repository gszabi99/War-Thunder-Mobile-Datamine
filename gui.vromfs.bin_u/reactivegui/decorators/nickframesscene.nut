from "%globalsDarg/darg_library.nut" import *
let { arrayByRows } = require("%sqstd/underscore.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { myUserName } = require("%appGlobals/profileStates.nut")
let { currencyToFullId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { chosenNickFrame, allFrames, availNickFrames,
  unseenDecorators, markDecoratorSeen, markDecoratorsSeen, isShowAllDecorators
} = require("decoratorState.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { set_current_decorator, unset_current_decorator, decoratorInProgress
} = require("%appGlobals/pServer/pServerApi.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")
let { textButtonPrimary, textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { contentWidthFull } = require("%rGui/options/optionsStyle.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { CS_SMALL } = require("%rGui/components/currencyStyles.nut")
let purchaseDecorator = require("purchaseDecorator.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { PURCH_SRC_PROFILE, PURCH_TYPE_DECORATOR, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { choosenMark } = require("decoratorsPkg.nut")
let { mkDecoratorUnlockProgress } = require("mkDecoratorUnlockProgress.nut")


let gap = hdpx(15)
let squareSize = [hdpx(163), hdpx(151)]
let listPaddingVert = hdpx(30)
let CS_DECORATORS = CS_SMALL.__merge({
  iconSize = hdpxi(30)
  fontStyle = fontTiny
})

let maxDecInRow = 9
let columns = min((contentWidthFull / (gap + squareSize[0])).tointeger(), maxDecInRow)

let chosenFrameName = Computed(@() chosenNickFrame.get()?.name ?? "")
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
  let isAvailable = Computed(@() name in availNickFrames.value || name == "")
  let isUnseen = Computed(@() name in unseenDecorators.value)
  return @() {
    watch = stateFlags
    rendObj = ROBJ_SOLID
    color = 0xAA000000
    behavior = Behaviors.Button
    sound = { click  = "meta_profile_elements" }
    onElemState = @(sf) stateFlags(sf)
    size = squareSize
    function onClick() {
      markDecoratorSeen(name)
      if (!isSelected.value)
        selectedFrameName.set(name)
      else if (isSelected.value && !isChoosen.value
          && decoratorInProgress.get() != (name != "" ? name : "nickFrame"))
        applySelectedDecorator()
    }
    onHover = hoverHoldAction("markDecoratorsSeen", name, markDecoratorSeen)
    transform = {
      scale = stateFlags.value & S_ACTIVE ? [0.95, 0.95] : [1, 1]
    }
    children = [
      @() {
        watch = isAvailable
        rendObj = ROBJ_TEXT
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        color = stateFlags.value & S_HOVER ? hoverColor
          : isAvailable.value ? 0xFFFFFFFF
          : 0xFF707070
        size = flex()
        text = frameNick("", name)
      }.__update(fontBig)
      @() {
        watch = [isChoosen, isSelected, isAvailable, isUnseen]
        size = flex()
        rendObj = ROBJ_BOX
        borderWidth = hdpx(2)
        borderColor = stateFlags.value & S_HOVER ? hoverColor
          : (stateFlags.value & S_ACTIVE) || isSelected.value ? 0xFFFFFFFF
          : 0xFF4F4F4F
        children = !isAvailable.value
          ? {
              size =const [hdpx(25),hdpx(32)]
              margin = const [hdpx(10),hdpx(15)]
              rendObj = ROBJ_IMAGE
              color = stateFlags.value & S_HOVER ? hoverColor : 0xFFAA1111
              image =  Picture($"ui/gameuiskin#lock_icon.svg:{hdpxi(25)}:{hdpxi(32)}:P")
            }
          : isChoosen.value || isSelected.value
            ? mkSpinnerHideBlock(Computed(@() decoratorInProgress.value != null),
              isChoosen.value ? choosenMark : null)
          : isUnseen.value
            ? {
                margin = const [hdpx(15), hdpx(20)]
                children = priorityUnseenMark
              }
          : null
      }
      price.price <= 0 || isAvailable.value ? null
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
    size = [flex(), defButtonHeight]
    vplace = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    gap
    children = [
      isCurrent ? null
        : canEquip
          ? textButtonPrimary(loc("mainmenu/btnEquip"), applySelectedDecorator,
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
  let showRowsAbove = 1.5
  let onAttach = @()
    scrollHandler.scrollToY(listPaddingVert + ((squareSize[1] + gap) * (chosenRow - showRowsAbove)))

  return {
    key = listKey
    watch = [availNickFrames, allFrames, isShowAllDecorators]
    padding = [listPaddingVert, 0]
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
  size = flex()
  flow = FLOW_VERTICAL
  gap
  onAttach = @() selectedFrameName.set(chosenFrameName.get())
  onDetach = @() markDecoratorsSeen(unseenDecorators.value.filter(@(_, id) id in availNickFrames.value).keys())
  children = [
    header
    makeVertScroll(framesList, { scrollHandler })
    footer
  ]
  animations = wndSwitchAnim
}

return decorationNameWnd
