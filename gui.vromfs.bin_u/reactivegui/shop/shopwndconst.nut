from "%globalsDarg/darg_library.nut" import *


const goodsGap = hdpx(20)
const goodsSmallSizeW = hdpxi(488)
const goodsPerRow = 3
const iconSize = hdpxi(106)
const iconMarginW = hdpx(16)
const tabW = iconSize + iconMarginW * 2


return {
  goodsGap
  goodsH = hdpxi(320)
  goodsSmallSizeW
  goodsPerRow
  iconSize
  iconMarginW
  tabW
  tabH = iconSize
  categoryGap = hdpx(80)
  shopGap = (sw(100) - saBorders[0] * 2 - tabW - (goodsPerRow - 1) * goodsGap - goodsPerRow * goodsSmallSizeW) / 2
  titleGap = hdpx(4)
  titleH = hdpxi(52)
}