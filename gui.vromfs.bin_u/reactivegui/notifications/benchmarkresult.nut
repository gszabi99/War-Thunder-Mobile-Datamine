from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { round_by_value } = require("%sqstd/math.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { mkCustomMsgBoxWnd, mkMsgBoxBtnsSet } = require("%rGui/components/msgBox.nut")

let wndUid = "benchmarkResult"
let statColor = 0xFFA0A0A0

let result = mkWatched(persist, "result", null)
let close = @() result(null)
subscribe("showBenchmarkResult", @(msg) result(msg))

let statsCfg = [
  {
    locId = "benchmark/avgfps"
    getValue = @(s) round_by_value(s.benchTotalTime < 0.1 ? 0.0 : (s.benchTotalFrames / s.benchTotalTime), 0.1)
  }
  {
    locId = "benchmark/minfps"
    getValue = @(s) round_by_value(s.benchMinFPS, 0.1)
  }
  {
    locId = "benchmark/total"
    getValue = @(s) s.benchTotalFrames
  }
]

let mkStatRow = @(cfg, stats) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = hdpx(50)
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_RIGHT
      rendObj = ROBJ_TEXT
      text = loc(cfg.locId)
      color = statColor
    }.__update(fontSmall)
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXT
      text = cfg.getValue(stats)
      color = statColor
    }.__update(fontSmall)
  ]
}

let benchmark = @(stats) {
  size = flex()
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  children = statsCfg.map(@(cfg) mkStatRow(cfg, stats))
}

let buttons = mkMsgBoxBtnsSet(wndUid, [ { id = "ok", isPrimary = true, cb = close } ])

let openBenchmark = @(data) addModalWindow(bgShaded.__merge({
  key = wndUid
  size = flex()
  children = mkCustomMsgBoxWnd(colon.concat(loc("chapters/benchmark"), data.title),
    benchmark(data.stats), buttons)
  onClick = @() null
}))
if (result.value != null)
  openBenchmark(result.value)
result.subscribe(@(v) v != null ? openBenchmark(v) : removeModalWindow(wndUid))
