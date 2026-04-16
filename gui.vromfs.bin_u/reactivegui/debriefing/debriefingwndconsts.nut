from "%globalsDarg/darg_library.nut" import *
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")

let tabFinalPauseTime = 2.0
let buttonsShowTime = 1.0

let footerGap = hdpx(30)
let footerHeight = defButtonHeight
let contentHeight = saSize[1] - footerGap - footerHeight

return {
  tabFinalPauseTime
  buttonsShowTime

  contentHeight
  footerGap
  footerHeight
}
