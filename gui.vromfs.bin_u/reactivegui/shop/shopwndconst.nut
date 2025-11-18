from "%globalsDarg/darg_library.nut" import *
let { selLineSize } = require("%rGui/components/tabs.nut")


let goodsGap = hdpx(20)
let goodsSmallSizeW = hdpxi(488)
let goodsPerRow = 3
let iconSize = hdpxi(106)
let iconMarginW = hdpx(16)
let tabW = iconSize + iconMarginW * 2
let fullTabW = tabW + selLineSize


return {
  goodsGap
  goodsH = hdpxi(378)
  goodsSmallSizeW
  goodsPerRow
  iconSize
  iconMarginW
  tabW
  tabH = iconSize
  fullTabW
  categoryGap = hdpx(80)
  shopGap = (sw(100) - saBorders[0] * 2 - fullTabW - (goodsPerRow - 1) * goodsGap - goodsPerRow * goodsSmallSizeW) / 2
  titleGap = hdpx(4)
  titleH = hdpxi(52)
}