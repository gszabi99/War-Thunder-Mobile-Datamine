from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%appGlobals/config/passPresentation.nut" import getOPPresentation
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%rGui/battlePass/operationPassState.nut" import OP_EVENT_ID, isOpAvailable
from "%rGui/components/translucentButton.nut" import translucentButton, translucentButtonsVGap
from "%rGui/event/eventState.nut" import specialEventsLootboxesState, specialEventsOrdered, subEventsList
from "%rGui/event/gmEventState.nut" import gmEventsList
import "%rGui/event/shouldShowEventMechanics.nut" as shouldShowEventMechanics
from "%rGui/quests/questsState.nut" import tabIdToOpen
import "%rGui/seasonScene/mkSeasonSceneUnseenMark.nut" as mkSeasonSceneUnseenMark
from "%rGui/seasonScene/seasonSceneState.nut" import openSeasonScene, openEventShopWnd, BATTLE_TAB
from "%rGui/shop/eventShopState.nut" import getShopEventName
from "%rGui/shop/shopState.nut" import goodsByShop, soonGoodsByShop, soonPersonalGoodsByShop, personalGoodsByShop


function mkUnseenWithSf(eventId) {
  let mark = mkSeasonSceneUnseenMark(eventId, { hplace = ALIGN_RIGHT, vplace = ALIGN_TOP })
  return @(_) mark
}

function btnsOpenSpecialEvents() {
  let children = []
  let usedEvents = {}
  if (shouldShowEventMechanics.get()) {
    if (isOpAvailable.get()) {
      usedEvents[OP_EVENT_ID] <- true
      children.append(translucentButton(getOPPresentation(curCampaign.get()).iconTab,
        @() openSeasonScene(OP_EVENT_ID),
        null,
        mkUnseenWithSf(OP_EVENT_ID)))
    }

    foreach (evt in specialEventsOrdered.get()) {
      let { eventName, eventId } = evt
      if (eventId in subEventsList.get())
        continue
      if (eventName in specialEventsLootboxesState.get().withLootboxes) {
        usedEvents[eventName] <- true
        children.append(translucentButton(getEventPresentation(eventName).icon,
          @() openSeasonScene(eventId),
          null,
          mkUnseenWithSf(eventId)))
      }
      else if (eventName in specialEventsLootboxesState.get().withoutLootboxes) {
        usedEvents[eventName] <- true
        children.append(translucentButton(getEventPresentation(eventName).icon,
          function onClick() {
            tabIdToOpen.set(eventId)
            openSeasonScene(eventName)
          },
          null,
          mkUnseenWithSf(eventId),
          { iconMul = getEventPresentation(eventName).imageSizeMul }
        ))
      }
    }

    gmEventsList.get().keys().each(function(id) {
      usedEvents[id] <- true
      let eventId = specialEventsOrdered.get().findvalue(@(s) s.eventName == id)?.eventId
      children.append(translucentButton(getEventPresentation(id).icon,
        @() openSeasonScene(id, BATTLE_TAB),
        null,
        eventId != null ? mkUnseenWithSf(eventId) : null))
    })

    
    let goodsByShopV = goodsByShop.get()
    let soonGoodsByShopV = soonGoodsByShop.get()
    let soonPersonalGoodsByShopV = soonPersonalGoodsByShop.get()
    let personalGoodsByShopV = personalGoodsByShop.get()
    foreach (shopId in ["events", "events2"]) {
      let eventName = getShopEventName(shopId, goodsByShopV, soonGoodsByShopV, soonPersonalGoodsByShopV, personalGoodsByShopV)
      if (eventName != "" && eventName not in usedEvents) {
        usedEvents[eventName] <- true
        children.append(translucentButton(getEventPresentation(eventName).icon,
          @() openEventShopWnd(eventName),
          null,
          mkUnseenWithSf(specialEventsOrdered.get().findvalue(@(s) s.eventName == eventName)?.eventId ?? eventName)))
      }
    }
  }

  return {
    watch = [ specialEventsLootboxesState, gmEventsList, specialEventsOrdered,
      shouldShowEventMechanics, isOpAvailable, curCampaign, goodsByShop, soonGoodsByShop, soonPersonalGoodsByShop,
      personalGoodsByShop, subEventsList
    ]
    flow = FLOW_HORIZONTAL
    gap = translucentButtonsVGap
    children
  }
}


return btnsOpenSpecialEvents
