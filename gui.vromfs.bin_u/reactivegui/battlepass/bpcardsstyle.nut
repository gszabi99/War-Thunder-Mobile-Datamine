from "%globalsDarg/darg_library.nut" import *
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_MEDIUM


let bpCardStyle = REWARD_STYLE_MEDIUM
let bpCardPadding = [hdpx(20), hdpx(20)]
const bpCardGap = hdpx(12)
let bpCardFooterHeight = evenPx(50)

return {
  bpCardHeight = bpCardPadding[0] + bpCardStyle.boxSize + bpCardGap + bpCardFooterHeight + bpCardPadding[1]
  bpCardMargin = hdpx(6)
  bpCardStyle
  bpCardPadding
  bpCardGap
  bpCardFooterHeight
}