from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/circleBtn.nut" import mkCircleBtn, circleBtnStyles
from "%rGui/style/stdColors.nut" import localPlayerColor, hoverColor, textColor


const defPageColor = 0xFFC0C0C0
const circleBtnImgSize = evenPx(30)
const pageHeight = evenPx(60)
const pageGap = hdpx(20)
const arrowImage = "ui/gameuiskin#spinnerListBox_arrow_up.svg"

let transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]

let pageText = @(text, color) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontSmall)

let underline = @(color) {
  size = const [FLEX, hdpx(5)]
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
    pageText(page, textColor)
    underline(textColor)
  ],
  { key = page })

function mkPage(page, onClick, color) {
  let stateFlags = Watched(0)
  return @() pageContainer(
    [
      pageText(page, stateFlags.get() & S_HOVER ? hoverColor : color)
      underline(stateFlags.get() & S_HOVER ? hoverColor : 0)
    ],
    {
      watch = stateFlags
      key = page

      behavior = Behaviors.Button
      sound = { click  = "click" }
      onElemState = @(sf) stateFlags.set(sf)
      onClick
      transform = { scale = stateFlags.get() & S_ACTIVE ? [0.8, 0.8] : [1, 1] }
    })
}

function mkArrowBtn(imgRotate) {
  let sizeOvr = { size = pageHeight, imgSize = circleBtnImgSize, imgRotate }
  let style = freeze(circleBtnStyles.COMMON.__merge(sizeOvr))
  let inactiveStyle = freeze(circleBtnStyles.INACTIVE.__merge(sizeOvr))

  return @(onClick, isEnabled) isEnabled
    ? mkCircleBtn(arrowImage, onClick, style)
    : mkCircleBtn(arrowImage, @() null, inactiveStyle)
}

let prevBtn = mkArrowBtn(-90)
let nextBtn = mkArrowBtn(90)

let mkPaginatorRow = @(watch, children, ovr) {
  watch
  size = [SIZE_TO_CONTENT, pageHeight]
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  gap = pageGap
  flow = FLOW_HORIZONTAL
  children
}.__update(ovr)


let mkPaginator = @(curPage, lastPage, myPage = Watched(-1), ovr = {}) function() {
  let watch = [curPage, lastPage, myPage]
  if (lastPage.get() >= 0 && lastPage.get() < 1)
    return { watch }.__update(ovr)

  let cur = curPage.get()
  let my = myPage.get()
  let last = lastPage.get() >= 0 ? lastPage.get() : max(cur, 1) + 1
  let isMyPageListed = my <= last

  let children = [prevBtn(@() curPage.set(cur - 1), cur > 0)]
  for (local i = 0; i <= last; i++) {
    let page = i
    let onClick = @() curPage.set(page)
    if (i == cur)
      children.append(mkCurPage(i + 1))
    else if ((cur - 1 <= i && i <= cur + 1)       
             || (i == my)                         
             || (i < 3)                           
             || i == last)                        
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

  children.append(nextBtn(@() curPage.set(cur + 1), cur < last))

  return mkPaginatorRow(watch, children, ovr)
}

let mkPaginatorCurPage = @(curPage, lastPage, ovr = {}) function() {
  let watch = [curPage, lastPage]
  if (lastPage.get() >= 0 && lastPage.get() < 1)
    return { watch }.__update(ovr)

  let cur = curPage.get()
  let last = lastPage.get() >= 0 ? lastPage.get() : max(cur, 1) + 1

  return mkPaginatorRow(watch,
    [
      prevBtn(@() curPage.set(cur - 1), cur > 0)
      {
        minWidth = pageHeight
        halign = ALIGN_CENTER
        children = pageText(cur + 1, textColor)
      }
      nextBtn(@() curPage.set(cur + 1), cur < last)
    ],
    ovr)
}

return {
  mkPaginator
  mkPaginatorCurPage
}