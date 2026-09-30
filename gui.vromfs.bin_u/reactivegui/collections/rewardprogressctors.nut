from "%globalsDarg/darg_library.nut" import *
from "%rGui/collections/collectionComps.nut" import mkProgress
from "%rGui/collections/rewardProgressConsts.nut" import rewardSizes, defRewardProgress, progressBorder
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlate, mkRewardReceivedMark, mkRewardPlateBg
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo, sortRewardsViewInfo


let rightCtor = @(sizes) function smallRight(rewards, cur, total, isReceived) {
  let vInfo = getRewardsViewInfo(rewards).sort(sortRewardsViewInfo)
  let main = vInfo?[0]
  let { fullSize, progressWidth, cardStyle } = sizes
  return {
    size = fullSize
    halign = ALIGN_RIGHT
    valign = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    gap = -progressBorder
    children = [
      isReceived ? null : mkProgress(cur, total, progressWidth)
      main == null ? mkRewardPlateBg({ slots = 1 }, cardStyle)
        : !isReceived ? mkRewardPlate(main, cardStyle)
        : {
            children = [
              mkRewardPlate(main, cardStyle)
              mkRewardReceivedMark(cardStyle)
            ]
          }
    ]
  }
}

let rewardCtors = {
  smallRight = rightCtor(rewardSizes.smallRight)
  tinyRight = rightCtor(rewardSizes.tinyRight)
}

foreach (id, _ in rewardCtors)
  if (id not in rewardSizes)
    logerr($"No size for colections reward ctor: {id}")
foreach (id, _ in rewardSizes)
  if (id not in rewardCtors)
    logerr($"Size without collection reward ctor: {id}")

let defCtor = rewardCtors[defRewardProgress]

return {
  rewardCtors
  getRewardCtor = @(id) rewardCtors?[id] ?? defCtor
}