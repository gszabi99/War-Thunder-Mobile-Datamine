from "%globalsDarg/darg_library.nut" import *
let { localPlayerColor, hoverColor } = require("%rGui/style/stdColors.nut")

let defPageColor = 0xFFC0C0C0
let pageHeight = evenPx(60)
let pageGap = hdpx(20)

let transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]

let pageText = @(text, color) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontSmall)

let underline = @(color) {
  size = [flex(), hdpx(5)]
  rendObj = ROBJ_SOLID
  color
}

let pageContainer = @(children, ovr) {
  size = [SIZE_TO_CONTENT, pageHeight]
  minWidth = pageHeight
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    flow = FLOW_VERTICAL
    children
  }
  transform = {}
  transitions
}.__update(ovr)

let dots = pageContainer([
    pageText("...", defPageColor)
    underline(0)
  ],
  { key = {} })

let mkCurPage = @(page) pageContainer(
  [
    pageText(page, 0xFFFFFFFF)
    underline(0xFFFFFFFF)
  ],
  { key = page })

let function mkPage(page, onClick, color) {
  let stateFlags = Watched(0)
  return @() pageContainer(
    [
      pageText(page, stateFlags.value & S_HOVER ? hoverColor : color)
      underline(stateFlags.value & S_HOVER ? hoverColor : 0)
    ],
    {
      watch = stateFlags
      key = page

      behavior = Behaviors.Button
      sound = { click  = "click" }
      onElemState = @(sf) stateFlags(sf)
      onClick
      transform = { scale = stateFlags.value & S_ACTIVE ? [0.8, 0.8] : [1, 1] }
    })
}

let emptyBtnPlace = { size = [pageHeight, pageHeight] }

let function arrowBtn(onClick, rotate) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = [pageHeight, pageHeight]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#spinnerListBox_arrow_up.svg:{pageHeight}:{pageHeight}:P")
    color = stateFlags.value & S_HOVER ? hoverColor : defPageColor

    behavior = Behaviors.Button
    sound = { click  = "click" }
    onElemState = @(sf) stateFlags(sf)
    onClick

    transform = {
      scale = stateFlags.value & S_ACTIVE ? [0.8, 0.8] : [1, 1]
      rotate
    }
    transitions
  }
}

let prevBtn = @(onClick) arrowBtn(onClick, -90)
let nextBtn = @(onClick) arrowBtn(onClick, 90)


//first page is 0
let mkPaginator = @(curPage, lastPage, myPage = Watched(-1), ovr = {}) function() {
  let res = { watch = [curPage, lastPage, myPage] }.__update(ovr)
  if (lastPage.value >= 0 && lastPage.value < 1)
    return res

  let cur = curPage.value
  let my = myPage.value
  let last = lastPage.value >= 0 ? lastPage.value : max(cur, 1) + 1
  let isMyPageListed = my <= last

  let children = [cur > 0 ? prevBtn(@() curPage(cur - 1)) : emptyBtnPlace]
  for (local i = 0; i <= last; i++) {
    let page = i
    let onClick = @() curPage(page)
    if (i == cur)
      children.append(mkCurPage(i + 1))
    else if ((cur - 1 <= i && i <= cur + 1)       //around current page
             || (i == my)                         //equal my page
             || (i < 3)                           //always show first 2 entrys
             || i == last)                        //show last entry
      children.append(mkPage(i + 1, onClick, my == i ? localPlayerColor : defPageColor))
    else {
      children.append(dots)
      if (isMyPageListed && i < my && (my < cur || i > cur))
        i = my - 1
      else if (i < cur)
        i = cur - 2
      else
        i = last - 1
    }
  }

  children.append(cur < last ? nextBtn(@() curPage(cur + 1)) : emptyBtnPlace)

  return res.__update({
    size = [SIZE_TO_CONTENT, pageHeight]
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    gap = pageGap
    flow = FLOW_HORIZONTAL
    children
  })
}

return {
  mkPaginator
}