from "%globalsDarg/darg_library.nut" import *
let { translucentButton, translucentButtonsVGap } = require("%rGui/components/translucentButton.nut")
let { openEventWnd, specialEventsLootboxesState, unseenLootboxes, unseenLootboxesShowOnce } = require("%rGui/event/eventState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { gmEventsList, openGmEventWnd, hasFinishedFirstBattle, canOpenGmEventWnd } = require("%rGui/event/gmEventState.nut")
let gmEventPresentation = require("%appGlobals/config/gmEventPresentation.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { openQuestsWndOnTab, questsCfg, progressUnlockByTab, progressUnlockBySection,
  hasUnseenQuestsBySection } = require("%rGui/quests/questsState.nut")


let statusMark = @(eventId) @() {
  watch = [hasUnseenQuestsBySection, progressUnlockByTab, progressUnlockBySection]
  hplace = ALIGN_RIGHT
  pos = [hdpx(4), hdpx(-4)]
  children = progressUnlockByTab.get()?[eventId].hasReward
      || questsCfg.get()?[eventId].findvalue(@(s) !!hasUnseenQuestsBySection.get()?[s]
        || !!progressUnlockBySection.get()?[s].hasReward) != null
    ? priorityUnseenMark
    : null
}

function btnsOpenSpecialEvents() {
  let children = []
  specialEventsLootboxesState.get().withLootboxes.each(@(evt)
    children.append(translucentButton(getEventPresentation(evt.eventName).icon,
      "",
      @() openEventWnd(evt.eventId),
      @(_) @() {
        watch = [unseenLootboxes, unseenLootboxesShowOnce]
        hplace = ALIGN_RIGHT
        pos = [hdpx(4), hdpx(-4)]
        children = (unseenLootboxes.get()?[evt.eventName].len() ?? 0) > 0
          || unseenLootboxesShowOnce.get().findindex(@(l) l == evt.eventName) != null
              ? priorityUnseenMark
            : null
      },
      { iconMul = getEventPresentation(evt.eventName).imageSizeMul }
    )))
  specialEventsLootboxesState.get().withoutLootboxes.each(@(evt)
    children.append(translucentButton(getEventPresentation(evt.eventName).icon,
      "",
      @() openQuestsWndOnTab(evt.eventId)
      @(_) statusMark(evt.eventId)
      { iconMul = getEventPresentation(evt.eventName).imageSizeMul }
    )))
  gmEventsList.get().keys().each(function(id) {
    if (canOpenGmEventWnd(id, hasFinishedFirstBattle.get()))
      children.append(translucentButton(gmEventPresentation(id).image,
      "",
      @() openGmEventWnd(id)))
  })

  return {
    watch = [specialEventsLootboxesState, gmEventsList, hasFinishedFirstBattle]
    flow = FLOW_HORIZONTAL
    gap = translucentButtonsVGap
    children
  }
}


return btnsOpenSpecialEvents
