from "%globalsDarg/darg_library.nut" import *
let { translucentButton, translucentButtonsVGap } = require("%rGui/components/translucentButton.nut")
let { specialEventsLootboxesState, specialEvents, orderEvents, shouldShowEventMechanics
} = require("%rGui/event/eventState.nut")
let { openSeasonScene, LOOTBOX_TAB, QUESTS_TAB } = require("%rGui/seasonScene/seasonSceneState.nut")
let mkSeasonSceneUnseenMark = require("%rGui/seasonScene/mkSeasonSceneUnseenMark.nut")
let { gmEventsList, openGmEventWnd, hasFinishedFirstBattle, canOpenGmEventWnd } = require("%rGui/event/gmEventState.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { tabIdToOpen } = require("%rGui/quests/questsState.nut")

function mkUnseenWithSf(eventId) {
  let mark = mkSeasonSceneUnseenMark(eventId, { hplace = ALIGN_RIGHT, vplace = ALIGN_TOP })
  return @(_) mark
}

function btnsOpenSpecialEvents() {
  let children = []
  if (shouldShowEventMechanics.get()) {
    orderEvents(specialEventsLootboxesState.get().withLootboxes).each(@(evt)
      children.append(translucentButton(getEventPresentation(evt.eventName).icon,
        @() openSeasonScene(evt.eventId, LOOTBOX_TAB),
        null,
        mkUnseenWithSf(evt.eventId))))

    orderEvents(specialEventsLootboxesState.get().withoutLootboxes).each(@(evt)
      children.append(translucentButton(getEventPresentation(evt.eventName).icon,
        function onClick() {
          let globalEventId = specialEvents.get().findindex(@(s) s.eventName == evt.eventName) ?? evt.eventId
          tabIdToOpen.set(globalEventId)
          openSeasonScene(evt.eventName, QUESTS_TAB)
        },
        null,
        mkUnseenWithSf(evt.eventId),
        { iconMul = getEventPresentation(evt.eventName).imageSizeMul }
      )))

    gmEventsList.get().keys().each(function(id) {
      if (canOpenGmEventWnd(id, hasFinishedFirstBattle.get()))
        children.append(translucentButton(getEventPresentation(id).icon, @() openGmEventWnd(id)))
    })
  }

  return {
    watch = [specialEventsLootboxesState, gmEventsList, hasFinishedFirstBattle, specialEvents, shouldShowEventMechanics]
    flow = FLOW_HORIZONTAL
    gap = translucentButtonsVGap
    children
  }
}


return btnsOpenSpecialEvents
