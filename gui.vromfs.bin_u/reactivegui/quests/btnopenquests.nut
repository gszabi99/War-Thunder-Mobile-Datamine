from "%globalsDarg/darg_library.nut" import *
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { openQuestsWnd } = require("%rGui/quests/questsState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { hasUnseenQuestsBySection, questsBySection, progressUnlock } = require("questsState.nut")

let statusMark = @(_) @() {
  watch = [hasUnseenQuestsBySection, progressUnlock]
  hplace = ALIGN_RIGHT
  pos = [hdpx(4), hdpx(-4)]
  children = hasUnseenQuestsBySection.value.findindex(@(v) v) == null && !progressUnlock.value?.hasReward ? null
    : priorityUnseenMark
}

let btnOpenQuests = @() {
  watch = questsBySection
  children = questsBySection.value.findindex(@(s) s.len() > 0) == null ? null
    : translucentButton("ui/gameuiskin#quests.svg",
        loc("mainmenu/btnQuests"),
        openQuestsWnd,
        statusMark)
}

return btnOpenQuests
