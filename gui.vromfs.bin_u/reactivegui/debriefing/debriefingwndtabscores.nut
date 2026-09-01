from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/adsButton.nut" import mkAdsButton
import "%rGui/debriefing/achievementsBlock.nut" as achievementsBlock
from "%rGui/debriefing/missionResultTitle.nut" import mkMissionResultTitle, missionResultTitleAnimTime
from "%rGui/debriefing/mkDebriefingStats.nut" import mkDebriefingStats
from "%rGui/debriefing/totalRewardCounts.nut" import mkTotalRewardCountsScores
from "%rGui/style/gradients.nut" import gradTranspDoubleSideX, mkColoredGradientY


const rewardsAnimStartTime = 0.5

let scoreBgPanel = {
  rendObj = ROBJ_IMAGE
  image = mkColoredGradientY(0x80000000, 0x00000000, 12)
  padding = const [hdpx(10), 0, hdpx(10), 0]
  flow = FLOW_VERTICAL
}

function mkDebriefingWndTabScores(debrData, _params) {
  if (debrData == null)
    return null

  let achievementsAnimStartTime = missionResultTitleAnimTime / 2
  let { achievementsAnimTime, achievementsComp } = achievementsBlock(debrData, achievementsAnimStartTime)
  let statsAnimStartTime = achievementsAnimStartTime + achievementsAnimTime
  let { statsAnimEndTime, debriefingStats, usedItems } = mkDebriefingStats(debrData, statsAnimStartTime)

  let { totalRewardCountsComp, totalRewardsShowTime, btnTryPremium
  } = mkTotalRewardCountsScores(debrData, rewardsAnimStartTime)

  let timeShow = max(
    statsAnimEndTime,
    rewardsAnimStartTime + totalRewardsShowTime,
  )

  if (achievementsComp == null && totalRewardCountsComp == null && debriefingStats == null)
    return null

  let comp = {
    size = FLEX
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      mkMissionResultTitle(debrData, true)
      achievementsComp
      scoreBgPanel.__merge(
        {
          size = FLEX
          gap = hdpx(10)
          children = [
            {
              size = FLEX_H
              flow = FLOW_HORIZONTAL
              padding = const [0, hdpx(40)]
              halign = ALIGN_CENTER
              gap = hdpx(40)
              children = [
                totalRewardCountsComp == null ? null
                  : totalRewardCountsComp
                debriefingStats == null ? null
                  : debriefingStats
              ]
            }
            {
              size = const [hdpx(1000), hdpx(9)]
              hplace = ALIGN_CENTER
              rendObj = ROBJ_IMAGE
              image = gradTranspDoubleSideX
              color = 0xFF808080
            }
            {
              size = FLEX
              children = [
                usedItems == null ? null
                  : usedItems.__merge(
                    {
                      hplace = ALIGN_CENTER,
                      vplace = ALIGN_TOP,
                    })
                {
                  size = FLEX
                  flow = FLOW_HORIZONTAL
                  valign = ALIGN_BOTTOM
                  children = [
                    mkAdsButton(debrData)
                    {size = FLEX}
                    btnTryPremium
                  ]}
              ]
            }
          ]
        }
      )
    ]
  }

  return {
    comp
    timeShow
    forceStopAnim = false
  }
}

return mkDebriefingWndTabScores
