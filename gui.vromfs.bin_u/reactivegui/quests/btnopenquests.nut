from "%globalsDarg/darg_library.nut" import *
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { hasUnseenQuestsBySection, questsBySection, progressUnlockByTab, progressUnlockBySection,
  questsCfg, openQuestsWnd, openQuestsWndOnTab
} = require("questsState.nut")

let statusMark = @(_) @() {
  watch = [hasUnseenQuestsBySection, progressUnlockByTab, progressUnlockBySection]
  hplace = ALIGN_RIGHT
  pos = [hdpx(4), hdpx(-4)]
  children = hasUnseenQuestsBySection.get().findindex(@(v) v) != null
      || progressUnlockByTab.get().findvalue(@(u) !!u?.hasReward) != null
      || progressUnlockBySection.get().findvalue(@(u) !!u?.hasReward) != null
    ? priorityUnseenMark
    : null
}

let btnOpenQuests = @() {
  watch = questsBySection
  children = questsBySection.get().findindex(@(s) s.len() > 0) == null ? null
    : translucentButton("ui/gameuiskin#quests.svg",
        "",
        openQuestsWnd,
        statusMark,
        { key = "quest_wnd_btn" }) 
}

function mkBtnOpenTabQuests(tabId, ovr = {}) {
  let sections = Computed(@() questsCfg.get()?[tabId] ?? [])
  let status = @() {
    watch = [sections, hasUnseenQuestsBySection, progressUnlockByTab, progressUnlockBySection]
    hplace = ALIGN_RIGHT
    pos = [hdpx(4), hdpx(-4)]
    children = (progressUnlockByTab.get()?[tabId]?.hasReward ?? false)
        || null != sections.get().findvalue(@(s) !!hasUnseenQuestsBySection.get()?[s]
            || !!progressUnlockBySection.get()?[s].hasReward)
      ? priorityUnseenMark
      : null
  }
  return @() {
    watch = questsBySection
    children = questsBySection.get().findindex(@(s) s.len() > 0) == null ? null
      : translucentButton("ui/gameuiskin#quests.svg",
          "",
          @() openQuestsWndOnTab(tabId),
          @(_) status,
          ovr)
  }
}

return {
  btnOpenQuests
  mkBtnOpenTabQuests
}
