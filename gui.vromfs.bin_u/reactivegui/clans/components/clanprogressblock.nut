from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/pServer/pServerApi.nut" import clanProgressRewardInProgress
from "%rGui/clans/clanQuestsInfoWnd.nut" import openClanQuestsInfoWnd
from "%rGui/clans/clanQuestsState.nut" import clanProgress, receiveClanProgressReward,
  startClanProgressRefresh, stopClanProgressRefresh
from "%rGui/components/infoButton.nut" import infoEllipseButton
from "%rGui/quests/questBar.nut" import mkQuestListProgressBar, mkStagesCtor
from "%rGui/quests/rewardsComps.nut" import progressBarRewardSize
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo
from "%rGui/style/gradients.nut" import simpleHorGrad
from "%rGui/tooltip.nut" import showHint


const HINT_SHOW_TIME = 10
const titleHeight = hdpx(80)
const blocksGap = hdpx(20)

let isPrevSeason = Computed(@() clanProgress.get()?.isPrevSeason ?? false)
let isRewardInProgress = Computed(@() clanProgressRewardInProgress.get() != null)
let isFullScreenWidth = Watched(false)

let getClanStageRewards = @(stage, _) getRewardsViewInfo(stage.rewards)
let mkClanStages = mkStagesCtor(@(_) isRewardInProgress, getClanStageRewards,
  @(progress, idx, _) receiveClanProgressReward(progress, idx),
  @(evt) showHint(evt.targetRect, loc("clan/quests/needPersonalProgress"), HINT_SHOW_TIME))

let mkTitle = @() {
  size = [SIZE_TO_CONTENT, titleHeight]
  rendObj = ROBJ_IMAGE
  image = simpleHorGrad
  flipX = true
  color = 0xAA000000
  padding = const [0, hdpx(60), 0, hdpx(20)]
  flow = FLOW_HORIZONTAL
  gap = hdpx(30)
  valign = ALIGN_CENTER
  children = [
    @() {
      watch = isPrevSeason
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc(isPrevSeason.get() ? "clan/quests/prevSeasonRewards" : "clan/quests/getClanVehicles"))
      ...fontMedium
    }
    infoEllipseButton(openClanQuestsInfoWnd)
  ]
}

let mkClanProgressBlock = @() {
  flow = FLOW_VERTICAL
  gap = blocksGap
  onAttach = startClanProgressRefresh
  onDetach = stopClanProgressRefresh
  children = [
    mkTitle()
    mkQuestListProgressBar(clanProgress, isFullScreenWidth, mkClanStages, getClanStageRewards)
  ]
}

return {
  mkClanProgressBlock
  clanProgressBlockHeight = titleHeight + blocksGap + progressBarRewardSize
}
