from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/listConst.nut" import tabExtraWidth

const tabH = hdpx(120)
const tabW = hdpx(410)
let tabPadding = const [hdpx(10), hdpx(20)]
let minContentOffset = isWidescreen ? hdpx(100) : hdpx(50)
let contentWidthFull = saSize[0] - tabW + tabExtraWidth - minContentOffset
let contentWidth = min(contentWidthFull, hdpx(1050))
let contentOffset = 0.5 * (saSize[0] - tabW + tabExtraWidth - contentWidth)

return {
  tabH
  tabW
  tabPadding
  contentOffset
  contentWidth
  contentWidthFull
  minContentOffset
}