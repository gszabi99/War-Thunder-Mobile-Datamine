from "%globalsDarg/darg_library.nut" import *
from "string" import format
from "%sqstd/time.nut" import secondsToTime
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/clans/clanQuestsState.nut" import CLAN_QUESTS_TAB, clanQuests, isClanQuestsLocked, clanQuestsUnlockTime
from "%rGui/clans/components/clanProgressBlock.nut" import mkClanProgressBlock, clanProgressBlockHeight
from "%rGui/components/gradientDefComps.nut" import headerHeightInSafeArea, headerMargin
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/components/scrollArrows.nut" import mkScrollArrow, scrollArrowImageSmall
from "%rGui/quests/questsPkg.nut" import mkTimeUntil, allQuestsCompleted
from "%rGui/quests/questsState.nut" import saveSeenQuests
from "%rGui/quests/questsWndPage.nut" import mkQuest, mkQuestsList, mergeQuestChains, questsSort
from "%rGui/unlocks/unlocks.nut" import unseenUnlocks


const pageBlocksGap = hdpx(30)
const listGradientHeight = hdpx(20)
const lockedBgColor = 0xD0000000

let mkListPannable = verticalPannableAreaCtor(
  saSize[1] - headerHeightInSafeArea - headerMargin - clanProgressBlockHeight,
  [pageBlocksGap, listGradientHeight])

let curSectionId = Watched(null)
let clanQuestsSorted = Computed(@()
  mergeQuestChains(clanQuests.get(), CLAN_QUESTS_TAB, curSectionId.get()).values().sort(questsSort))
let hasQuests = Computed(@() clanQuestsSorted.get().len() > 0)

function markQuestsSeen() {
  if (isClanQuestsLocked.get())
    return
  let names = clanQuests.get().filter(@(q, id) !q.hasReward && id in unseenUnlocks.get()).keys()
  if (names.len() > 0)
    saveSeenQuests(names)
}

function secondsToHoursMinutes(sec) {
  let { days, hours, minutes } = secondsToTime(max(0, sec) + 59)
  return format("%02d:%02d", days * 24 + hours, minutes)
}

let unlockTimeText = @() {
  watch = [serverTime, clanQuestsUnlockTime]
  children = mkTimeUntil(secondsToHoursMinutes(clanQuestsUnlockTime.get() - serverTime.get()),
    "clan/quests/availableIn", fontMedium)
}

let lockOverlay = @() {
  watch = isClanQuestsLocked
  size = FLEX
  children = !isClanQuestsLocked.get() ? null
    : {
        size = FLEX
        rendObj = ROBJ_SOLID
        color = lockedBgColor
        stopMouse = true
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = unlockTimeText
      }
}

function mkClanQuestsPage() {
  let scrollHandler = ScrollHandler()
  let listContent = [
    mkListPannable(mkQuestsList(clanQuestsSorted, mkQuest, curSectionId, markQuestsSeen),
      {},
      { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
    mkScrollArrow(scrollHandler, MR_B, scrollArrowImageSmall)
  ]
  let questsList = [
    @() {
      watch = isClanQuestsLocked
      size = FLEX
      disableInput = isClanQuestsLocked.get()
      children = listContent
    }
    lockOverlay
  ]
  return {
    size = FLEX
    flow = FLOW_VERTICAL
    gap = pageBlocksGap
    children = [
      mkClanProgressBlock()
      @() {
        watch = hasQuests
        size = FLEX
        children = hasQuests.get() ? questsList : allQuestsCompleted
      }
    ]
  }
}

return mkClanQuestsPage
