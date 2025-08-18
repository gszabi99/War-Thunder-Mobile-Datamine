from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { benchmarkGameModes } = require("%rGui/gameModes/gameModeState.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { closeButton } = require("%rGui/components/debugWnd.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")

let wndUid = "chooseBenchmark"
let close = @() removeModalWindow(wndUid)

let gap = hdpx(10)

let benchmarksList = Watched([])
eventbus_subscribe("benchmarksList", @(msg) benchmarksList.set(msg.benchmarks))

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

let btnStyle = { ovr = { size = const [flex(), hdpx(100)] } }
function missionsListUi() {
  let children = [byRows(benchmarksList.get().map(@(b)
    textButtonCommon(
      b.name,
      function() {
        close()
        eventbus_send("startBenchmark", { id = b.id })
      },
      btnStyle)))
  ]
  if (benchmarkGameModes.get().len() > 0)
    children.append(
      {
        margin = const [hdpx(10), 0, 0, 0]
        rendObj = ROBJ_TEXT
        text = loc("chapters/onlineBenchmark")
      }.__update(fontSmall),
      byRows(benchmarkGameModes.get().values()
        .sort(@(a, b) a.gameModeId <=> b.gameModeId)
        .map(@(gm) textButtonCommon(
          loc($"gameMode/{gm.name}", gm.name),
          function() {
            close()
            eventbus_send("queueToGameMode", { modeId = gm?.gameModeId })
          },
          btnStyle)))
    )
  return {
    watch = [benchmarksList, benchmarkGameModes]
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
  onAttach = @() eventbus_send("getBenchmarksList", {})
  children = {
    size = const [hdpx(1300), SIZE_TO_CONTENT]
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
            text = loc("mainmenu/btnBenchmark")
          }.__update(fontSmall)
          { size = flex() }
          closeButton(close)
        ]
      }
      missionsListUi
    ]
  }
})