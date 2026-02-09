from "%globalsDarg/darg_library.nut" import *
from "%sqstd/underscore.nut" import arrayByRows
from "%rGui/components/expandArrow.nut" import expandArrow, defaultExpandAnimationDuration
from "%rGui/style/gradients.nut" import mkColoredGradientY

let headerH = hdpx(90)
let itemGap = hdpx(8)
let contentPadding = itemGap

let contentBgColor = 0x990C1113
let headerBgColor = 0x99000000
let headerBgHoverColor = 0x99080808
let itemBgColor = 0xFF29292C
let itemBgHoverColor = 0xFF2F2F33

let arrowSize = [evenPx(30), evenPx(24)]
let arrowOvr = {
  margin = [0, hdpx(30)]
  image = Picture($"ui/gameuiskin#triangle.svg:{arrowSize[0]}:{arrowSize[1]}:P")
}

function mkFoldableList(listContent, headerContent, curOpenedSelector, selectorId, handleClick = null) {
  let stateFlags = Watched(0)
  let isExpanded = Computed(@() curOpenedSelector.get() == selectorId)

  let header = @() {
    watch = stateFlags
    size = [flex(), headerH]
    rendObj = ROBJ_SOLID
    color = (stateFlags.get() & S_HOVER) != 0 ? headerBgHoverColor : headerBgColor
    behavior = Behaviors.Button
    function onClick() {
      if (handleClick?(isExpanded.get()))
        return
      curOpenedSelector.set(isExpanded.get() ? null : selectorId)
    }
    onElemState = @(v) stateFlags.set(v)
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(20)
    children = [
      expandArrow(isExpanded, defaultExpandAnimationDuration, arrowSize, arrowOvr)
      headerContent
    ]
  }

  let content = {
    size = FLEX_H
    flow = FLOW_VERTICAL
    padding = contentPadding
    rendObj = ROBJ_SOLID
    color = contentBgColor
    clipChildren = true
    children = listContent
  }

  return @() {
    watch = isExpanded
    size = FLEX_H
    behavior = Behaviors.TransitionSize
    orientation = O_VERTICAL
    speed = hdpx(2000)
    maxTime = 0.3
    clipChildren = true
    flow = FLOW_VERTICAL
    children = [
      header
      {
        size = isExpanded.get() ? FLEX_H : [flex(), 0]
        children = content
      }
    ]
  }
}

let mkFoldableSelector = @(listValues, curValue, columns, itemCtor, headItemCtor, curOpenedSelector, selectorId) mkFoldableList(
  @() {
    watch = listValues
    flow = FLOW_VERTICAL
    gap = itemGap
    children = arrayByRows(listValues.get().map(@(id) itemCtor(id, Computed(@() curValue.get() == id), function() {
        curValue.set(id)
        curOpenedSelector?.set("")
      })), columns)
        .map(@(children) {
          flow = FLOW_HORIZONTAL
          gap = itemGap
          children
        })
  },
  @() {
    watch = curValue
    children = headItemCtor(curValue.get())
  },
  curOpenedSelector,
  selectorId
)

let itemBase = {
  rendObj = ROBJ_SOLID
  color = itemBgColor
}

let selItemBg = {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = mkColoredGradientY(0xFF7FAEFF, 0xFF333333)
}

function mkListItem(id, isSelectedW, onClick, w, h, content) {
  let stateFlags = Watched(0)
  return @() itemBase.__merge({
    watch = stateFlags
    key = id
    size = [w, h]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    color = (stateFlags.get() & S_HOVER) != 0 ? itemBgHoverColor : itemBgColor
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    onClick
    sound = { click  = "click" }
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
    children = [
      @() { watch = isSelectedW }.__merge(isSelectedW.get() ? selItemBg : {})
      content
    ]
  })
}

return {
  mkFoldableList
  mkFoldableSelector
  mkListItem

  itemGap
  headerH
  contentPadding
  contentBgColor
  headerBgColor
}
