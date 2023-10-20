from "%globalsDarg/darg_library.nut" import *
let { mkOfferWrap, mkOfferTexts, mkBgImg } = require("%rGui/shop/goodsView/sharedParts.nut")
let { openEventWnd, eventEndsAt, eventSeason, eventSeasonName, unseenLootboxes, unseenLootboxesShowOnce,
  eventWndShowAnimation } = require("eventState.nut")
let { isEventActive } = require("%rGui/quests/questsState.nut")
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

let eventBanner = @() {
  watch = [isEventActive, eventEndsAt, eventSeason, eventSeasonName]
  children = !isEventActive.value ? null
    : [
        mkOfferWrap(onClick,
          @(sf) [
            mkBgImg($"ui/gameuiskin#banner_event_{eventSeason.value}.avif:0:P", "ui/gameuiskin#offer_bg_blue.avif:0:P")
            sf & S_HOVER ? bgHiglight : null
            mkOfferTexts(eventSeasonName.value, eventEndsAt.value)
          ])
        @() {
          watch = [unseenLootboxes, unseenLootboxesShowOnce]
          margin = hdpx(10)
          children = unseenLootboxes.value.len() > 0 || unseenLootboxesShowOnce.value.findindex(@(v) v) != null
              ? priorityUnseenMark
            : null
        }
      ]
}

return eventBanner
