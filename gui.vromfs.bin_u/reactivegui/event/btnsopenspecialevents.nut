from "%globalsDarg/darg_library.nut" import *
let { getOPPresentation } = require("%appGlobals/config/passPresentation.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { translucentButton, translucentButtonsVGap } = require("%rGui/components/translucentButton.nut")
let { specialEventsLootboxesState, specialEvents, orderEvents, subEventsList
} = require("%rGui/event/eventState.nut")
let shouldShowEventMechanics = require("%rGui/event/shouldShowEventMechanics.nut")
let { openSeasonScene, openEventShopWnd, openGmEventWnd } = require("%rGui/seasonScene/seasonSceneState.nut")
let mkSeasonSceneUnseenMark = require("%rGui/seasonScene/mkSeasonSceneUnseenMark.nut")
let { goodsByShop, soonGoodsByShop, soonPersonalGoodsByShop, personalGoodsByShop } = require("%rGui/shop/shopState.nut")
let { gmEventsList } = require("%rGui/event/gmEventState.nut")
let { getShopEventName } = require("%rGui/shop/eventShopState.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { tabIdToOpen } = require("%rGui/quests/questsState.nut")
let { OP_EVENT_ID, isOpAvailable } = require("%rGui/battlePass/operationPassState.nut")


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

    orderEvents(specialEventsLootboxesState.get().withLootboxes).each(function(evt) {
      if (evt.eventId in subEventsList.get())
        return
      usedEvents[evt.eventName] <- true
      children.append(translucentButton(getEventPresentation(evt.eventName).icon,
        @() openSeasonScene(evt.eventId),
        null,
        mkUnseenWithSf(evt.eventId)))
    })

    orderEvents(specialEventsLootboxesState.get().withoutLootboxes).each(function(evt) {
      if (evt.eventId in subEventsList.get())
        return
      usedEvents[evt.eventName] <- true
      children.append(translucentButton(getEventPresentation(evt.eventName).icon,
        function onClick() {
          let globalEventId = specialEvents.get().findindex(@(s) s.eventName == evt.eventName) ?? evt.eventId
          tabIdToOpen.set(globalEventId)
          openSeasonScene(evt.eventName)
        },
        null,
        mkUnseenWithSf(evt.eventId),
        { iconMul = getEventPresentation(evt.eventName).imageSizeMul }
      ))
    })

    gmEventsList.get().keys().each(function(id) {
      usedEvents[id] <- true
      children.append(translucentButton(getEventPresentation(id).icon, @() openGmEventWnd(id)))
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
          mkUnseenWithSf(eventName)))
      }
    }
  }

  return {
    watch = [ specialEventsLootboxesState, gmEventsList, specialEvents,
      shouldShowEventMechanics, isOpAvailable, curCampaign, goodsByShop, soonGoodsByShop, soonPersonalGoodsByShop,
      personalGoodsByShop, subEventsList
    ]
    flow = FLOW_HORIZONTAL
    gap = translucentButtonsVGap
    children
  }
}


return btnsOpenSpecialEvents
