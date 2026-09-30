from "%globalsDarg/darg_library.nut" import *
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_TINY, REWARD_STYLE_VERY_TINY


const progressHeight = hdpx(30)
const progressBorder = hdpx(3)
let smallProgressWidth = REWARD_STYLE_TINY.boxSize * 3 / 2 - hdpx(6)

let rewardSizes = {
  smallRight = {
    fullSize = [REWARD_STYLE_TINY.boxSize + smallProgressWidth - progressBorder, REWARD_STYLE_TINY.boxSize]
    progressWidth = smallProgressWidth
    cardStyle = REWARD_STYLE_TINY.__merge({ needShowPreview = false })
  }

  tinyRight = {
    fullSize = [REWARD_STYLE_VERY_TINY.boxSize + smallProgressWidth - progressBorder, REWARD_STYLE_VERY_TINY.boxSize]
    progressWidth = smallProgressWidth
    cardStyle = REWARD_STYLE_VERY_TINY.__merge({ needShowPreview = false })
  }
}

let defRewardProgress = "smallRight"
let defSize = rewardSizes[defRewardProgress].fullSize

let getRewardSize = @(id) rewardSizes?[id].fullSize ?? defSize

return {
  progressHeight
  progressBorder

  defRewardProgress
  rewardSizes
  getRewardSize
}