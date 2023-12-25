from "%globalsDarg/darg_library.nut" import *
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { openEventWnd, specialEvents, unseenLootboxes, unseenLootboxesShowOnce } = require("%rGui/event/eventState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")


let btnsOpenSpecialEvents = @() {
  watch = specialEvents
  flow = FLOW_HORIZONTAL
  gap = hdpx(30)
  children = specialEvents.value.values().map(@(v)
    translucentButton($"ui/gameuiskin#icon_event_{v.eventName}.svg",
      "",
      @() openEventWnd(v.eventId),
      @(_) @() {
        watch = [unseenLootboxes, unseenLootboxesShowOnce]
        hplace = ALIGN_RIGHT
        pos = [hdpx(4), hdpx(-4)]
        children = (unseenLootboxes.get()?[v.eventName].len() ?? 0) > 0
          || unseenLootboxesShowOnce.value.findindex(@(l) l == v.eventName) != null
              ? priorityUnseenMark
            : null
      }
    ))
}


return btnsOpenSpecialEvents
