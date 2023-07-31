from "%globalsDarg/darg_library.nut" import *
let { subscribe, send } = require("eventbus")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { benchmarkGameModes } = require("%rGui/gameModes/gameModeState.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { closeButton } = require("%rGui/components/debugWnd.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")

let wndUid = "chooseBenchmark"
let close = @() removeModalWindow(wndUid)

let gap = hdpx(10)

let benchmarksList = Watched([])
subscribe("benchmarksList", @(msg) benchmarksList(msg.benchmarks))

let function byRows(list) {
  if (list.len() == 0)
    return null
  let rows = arrayByRows(list, 2)
  if (rows.top().len() < 2)
    rows.top().resize(2, { size = flex() })
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap
    children = rows.map(@(children) {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap
      children
    })
  }
}

let btnStyle = { ovr = { size = [flex(), hdpx(100)] } }
let function missionsListUi() {
  let children = [byRows(benchmarksList.value.map(@(b)
    textButtonCommon(
      b.name,
      function() {
        close()
        send("startBenchmark", { id = b.id })
      },
      btnStyle)))
  ]
  if (benchmarkGameModes.value.len() > 0)
    children.append(
      {
        margin = [hdpx(10), 0, 0, 0]
        rendObj = ROBJ_TEXT
        text = loc("chapters/onlineBenchmark")
      }.__update(fontSmall),
      byRows(benchmarkGameModes.value.values()
        .sort(@(a, b) a <=> b)
        .map(@(gm) textButtonCommon(
          loc($"gameMode/{gm.name}", gm.name),
          function() {
            close()
            send("queueToGameMode", { modeId = gm?.gameModeId })
          },
          btnStyle)))
    )
  return {
    watch = [benchmarksList, benchmarkGameModes]
    size = [flex(), SIZE_TO_CONTENT]
    padding = gap
    gap
    flow = FLOW_VERTICAL
    children
  }
}

return @() addModalWindow({
  key = wndUid
  hotkeys = [["Esc", { action = close }]]
  size = flex()
  onAttach = @() send("getBenchmarksList", {})
  children = {
    size = [hdpx(1300), SIZE_TO_CONTENT]
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = Color(30, 30, 30, 240)
    flow = FLOW_VERTICAL
    stopMouse = true
    stopHotkeys = true
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
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