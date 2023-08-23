from "%globalsDarg/darg_library.nut" import *
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { openQuestsWnd } = require("%rGui/quests/questsState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { hasUnseenQuestsBySection, questsBySection } = require("questsState.nut")

let statusMark = @(_) @() {
  watch = hasUnseenQuestsBySection
  hplace = ALIGN_RIGHT
  margin = hdpx(4)
  children = hasUnseenQuestsBySection.value.findindex(@(v) v) == null ? null
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
