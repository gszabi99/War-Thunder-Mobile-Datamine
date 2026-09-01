from "%globalsDarg/darg_library.nut" import *
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_TINY
from "%rGui/style/gamercardStyle.nut" import gamercardHeight


let lbHeaderHeight = gamercardHeight
const lbFooterHeight = hdpx(60)
const lbVGap = hdpx(10)
const lbTableBorderWidth = hdpxi(4)
let lbHeaderRowHeight = evenPx(60)
let lbRowHeight = evenPx(60)
let lbDotsRowHeight = lbRowHeight / 2
let lbTableHeightBase = saSize[1] - lbHeaderHeight - lbFooterHeight - 2 * lbVGap
let lbPageRows = (lbTableHeightBase - lbHeaderRowHeight - lbTableBorderWidth - lbDotsRowHeight).tointeger() / lbRowHeight -1
let lbTableHeight = lbHeaderRowHeight + lbTableBorderWidth + lbDotsRowHeight + (lbPageRows + 1) * lbRowHeight
const lbTabIconSize = hdpxi(60)

let rewardStyle = clone REWARD_STYLE_TINY
let lbRewardsPerRow = isWidescreen ? 6 : 5
let lbRewardRowHeightBase = (lbDotsRowHeight + 11 * lbRowHeight) / (isWidescreen ? 5 : 6)
let lbRewardsGap = clamp((lbRewardRowHeightBase - rewardStyle.boxSize) / 2, lbTableBorderWidth, rewardStyle.boxGap)
let lbRewardRowPadding = lbRewardsGap
let lbRewardsBlockWidth = rewardStyle.boxSize * lbRewardsPerRow + lbRewardsGap * (lbRewardsPerRow - 1)
  + 2 * lbTableBorderWidth + 2 * lbRewardRowPadding

rewardStyle.boxGap = lbRewardsGap

let prizeIcons = [
  "leaderboard_trophy_01.avif"
  "leaderboard_trophy_02.avif"
  "leaderboard_trophy_03.avif"
  "leaderboard_trophy_04.avif"
  "leaderboard_trophy_05.avif"
  "leaderboard_trophy_06.avif"
]

const rowBgOddColor = 0x60000000
const rowBgEvenColor = 0x60141414
const rowBgMyOddColor = 0x600A2630
const rowBgMyEvenColor = 0x60104051

return {
  rowBgOddColor
  rowBgEvenColor
  rowBgMyOddColor
  rowBgMyEvenColor
  getRowBgColor = @(isOdd, isMy)
    isOdd ? (isMy ? rowBgMyOddColor  : rowBgOddColor)
          : (isMy ? rowBgMyEvenColor : rowBgEvenColor)

  lbHeaderHeight
  lbVGap
  lbTableHeight
  lbHeaderRowHeight
  lbRowHeight
  lbDotsRowHeight
  lbTableBorderWidth
  lbPageRows
  lbTabIconSize

  rewardStyle
  lbRewardsBlockWidth
  lbRewardRowPadding
  lbRewardsGap
  prizeIcons
}
