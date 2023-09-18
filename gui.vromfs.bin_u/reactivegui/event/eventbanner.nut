from "%globalsDarg/darg_library.nut" import *
let { mkOfferWrap, mkOfferTexts, mkBgImg } = require("%rGui/shop/goodsView/sharedParts.nut")
let { openEventWnd } = require("eventState.nut")
let { getLootboxImage } = require("%rGui/unlocks/rewardsView/lootboxPresentation.nut")
let { isEventActive } = require("%rGui/quests/questsState.nut")

let lootboxSize = hdpx(200)

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x01261E10
}

// TODO: add unseen mark, timer

let eventBanner = @() {
  watch = isEventActive
  children = !isEventActive.value ? null
    : mkOfferWrap(openEventWnd,
        @(sf) [
          mkBgImg("ui/gameuiskin#banner_event_01.avif:O:P")
          sf & S_HOVER ? bgHiglight : null
          {
            size = [lootboxSize, lootboxSize]
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            rendObj = ROBJ_IMAGE
            keepAspect = true
            image = getLootboxImage("event_big", lootboxSize)
          }
          mkOfferTexts(loc("event/banner"), 0)
        ])
}

return eventBanner
