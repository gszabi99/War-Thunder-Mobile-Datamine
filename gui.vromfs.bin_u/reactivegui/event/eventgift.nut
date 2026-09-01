from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_send
from "%sqstd/platform.nut" import is_ios
from "%appGlobals/config/eventsGiftPresentation.nut" import getGiftPresentation, availableGifts
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/permissions.nut" import allow_event_gift_on_ios
from "%rGui/event/eventState.nut" import specialEvents
from "%rGui/shop/goodsView/sharedParts.nut" import offerH


const eventGiftGap = hdpx(25)
let boxSize = [offerH, offerH]
let tagSize = [hdpxi(50), hdpxi(50)]
let campaignGiftImg = {
  tanks = "event_christmas_gift_tag_tanks"
  air = "event_christmas_gift_tag_planes"
  ships = "event_christmas_gift_tag_ships"
}

function mkGiftBtn(eventId) {
  let stateFlags = Watched(0)
  let gift = getGiftPresentation(eventId)
  return @() {
    watch = stateFlags
    size = boxSize
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick = @() eventbus_send("openUrl", { baseUrl = gift?.link ?? "" })
    children = [
      {
        size = FLEX
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#{gift?.icon}:{boxSize[0]}:{boxSize[1]}:P")
        keepAspect = KEEP_ASPECT_FIT
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
      }
      @() {
        watch = curCampaign
        size = tagSize
        pos = const [-hdpx(10), hdpx(25)]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#{campaignGiftImg[curCampaign.get()]}.avif:{tagSize[0]}:{tagSize[1]}:P")
        keepAspect = KEEP_ASPECT_FIT
      }
      {
        size = [boxSize[0] + 2 * eventGiftGap, SIZE_TO_CONTENT]
        behavior = Behaviors.TextArea
        halign = ALIGN_CENTER
        hplace = ALIGN_CENTER
        vplace = ALIGN_BOTTOM
        rendObj = ROBJ_TEXTAREA
        text = loc(gift?.locId ?? "")
      }.__update(fontTinyAccentedShaded)
    ]
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
  }
}

function eventGift() {
  let eventId = specialEvents.get().findvalue(@(e) e.eventName in availableGifts)?.eventName
  let canShow = !is_ios || allow_event_gift_on_ios.get()
  return {
    watch = [specialEvents, allow_event_gift_on_ios]
    children = eventId == null || !canShow ? null
      : mkGiftBtn(eventId)
    }
}

return {
  eventGift
  eventGiftGap
}