from "%globalsDarg/darg_library.nut" import *
let { arrayByRows } = require("%sqstd/underscore.nut")
let { ceil } = require("%sqstd/math.nut")
let { myUserName } = require("%appGlobals/profileStates.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { chosenTitle, allTitles, chosenNickFrame, availTitles, getReceiveReason,
unseenDecorators, markDecoratorSeen, markDecoratorsSeen } = require("decoratorState.nut")
let { set_current_decorator, unset_current_decorator, decoratorInProgress
} = require("%appGlobals/pServer/pServerApi.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")
let { textButtonPrimary, textButtonCommon } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkTitle } = require("%rGui/decorators/decoratorsPkg.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")


let gap = hdpx(15)
let checkIconSize = hdpx(45)
let rowHeight = hdpx(75)
let minRows = 6
let columns = 2

let bgColor = @(rowIdx) rowIdx % 2 == 0 ? 0x00000000 : 0x80323232

let selectedTitle = Watched(chosenTitle.value?.name)
let visibleTitles = Computed(@() allTitles.value.filter(@(dec, id) !dec.isHidden || (id in availTitles.value)))
let hasVisibleTitles = Computed(@() visibleTitles.value.len() > 0)

let choosenMark = {
  size = [checkIconSize,checkIconSize]
  rendObj  =  ROBJ_IMAGE
  color = 0xFF00FF00
  hplace = ALIGN_CENTER
  image =  Picture($"ui/gameuiskin#check.svg:{checkIconSize}:{checkIconSize}:P")
}

let function applySelectedTitle(){
  if (selectedTitle.value == "") {
    unset_current_decorator("title")
    return
  }
  if (selectedTitle.value not in availTitles.value){
    openMsgBox({
      text = getReceiveReason(selectedTitle.value) ?? loc("decor/decorNotAvailable")
      buttons = [{ id = "ok", isCancel = true }]
    })
    return
  }
  set_current_decorator(selectedTitle.value)
}

let header = {
  size = [SIZE_TO_CONTENT,hdpx(100)]
  flow = FLOW_VERTICAL
  children = [
    @() {
      watch = [myUserName, chosenNickFrame]
      rendObj = ROBJ_TEXT
      text = frameNick(myUserName.value, chosenNickFrame.value?.name)
    }.__update(fontMedium)
    mkTitle(fontSmall)
  ]
}

let function titleRow(name, locName, rowIdx) {
  let stateFlags = Watched(0)
  let isChoosen = Computed(@() chosenTitle.value?.name == name ||
    (chosenTitle.value == null && name == ""))
  let isSelected = Computed(@() selectedTitle.value == name)
  let isUnseen = Computed(@() name in unseenDecorators.value)
  return {
    rendObj = ROBJ_SOLID
    size = [flex(), rowHeight]
    color = bgColor(rowIdx)
    behavior = Behaviors.Button
    valign = ALIGN_CENTER
    onElemState = @(sf) stateFlags(sf)
    function onClick() {
      markDecoratorSeen(name)
      if (!isSelected.value)
        selectedTitle(name)
      else if (isSelected.value && !isChoosen.value
          && decoratorInProgress.value != (name ?? "title"))
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
          size = [hdpx(85),hdpx(85)]
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = name != "" && name not in availTitles.value
            ? {
                size =[hdpx(35),hdpx(45)]
                rendObj = ROBJ_IMAGE
                color = 0xFFFFB70B
                image =  Picture($"!ui/gameuiskin#lock_icon.svg:{hdpxi(35)}:{hdpxi(45)}:P")
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

let footer = @() {
  watch = [selectedTitle, chosenTitle]
  size = [flex(), defButtonHeight]
  flow = FLOW_HORIZONTAL
  gap = hdpx(50)
  children = [
    selectedTitle.value == chosenTitle.value?.name
        ? null
      : selectedTitle.value in availTitles.value || selectedTitle.value == ""
        ? textButtonPrimary(loc("mainmenu/btnEquip"), applySelectedTitle,
          { hotkeys = ["^J:X | Enter"] })
      : textButtonCommon(loc("mainmenu/btnEquip"), applySelectedTitle)
    {
      rendObj = ROBJ_TEXT
      vplace = ALIGN_CENTER
      text = getReceiveReason(selectedTitle.value)
    }.__update(fontSmallAccented)
  ]
}

let function titlesList() {
  local total = max(visibleTitles.value.len() + 1, columns * minRows)
  let rows = ceil(total.tofloat() / columns).tointeger()
  total = rows * columns

  let titleComps = visibleTitles.value
    .keys()
    .map(@(name) { name, locName = loc($"title/{name}") })
    .sort(@(a,b) (b.name in availTitles.value) <=> (a.name in availTitles.value)
      || a.locName <=> b.locName)
    .insert(0, { name = "", locName = loc("title/empty") })
    .map(@(v, idx) titleRow(v.name, v.locName, idx % rows))

  for(local i = titleComps.len(); i < total; i++)
    titleComps.append(emptyRow(i % rows))

  return {
    watch = [availTitles, allTitles]
    flow = FLOW_HORIZONTAL
    gap
    size = [flex(), SIZE_TO_CONTENT]
    children = arrayByRows(titleComps, rows).map(@(children) {
      size = [flex(), SIZE_TO_CONTENT]
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
      text = loc("decorators/chooseDecoratorName")
      padding = [hdpx(40), 0,hdpx(40),0]
    }.__update(fontMedium)
    makeVertScroll(titlesList)
    footer
  ]
  animations = wndSwitchAnim
}

let titlesScene = @() {
  watch = hasVisibleTitles
  key = hasVisibleTitles
  size = flex()
  maxWidth = hdpx(1800)
  onDetach = @() markDecoratorsSeen(unseenDecorators.value.filter(@(_, id) id in availTitles.value).keys())
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