from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { SEND_GIFT_URL } = require("%appGlobals/commonUrl.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { specialEvents } = require("eventState.nut")
let { offerH } = require("%rGui/shop/goodsView/sharedParts.nut")


let eventGiftGap = hdpx(25)
let boxSize = [offerH, offerH]
let tagSize = [hdpxi(50), hdpxi(50)]
let campaignGiftImg = {
  tanks = "event_christmas_gift_tag_tanks"
  air = "event_christmas_gift_tag_planes"
  ships = "event_christmas_gift_tag_ships"
}

function mkGiftBtn() {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = boxSize
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick = @() eventbus_send("openUrl", { baseUrl = SEND_GIFT_URL })
    children = [
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#event_christmas_gift_box.avif:{boxSize[0]}:{boxSize[1]}:P")
        keepAspect = KEEP_ASPECT_FIT
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
      }
      @() {
        watch = curCampaign
        size = tagSize
        pos = [-hdpx(10), hdpx(25)]
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
        text = loc("mainmenu/btnSendGift")
      }.__update(fontTinyAccentedShaded)
    ]
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
  }
}

let eventGift = @() {
  watch = specialEvents
  children = specialEvents.get().findvalue(@(e) e.eventName == "event_new_year") == null ? null
    : mkGiftBtn()
}

return {
  eventGift
  eventGiftGap
}