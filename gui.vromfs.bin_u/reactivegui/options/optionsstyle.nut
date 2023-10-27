from "%globalsDarg/darg_library.nut" import *

let tabH = hdpx(135)
let tabW = hdpx(410)
let minContentOffset = isWidescreen ? hdpx(100) : hdpx(50)
let contentWidthFull = saSize[0] - tabW - minContentOffset
let contentWidth = min(contentWidthFull, hdpx(1050))
let contentOffset = 0.5 * (saSize[0] - tabW - contentWidth)

return {
  tabH
  tabW
  contentOffset
  contentWidth
  contentWidthFull
  minContentOffset
}