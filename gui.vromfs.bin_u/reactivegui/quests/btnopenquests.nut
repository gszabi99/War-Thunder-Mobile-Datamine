from "%globalsDarg/darg_library.nut" import *
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { hasUnseenQuestsBySection, questsBySection, progressUnlockByTab, progressUnlockBySection,
  questsCfg, openQuestsWnd, openQuestsWndOnTab, tutorialQuestBtnKey
} = require("%rGui/quests/questsState.nut")
let { addUnlocksUpdater, removeUnlocksUpdater } = require("%rGui/unlocks/userstat.nut")

let statusKey = "btnOpenQuestsStatus"
let statusMark = @(_) @() {
  watch = [hasUnseenQuestsBySection, progressUnlockByTab, progressUnlockBySection]
  key = statusKey
  onAttach = @() addUnlocksUpdater(statusKey)
  onDetach = @() removeUnlocksUpdater(statusKey)
  hplace = ALIGN_RIGHT
  pos = [hdpx(4), hdpx(-4)]
  children = hasUnseenQuestsBySection.get().findindex(@(v) v) != null
      || progressUnlockByTab.get().findvalue(@(u) !!u?.hasReward) != null
      || progressUnlockBySection.get().findvalue(@(u) !!u?.hasReward) != null
    ? priorityUnseenMark
    : null
}

function btnOpenQuests(keyPostfix) {
  let key = $"quest_wnd_btn_{keyPostfix}" 
  return @() {
    watch = questsBySection
    children = questsBySection.get().findindex(@(s) s.len() > 0) == null ? null
      : translucentButton("ui/gameuiskin#quests.svg",
          "",
          openQuestsWnd,
          statusMark,
          {
            key,
            onAttach = @() tutorialQuestBtnKey.set(key),
            onDetach = @() tutorialQuestBtnKey.set(null)
          })
  }
}

function mkBtnOpenTabQuests(tabId, ovr = {}) {
  let sections = Computed(@() questsCfg.get()?[tabId] ?? [])
  let key = $"btnOpenTabQuests_{tabId}"
  let status = @() {
    watch = [sections, hasUnseenQuestsBySection, progressUnlockByTab, progressUnlockBySection]
    key
    onAttach = @() addUnlocksUpdater(key)
    onDetach = @() removeUnlocksUpdater(key)
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
