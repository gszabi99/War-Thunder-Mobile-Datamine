from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe, eventbus_send
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/underscore.nut" import arrayByRows
from "%appGlobals/updater/missionUnits.nut" import getMissionUnitsAndAddons
from "%rGui/components/debugWnd.nut" import closeButton
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/textButton.nut" import textButtonCommon
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/gameModes/gameModeState.nut" import benchmarkGameModes
from "%rGui/updater/updaterState.nut" import openDownloadAddonsWnd


const wndUid = "chooseBenchmark"
let close = @() removeModalWindow(wndUid)

const gap = hdpx(10)

let benchmarksList = Watched([])
eventbus_subscribe("benchmarksList", @(msg) benchmarksList.set(msg.benchmarks))

function byRows(list) {
  if (list.len() == 0)
    return null
  let rows = arrayByRows(list, 2)
  if (rows.top().len() < 2)
    rows.top().resize(2, { size = FLEX })
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

let btnStyle = { ovr = { size = const [FLEX, hdpx(100)] } }
function missionsListUi() {
  let children = [byRows(benchmarksList.get().map(@(b)
    textButtonCommon(
      utf8ToUpper(b.name),
      function() {
        close()
        log("[BENCHMARK] openDownloadAddonsWnd offline benchmark")
        let { misUnits, misAddons } = getMissionUnitsAndAddons(b.id)
        openDownloadAddonsWnd(misAddons.keys(), misUnits.keys(),
          "startBenchmark", { paramStr1 = b.id },
          "startBenchmark", { id = b.id })
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
          utf8ToUpper(loc($"gameMode/{gm.name}", gm.name)),
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
  size = FLEX
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
          { size = FLEX }
          closeButton(close)
        ]
      }
      missionsListUi
    ]
  }
})