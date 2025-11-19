from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout, clearTimer
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

function mkFoldableList(listContent, headerContent, listW = null, curOpenedSelector = null, selectorId = null) {
  let stateFlags = Watched(0)
  let isExpanded = Watched(false)
  let contentHeight = Watched(0)
  let foldableHeight = Watched(headerH)
  let collapseFoldableHeight = @() foldableHeight.set(headerH)

  let header = @() {
    watch = [stateFlags, isExpanded]
    size = [flex(), headerH]
    rendObj = ROBJ_SOLID
    color = (stateFlags.get() & S_HOVER) != 0 ? headerBgHoverColor : headerBgColor
    behavior = Behaviors.Button
    function onClick() {
      let isExpand = !isExpanded.get()
      isExpanded.set(isExpand)
      if (isExpand)
        curOpenedSelector?.set(selectorId)
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

  let content = @() {
    watch = [isExpanded, contentHeight]
    size = FLEX_H
    pos = [0, headerH]
    flow = FLOW_VERTICAL
    padding = contentPadding
    rendObj = ROBJ_SOLID
    color = contentBgColor
    clipChildren = true
    children = listContent
    opacity = isExpanded.get() ? 1 : 0
    transform = { translate = [0, (isExpanded.get() ? 0 : -contentHeight.get())] }
    transitions = [
      { prop = AnimProp.translate, duration = defaultExpandAnimationDuration }
      { prop = AnimProp.opacity, duration = defaultExpandAnimationDuration }
    ]
  }

  let updateContentHeight = @() contentHeight.set(calc_comp_size(content)[1])
  listW?.subscribe(@(_) updateContentHeight())
  updateContentHeight()
  curOpenedSelector?.subscribe(@(v) v == selectorId ? null : isExpanded.set(false))
  isExpanded.subscribe(function(v) {
    if (v) {
      clearTimer(collapseFoldableHeight)
      foldableHeight.set(headerH + contentHeight.get())
    }
    else
      resetTimeout(defaultExpandAnimationDuration, collapseFoldableHeight)
  })

  return @() {
    watch = foldableHeight
    size = [hdpx(520), foldableHeight.get()]
    clipChildren = true
    children = [
      content
      header
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
  listValues
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
  contentPadding
  contentBgColor
  headerBgColor
}
