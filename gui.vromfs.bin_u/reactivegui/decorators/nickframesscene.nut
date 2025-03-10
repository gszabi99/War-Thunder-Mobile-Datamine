from "%globalsDarg/darg_library.nut" import *
let { arrayByRows } = require("%sqstd/underscore.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { myUserName } = require("%appGlobals/profileStates.nut")
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
let CS_DECORATORS = CS_SMALL.__merge({
  iconSize = hdpxi(30)
  fontStyle = fontTiny
})

let maxDecInRow = 9
let columns = min((contentWidthFull / (gap + squareSize[0])).tointeger(), maxDecInRow)

let selectedDecorator = Watched(chosenNickFrame.value?.name)

chosenNickFrame.subscribe(function(v){
  if (v && v.name)
    markDecoratorSeen(v.name)
})

let buySelectedDecorator = @()
  purchaseDecorator(selectedDecorator.value, frameNick("", selectedDecorator.value),
    mkBqPurchaseInfo(PURCH_SRC_PROFILE, PURCH_TYPE_DECORATOR, selectedDecorator.value))

function applySelectedDecorator() {
  if (selectedDecorator.value == "") {
    unset_current_decorator("nickFrame")
    return
  }
  if (selectedDecorator.value in availNickFrames.value) {
    set_current_decorator(selectedDecorator.value)
    return
  }
  if ((allFrames.value?[selectedDecorator.value]?.price.price ?? 0) > 0) {
    buySelectedDecorator()
    return
  }
}

let header = {
  flow = FLOW_VERTICAL
  children = [
    @() {
      watch = [myUserName, selectedDecorator]
      valign = ALIGN_CENTER
      rendObj = ROBJ_TEXT
      text = frameNick(myUserName.value, selectedDecorator.value)
    }.__update(fontMedium)
    {
      rendObj = ROBJ_TEXT
      text = loc("decorators/chooseDecoratorName")
      padding = [hdpx(40), 0,0,0]
    }.__update(fontMedium)
  ]
}

function tagBtn(item) {
  let name = item[0]
  let price = item[1].price
  let stateFlags = Watched(0)
  let isChoosen = Computed(@() chosenNickFrame.value?.name == name ||
    (chosenNickFrame.value == null && name == ""))
  let isSelected = Computed(@() selectedDecorator.value == name)
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
        selectedDecorator(name)
      else if (isSelected.value && !isChoosen.value
          && decoratorInProgress.value != (name ?? "nickFrame"))
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
              size =[hdpx(25),hdpx(32)]
              margin = [hdpx(10),hdpx(15)]
              rendObj = ROBJ_IMAGE
              color = stateFlags.value & S_HOVER ? hoverColor : 0xFFAA1111
              image =  Picture($"ui/gameuiskin#lock_icon.svg:{hdpxi(25)}:{hdpxi(32)}:P")
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
            children = mkCurrencyComp(price.price, price.currencyId, CS_DECORATORS)
          }
    ]
  }
}

function footer() {
  let { price = null } = allFrames.value?[selectedDecorator.value]
  let canBuy = (price?.price ?? 0) > 0
  let canEquip = selectedDecorator.value in availNickFrames.value || selectedDecorator.value == ""
  let isCurrent = selectedDecorator.value == chosenNickFrame.value?.name

  return {
    watch = [selectedDecorator, chosenNickFrame, allFrames, availNickFrames]
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
              mkCurrencyComp(price.price, price.currencyId),
              buySelectedDecorator)
        : null
      canEquip || canBuy || isCurrent ? null : mkDecoratorUnlockProgress(selectedDecorator.get())
    ]
  }
}

let framesList = @() {
  watch = [availNickFrames, allFrames, isShowAllDecorators]
  padding = [hdpx(30), 0, hdpx(30), 0]
  flow = FLOW_VERTICAL
  gap
  children = arrayByRows(
    allFrames.value.filter(@(frame, key) isShowAllDecorators.value || !frame.isHidden || (key in (availNickFrames.value)))
      .topairs()
      .sort(@(a,b) (b[0] in availNickFrames.value)<=>(a[0] in availNickFrames.value))
      .insert(0, [ "",
        {
          price = {
            price = 0
            currencyId = ""
          }
        }
      ])
      .map(@(item) tagBtn(item)),
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
  onDetach = @() markDecoratorsSeen(unseenDecorators.value.filter(@(_, id) id in availNickFrames.value).keys())
  children = [
    header
    makeVertScroll(framesList)
    footer
  ]
  animations = wndSwitchAnim
}

return decorationNameWnd
