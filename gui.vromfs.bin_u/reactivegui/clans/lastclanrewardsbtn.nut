from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/clans/clanQuestsState.nut" import clanProgress, hasClanProgressReward, startClanProgressRefresh,
  stopClanProgressRefresh
from "%rGui/clans/components/clanProgressBlock.nut" import mkClanProgressBar
from "%rGui/clans/currentClanState.nut" import NO_CLAN_ID, currentClanId
from "%rGui/components/modalWindows.nut" import addModalWindowWithHeader, removeModalWindow
from "%rGui/components/textButton.nut" import textButtonCommon, textButtonUnseenMargin
from "%rGui/components/unseenMark.nut" import mkPriorityUnseenMarkWatch


const WND_UID = "lastClanRewardsWnd"
let needShowLastClanRewardsBtn = Computed(@() currentClanId.get() == NO_CLAN_ID
  && (clanProgress.get()?.hasReward ?? false))

let openLastClanRewardsWnd = @() addModalWindowWithHeader(WND_UID,
  loc("clan/lastClanRewards"),
  {
    padding = hdpx(40)
    children = mkClanProgressBar(false)
  })

currentClanId.subscribe(@(id) id == NO_CLAN_ID ? null : removeModalWindow(WND_UID))

let unseenMark = mkPriorityUnseenMarkWatch(hasClanProgressReward,
  { hplace = ALIGN_RIGHT, vplace = ALIGN_TOP, margin = textButtonUnseenMargin })

let lastClanRewardsBtn = @() {
  watch = needShowLastClanRewardsBtn
  onAttach = startClanProgressRefresh
  onDetach = stopClanProgressRefresh
  children = !needShowLastClanRewardsBtn.get() ? null
    : [
        textButtonCommon(utf8ToUpper(loc("clan/lastClanRewards")), openLastClanRewardsWnd)
        unseenMark
      ]
}

return { lastClanRewardsBtn }
