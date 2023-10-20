from "%globalsDarg/darg_library.nut" import *
let { gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")

let lbHeaderHeight = gamercardHeight
let lbFooterHeight = hdpx(60)
let lbVGap = hdpx(10)
let lbTableBorderWidth = hdpx(4)
let lbHeaderRowHeight = hdpx(60)
let lbRowHeight = hdpxi(40)

let lbTableHeight = saSize[1] - lbHeaderHeight - lbFooterHeight - 2 * lbVGap
let lbPageRows = (lbTableHeight - lbHeaderRowHeight - lbTableBorderWidth).tointeger() / lbRowHeight - 2

return {
  lbHeaderHeight
  lbFooterHeight
  lbVGap
  lbTableHeight
  lbHeaderRowHeight
  lbRowHeight
  lbTableBorderWidth
  lbPageRows
}