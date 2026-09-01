from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/debriefing/debriefingWndConsts.nut" import contentHeight
from "%rGui/debriefing/missionResultTitle.nut" import mkMissionResultTitle
import "%rGui/debriefing/mkDebrQuestsProgress.nut" as mkDebrQuestsProgress


const questsAnimStartTime = 0.0

let pageContentHeight = contentHeight - hdpx(120)
let contentGradientSize = [ hdpx(20), hdpx(50) ]
let pannableArea = verticalPannableAreaCtor(pageContentHeight + contentGradientSize[0]
  + 0.5 * contentGradientSize[1], contentGradientSize)

function mkDebriefingWndTabQuests(debrData, _params) {
  let { questsProgressComps, questsProgressShowTime } = mkDebrQuestsProgress(debrData, questsAnimStartTime)
  if (questsProgressComps == null)
    return null

  let timeShow = questsAnimStartTime + questsProgressShowTime

  let comp = {
    size = [FLEX, contentHeight]
    children = {
      size = FLEX
      halign = ALIGN_CENTER
      children = [
        mkMissionResultTitle(debrData, false)
        {
          size = [FLEX, pageContentHeight]
          vplace = ALIGN_BOTTOM
          children = pannableArea(questsProgressComps)
        }
      ]
    }
  }

  return {
    comp
    timeShow
    forceStopAnim = false
  }
}

return mkDebriefingWndTabQuests
