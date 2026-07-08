from "%globalsDarg/darg_library.nut" import *
let { translucentButton, translucentButtonsVGap } = require("%rGui/components/translucentButton.nut")
let { specialEventsLootboxesState, specialEvents, unseenLootboxes, unseenLootboxesShowOnce, orderEvents,
  shouldShowEventMechanics } = require("%rGui/event/eventState.nut")
let { openSeasonScene, LOOTBOX_TAB, QUESTS_TAB } = require("%rGui/seasonScene/seasonSceneState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { gmEventsList, openGmEventWnd, hasFinishedFirstBattle, canOpenGmEventWnd } = require("%rGui/event/gmEventState.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { curTabId, questsCfg, progressUnlockByTab, progressUnlockBySection,
  hasUnseenQuestsBySection
} = require("%rGui/quests/questsState.nut")
let { addUnlocksUpdater, removeUnlocksUpdater } = require("%rGui/unlocks/userstat.nut")


function statusMark(eventId) {
  let key = $"eventStatus_{eventId}"
  return @() {
    watch = [hasUnseenQuestsBySection, progressUnlockByTab, progressUnlockBySection]
    key
    onAttach = @() addUnlocksUpdater(key)
    onDetach = @() removeUnlocksUpdater(key)
    hplace = ALIGN_RIGHT
    vplace = ALIGN_TOP
    children = progressUnlockByTab.get()?[eventId].hasReward
        || questsCfg.get()?[eventId].findvalue(@(s) !!hasUnseenQuestsBySection.get()?[s]
          || !!progressUnlockBySection.get()?[s].hasReward) != null
      ? priorityUnseenMark
      : null
  }
}

function btnsOpenSpecialEvents() {
  let children = []
  if (shouldShowEventMechanics.get())
    orderEvents(specialEventsLootboxesState.get().withLootboxes).each(@(evt)
      children.append(translucentButton(getEventPresentation(evt.eventName).icon,
        @() openSeasonScene(LOOTBOX_TAB, null, evt.eventId),
        null,
        @(_) @() {
          watch = [unseenLootboxes, unseenLootboxesShowOnce]
          hplace = ALIGN_RIGHT
          vplace = ALIGN_TOP
          children = (unseenLootboxes.get()?[evt.eventName].len() ?? 0) > 0
            || unseenLootboxesShowOnce.get().findindex(@(l) l == evt.eventName) != null
                ? priorityUnseenMark
              : null
        },
        { iconMul = getEventPresentation(evt.eventName).imageSizeMul }
      )))
  orderEvents(specialEventsLootboxesState.get().withoutLootboxes).each(@(evt)
    children.append(translucentButton(getEventPresentation(evt.eventName).icon,
      function onClick() {
        let globalEventId = specialEvents.get().findindex(@(s) s.eventName == evt.eventName) ?? evt.eventId
        curTabId.set(globalEventId)
        openSeasonScene(QUESTS_TAB)
      },
      null,
      @(_) statusMark(evt.eventId),
      { iconMul = getEventPresentation(evt.eventName).imageSizeMul }
    )))
  if (shouldShowEventMechanics.get())
    gmEventsList.get().keys().each(function(id) {
      if (canOpenGmEventWnd(id, hasFinishedFirstBattle.get()))
        children.append(translucentButton(getEventPresentation(id).icon, @() openGmEventWnd(id)))
    })

  return {
    watch = [specialEventsLootboxesState, gmEventsList, hasFinishedFirstBattle, specialEvents, shouldShowEventMechanics]
    flow = FLOW_HORIZONTAL
    gap = translucentButtonsVGap
    children
  }
}


return btnsOpenSpecialEvents
