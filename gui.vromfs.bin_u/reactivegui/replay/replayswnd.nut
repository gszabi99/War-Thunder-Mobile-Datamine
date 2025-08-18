from "%globalsDarg/darg_library.nut" import *
let { on_view_replay, get_replays_list } = require("replays")
let { format } =  require("string")
let { can_write_replays } = require("%appGlobals/permissions.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { closeButton } = require("%rGui/components/debugWnd.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")

let wndUid = "replaysWnd"
let close = @() removeModalWindow(wndUid)

let gap = hdpx(10)
let wndWidth = hdpx(1300)

function byRows(list) {
  if (list.len() == 0)
    return null
  let rows = arrayByRows(list, 2)
  if (rows.top().len() < 2)
    rows.top().resize(2, { size = flex() })
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap
    children = rows.map(@(children) {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap
      children
    })
  }
}

let replaySort = @(a, b) b.startTime <=> a.startTime || b.name <=> a.name

let headerText = @(text) {
  size = FLEX_H
  margin = const [hdpx(10), 0, 0, 0]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color = 0xFFC0C0C0
}.__update(fontTiny)

let invalidReplaysList = @(replays) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = ", ".join(replays.map(@(r) r.name))
}.__update(fontTiny)

function getReplayDescription(r) {
  let { year, month, day, hour, sec } = r.dateTime
  let minute = r.dateTime.min
  return format("%d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, minute, sec)
}

function replaysList() {
  let replays = get_replays_list()
  let children = []

  let activeReplays = replays
    .filter(@(r) !r.isVersionMismatch && !r.corrupted)
    .sort(replaySort)
  if (activeReplays.len() > 0)
    children.append(byRows(activeReplays.map(@(r)
      textButtonCommon(
        r.name,
        function() {
          close()
          on_view_replay(r.path)
        },
        {
          ovr = { size = const [flex(), hdpx(100)] }
          tooltipCtor = @() getReplayDescription(r)
        }))))

  if (can_write_replays.get()) {
    let invalidVersionRelays = replays
      .filter(@(r) r.isVersionMismatch)
      .sort(replaySort)
    if (invalidVersionRelays.len() > 0)
      children.append(
        headerText(loc("replays/versionMismatch")),
        invalidReplaysList(invalidVersionRelays))

    let corruptedReplays = replays
      .filter(@(r) r.corrupted)
      .sort(replaySort)
    if (corruptedReplays.len() > 0)
      children.append(
        headerText(loc("replays/corrupted")),
        invalidReplaysList(corruptedReplays))
  }

  if (children.len() == 0)
    children.append(headerText(loc("mainmenu/noReplays")))

  return {
    watch = can_write_replays
    size = FLEX_H
    padding = gap
    gap
    flow = FLOW_VERTICAL
    children
  }
}

return @() addModalWindow({
  key = wndUid
  hotkeys = [[btnBEscUp, { action = close }]]
  size = flex()
  children = {
    size = [wndWidth, SIZE_TO_CONTENT]
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = Color(30, 30, 30, 240)
    flow = FLOW_VERTICAL
    stopMouse = true
    stopHotkeys = true
    children = [
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        padding = gap
        children = [
          {
            rendObj = ROBJ_TEXT
            text = loc("mainmenu/btnReplays")
          }.__update(fontSmall)
          { size = flex() }
          closeButton(close)
        ]
      }
      makeVertScroll(
        replaysList,
        {
          size = FLEX_H
          maxHeight = hdpx(900)
          rootBase = { behavior = Behaviors.Pannable }
        })
    ]
  }
})