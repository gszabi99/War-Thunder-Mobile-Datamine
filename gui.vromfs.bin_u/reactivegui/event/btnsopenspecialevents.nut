from "%globalsDarg/darg_library.nut" import *
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { openEventWnd, specialEventsWithLootboxes, unseenLootboxes, unseenLootboxesShowOnce } = require("%rGui/event/eventState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { gmEventsList, openGmEventWnd } = require("%rGui/event/gmEventState.nut")
let gmEventPresentation = require("%appGlobals/config/gmEventPresentation.nut")


function btnsOpenSpecialEvents() {
  let children = []
  specialEventsWithLootboxes.get().each(@(evt)
    children.append(translucentButton($"ui/gameuiskin#icon_event_{evt.eventName}.svg",
      "",
      @() openEventWnd(evt.eventId),
      @(_) @() {
        watch = [unseenLootboxes, unseenLootboxesShowOnce]
        hplace = ALIGN_RIGHT
        pos = [hdpx(4), hdpx(-4)]
        children = (unseenLootboxes.get()?[evt.eventName].len() ?? 0) > 0
          || unseenLootboxesShowOnce.value.findindex(@(l) l == evt.eventName) != null
              ? priorityUnseenMark
            : null
      }
    )))
  gmEventsList.get().each(@(id)
    children.append(translucentButton(gmEventPresentation(id).image,
      "",
      @() openGmEventWnd(id))))

  return {
    watch = specialEventsWithLootboxes
    flow = FLOW_HORIZONTAL
    gap = hdpx(30)
    children
  }
}


return btnsOpenSpecialEvents
