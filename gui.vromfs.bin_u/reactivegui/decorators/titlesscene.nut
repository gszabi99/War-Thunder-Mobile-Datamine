from "%globalsDarg/darg_library.nut" import *
let { arrayByRows } = require("%sqstd/underscore.nut")
let { ceil } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { myUserName } = require("%appGlobals/profileStates.nut")
let { currencyToFullId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { chosenTitle, allTitles, chosenNickFrame, availTitles,
  unseenDecorators, markDecoratorSeen, markDecoratorsSeen, isShowAllDecorators
} = require("decoratorState.nut")
let { set_current_decorator, unset_current_decorator, decoratorInProgress
} = require("%appGlobals/pServer/pServerApi.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")
let { textButtonPrimary, textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkTitle } = require("%rGui/decorators/decoratorsPkg.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { choosenMark } = require("decoratorsPkg.nut")
let { mkDecoratorUnlockProgress } = require("mkDecoratorUnlockProgress.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let purchaseDecorator = require("purchaseDecorator.nut")
let { PURCH_SRC_PROFILE, PURCH_TYPE_DECORATOR, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")


let gap = hdpx(15)
let rowHeight = hdpx(75)
let minRows = 6
let columns = 2

let bgColor = @(rowIdx) rowIdx % 2 == 0 ? 0x00000000 : 0x80323232

let chosenTitleName = Computed(@() chosenTitle.get()?.name ?? "")
let selectedTitleName = Watched(chosenTitleName.get())
let visibleTitles = Computed(@() allTitles.get().filter(@(dec, id) !dec.isHidden || isShowAllDecorators.get() || (id in availTitles.get())))
let hasVisibleTitles = Computed(@() visibleTitles.value.len() > 0)

function applySelectedTitle() {
  let selTitle = selectedTitleName.get()
  if (selTitle == "")
    unset_current_decorator("title")
  else if (selTitle in availTitles.get())
    set_current_decorator(selTitle)
}

let header = {
  size = const [SIZE_TO_CONTENT,hdpx(100)]
  flow = FLOW_VERTICAL
  children = [
    @() {
      watch = [myUserName, chosenNickFrame]
      rendObj = ROBJ_TEXT
      text = frameNick(myUserName.value, chosenNickFrame.get()?.name)
    }.__update(fontMedium)
    mkTitle(fontSmall)
  ]
}

function titleRow(name, locName, rowIdx) {
  let stateFlags = Watched(0)
  let isChoosen = Computed(@() chosenTitleName.get() == name)
  let isSelected = Computed(@() selectedTitleName.get() == name)
  let isUnseen = Computed(@() name in unseenDecorators.get())
  return {
    rendObj = ROBJ_SOLID
    size = [flex(), rowHeight]
    color = bgColor(rowIdx)
    behavior = Behaviors.Button
    sound = { click  = "meta_profile_elements" }
    valign = ALIGN_CENTER
    onElemState = @(sf) stateFlags(sf)
    function onClick() {
      markDecoratorSeen(name)
      if (!isSelected.value)
        selectedTitleName.set(name)
      else if (isSelected.value && !isChoosen.value
          && decoratorInProgress.get() != (name != "" ? name : "title"))
        applySelectedTitle()
    }
    onHover = hoverHoldAction("markDecoratorSeen", name, markDecoratorSeen)
    children = @(){
      watch = [stateFlags, isSelected]
      flow = FLOW_HORIZONTAL
      rendObj = ROBJ_BOX
      valign = ALIGN_CENTER
      size = flex()
      borderWidth = hdpx(2)
      borderColor = stateFlags.value & S_HOVER ? hoverColor
        : (stateFlags.value & S_ACTIVE) || isSelected.value ? 0xFFFFFFFF
        : 0x00000000
      children = [
        @() {
          watch = [isChoosen, availTitles, isUnseen]
          size = hdpx(85)
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = name != "" && name not in availTitles.get()
            ? {
                size =const [hdpx(35),hdpx(45)]
                rendObj = ROBJ_IMAGE
                color = 0xFFFFB70B
                image =  Picture($"ui/gameuiskin#lock_icon.svg:{hdpxi(35)}:{hdpxi(45)}:P")
              }
            : isChoosen.value || isSelected.value
              ? mkSpinnerHideBlock(Computed(@() decoratorInProgress.value != null),
                isChoosen.value ? choosenMark(hdpxi(45), { hplace = ALIGN_CENTER }) : null)
            : isUnseen.value
              ? {
                  margin = const [hdpx(15), hdpx(20)]
                  children = priorityUnseenMark
                }
              : null
        }
        {
          rendObj = ROBJ_TEXT
          color = stateFlags.value & S_HOVER ? hoverColor : 0xFFFFFFFF
          text = locName
          transform = {
            scale = stateFlags.value & S_ACTIVE ? [0.95, 0.95] : [1, 1]
          }
        }.__update(fontMedium)
      ]
    }
  }
}

let emptyRow = @(rowIdx) {
  rendObj = ROBJ_SOLID
  size = [flex(), rowHeight]
  color = bgColor(rowIdx)
}

let buySelectedDecorator = @()
  purchaseDecorator(selectedTitleName.get(), loc($"title/{selectedTitleName.get()}"),
    mkBqPurchaseInfo(PURCH_SRC_PROFILE, PURCH_TYPE_DECORATOR, selectedTitleName.get()))

function footer() {
  let { price = null } = allTitles.get()?[selectedTitleName.get()]
  let currencyFullId = currencyToFullId.get()?[price?.currencyId] ?? price?.currencyId
  return {
    watch = [selectedTitleName, chosenTitleName, availTitles, allTitles, currencyToFullId]
    size = [flex(), defButtonHeight]
    flow = FLOW_HORIZONTAL
    gap = hdpx(50)
    children = selectedTitleName.get() == chosenTitleName.get()
        ? null
      : selectedTitleName.get() in availTitles.get() || selectedTitleName.get() == ""
        ? textButtonPrimary(loc("mainmenu/btnEquip"), applySelectedTitle,
          { hotkeys = ["^J:X | Enter"] })
      : (price?.price ?? 0) > 0
        ? textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")),
            mkCurrencyComp(price.price, currencyFullId),
            buySelectedDecorator, { hotkeys = ["^J:X | Enter"]  })
      : mkDecoratorUnlockProgress(selectedTitleName.get())
  }
}

let scrollHandler = ScrollHandler()
let listKey = {}

function titlesList() {
  local total = max(visibleTitles.value.len() + 1, columns * minRows)
  let rows = ceil(total.tofloat() / columns).tointeger()
  total = rows * columns

  let titles = visibleTitles.get()
    .keys()
    .map(@(name) { name, locName = loc($"title/{name}") })
    .sort(@(a,b) (b.name in availTitles.get()) <=> (a.name in availTitles.get())
      || a.locName <=> b.locName)
    .insert(0, { name = "", locName = loc("title/empty") })
  let titleComps = titles.map(@(v, idx) titleRow(v.name, v.locName, idx % rows))

  for(local i = titleComps.len(); i < total; i++)
    titleComps.append(emptyRow(i % rows))

  let chosenIdx = (titles.findindex(@(v) v.name == chosenTitleName.get()) ?? 0) % rows
  let showRowsAbove = (minRows / 2) - 0.5
  let onAttach = @() scrollHandler.scrollToY(rowHeight * (chosenIdx - showRowsAbove))

  return {
    key = listKey
    watch = [availTitles, allTitles]
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap
    onAttach
    children = arrayByRows(titleComps, rows).map(@(children) {
      size = FLEX_H
      flow = FLOW_VERTICAL
      children
    })
  }
}

let titleContent = {
  size = flex()
  flow = FLOW_VERTICAL
  gap
  children = [
    header
    {
      rendObj = ROBJ_TEXT
      text = loc("decorator/title/choose")
      padding = const [hdpx(40), 0,hdpx(40),0]
    }.__update(fontMedium)
    makeVertScroll(titlesList, { scrollHandler })
    footer
  ]
  animations = wndSwitchAnim
}

let titlesScene = @() {
  watch = hasVisibleTitles
  key = hasVisibleTitles
  size = flex()
  maxWidth = hdpx(1800)
  onAttach = @() selectedTitleName.set(chosenTitleName.get())
  onDetach = @() markDecoratorsSeen(unseenDecorators.get().filter(@(_, id) id in availTitles.get()).keys())
  children = hasVisibleTitles.value ? titleContent
    : {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = flex()
      rendObj = ROBJ_TEXT
      text = loc("title/no_titles")
    }.__update(fontMedium)
}



return titlesScene