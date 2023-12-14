from "%globalsDarg/darg_library.nut" import *
let { REWARD_STYLE_MEDIUM } = require("%rGui/rewards/rewardStyles.nut")

let bpCardStyle = REWARD_STYLE_MEDIUM
let bpCardPadding = [hdpx(50), hdpx(20)]
let bpCardGap = hdpx(12)
let bpCardFooterHeight = evenPx(50)

return {
  bpCardHeight = bpCardPadding[0] + bpCardStyle.boxSize + bpCardGap + bpCardFooterHeight + bpCardPadding[1]
  bpCardMargin = hdpx(6)
  bpCardStyle
  bpCardPadding
  bpCardGap
  bpCardFooterHeight
}