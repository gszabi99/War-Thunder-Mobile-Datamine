from "%globalsDarg/darg_library.nut" import *

let tabH = hdpx(140)
let tabW = hdpx(410)
let minContentOffset = hdpx(100)
let contentWidth = min(saSize[0] - tabW - minContentOffset, hdpx(1050))
let contentOffset = 0.5 * (saSize[0] - tabW - contentWidth)

return {
  tabH
  tabW
  contentOffset
  contentWidth
}