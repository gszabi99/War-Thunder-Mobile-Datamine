from "%globalsDarg/darg_library.nut" import *
let { mkOfferWrap, mkOfferTexts, mkBgImg } = require("%rGui/shop/goodsView/sharedParts.nut")
let { openEventWnd, eventEndsAt, eventSeason, eventSeasonName, unseenLootboxes, unseenLootboxesShowOnce,
  eventWndShowAnimation, isEventActive } = require("eventState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")


let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x01261E10
}

let function onClick() {
  eventWndShowAnimation(true)
  openEventWnd()
}


let markH = hdpxi(60)
let markTexOffs = [ 0, markH / 2, 0, 0 ]
let eventBanner = @() {
  watch = [isEventActive, eventEndsAt, eventSeason, eventSeasonName]
  children = !isEventActive.value ? null
    : [
        mkOfferWrap(onClick,
          @(sf) [
            mkBgImg($"ui/gameuiskin#banner_event_{eventSeason.value}.avif:0:P", "ui/gameuiskin#offer_bg_blue.avif:0:P")
            sf & S_HOVER ? bgHiglight : null
            mkOfferTexts(eventSeasonName.value, eventEndsAt.value)
          ],
          null,
          false)
        {
          size = [SIZE_TO_CONTENT, markH]
          rendObj = ROBJ_9RECT
          image = Picture($"ui/gameuiskin#tag_popular.svg:{markH}:{markH}:P")
          keepAspect = KEEP_ASPECT_NONE
          screenOffs = markTexOffs
          texOffs = markTexOffs
          color = 0x500C7EFF
          children = {
              margin = [0, hdpx(30), 0, hdpx(20)]
              rendObj = ROBJ_TEXT
              text = loc("mainmenu/event")
              vplace = ALIGN_CENTER
            }.__update(fontTinyAccentedShaded)
        }
        @() {
          watch = [unseenLootboxes, unseenLootboxesShowOnce]
          margin = hdpx(10)
          vplace = ALIGN_BOTTOM
          children = unseenLootboxes.value.len() > 0 || unseenLootboxesShowOnce.value.findindex(@(v) v) != null
              ? priorityUnseenMark
            : null
        }
      ]
}

return eventBanner
