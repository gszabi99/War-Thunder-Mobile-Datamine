from "%globalsDarg/darg_library.nut" import *
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { contentHeight } = require("%rGui/debriefing/debriefingWndConsts.nut")
let { mkMissionResultTitle } = require("%rGui/debriefing/missionResultTitle.nut")
let mkDebrQuestsProgress = require("%rGui/debriefing/mkDebrQuestsProgress.nut")

let questsAnimStartTime = 0.0

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
    size = [flex(), contentHeight]
    children = {
      size = flex()
      halign = ALIGN_CENTER
      children = [
        mkMissionResultTitle(debrData, false)
        {
          size = [flex(), pageContentHeight]
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
