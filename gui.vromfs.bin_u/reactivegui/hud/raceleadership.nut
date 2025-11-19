from "%globalsDarg/darg_library.nut" import *
let { preciseSecondsToString } = require("%appGlobals/timeToText.nut")
let { myUserName } = require("%appGlobals/profileStates.nut")
let { raceLeadershipPlayers } = require("%rGui/hud/raceState.nut")
let { teamRedLightColor } = require("%rGui/style/teamColors.nut")
let { localPlayerColor } = require("%rGui/style/stdColors.nut")
let { getElemFont } = require("%rGui/hudTuning/cfg/cfgOptions.nut")
let { curUnitHudTuningOptions } = require("%rGui/hudTuning/hudTuningBattleState.nut")
let { mkPlaceIcon } = require("%rGui/components/playerPlaceIcon.nut")


let MAX_ROWS = 4
let evenRowColor = 0x40000000
let unevenRowColor = 0x80000000
let rowHtMul = 1.7
let placeHtMul = 2.0

let getFont = @(o) getElemFont(o, "raceLeadership")

let mkText = @(text, isMe, font) {
  rendObj = ROBJ_TEXT
  text
  color = isMe ? localPlayerColor : teamRedLightColor
}.__update(font)

let columns = [
  {
    width = @(font, _) calc_str_box("9:59.999", font)[0]
    halign = ALIGN_RIGHT
    ctor = @(data, sizes) mkText(
      data.raceFinishTime > 0 ? preciseSecondsToString(data.raceFinishTime, false)
        : data.progress >= 0 ? $"{data.progress}%"
        : "",
      data.isPlayer,
      sizes.font)
  }
  {
    width = @(_, htA) (htA * placeHtMul + 0.5).tointeger()
    ctor = @(data, sizes) mkPlaceIcon(data.place, sizes.palceSize, sizes.font)
  }
  {
    halign = ALIGN_LEFT
    width = @(font, _) calc_str_box("WWWWWWWWWWWWWWWW", font)[0]
    ctor = @(data, sizes) mkText(data.name, data.isPlayer, sizes.font)
  }
]

function getSizes(font) {
  let gapSize = calc_str_box("A", font)
  let colWidths = columns.map(@(c) c.width(font, gapSize[1]))
  let gap = gapSize[0]
  return {
    font
    gap
    rowHeight = (gapSize[1] * rowHtMul + 0.5).tointeger()
    palceSize = 2 * (gapSize[1] * placeHtMul / 2 + 0.5).tointeger()
    colWidths
    totalWidth = colWidths.reduce(@(a, b) a + b) + gap * (columns.len() + 1)
  }
}

function mkRow(rowIdx, data, sizes) {
  let { rowHeight, gap, colWidths } = sizes
  return @() {
    watch = data
    size = [flex(), rowHeight]
    padding = [0, gap]
    rendObj = ROBJ_SOLID
    color = (rowIdx % 2) ? evenRowColor : unevenRowColor
    flow = FLOW_HORIZONTAL
    gap
    children = data.get() == null ? null
      : columns.map(@(c, i) {
          size = [colWidths[i], flex()]
          valign = ALIGN_CENTER
          halign = c?.halign ?? ALIGN_CENTER
          children = c.ctor(data.get(), sizes)
        })
  }
}

function mkRaceLeadership(rowsData, sizes) {
  let rowsCount = Computed(@() rowsData.get().len())
  let { rowHeight, totalWidth } = sizes
  return @() {
    watch = rowsCount
    size = [totalWidth, rowHeight * MAX_ROWS]
    flow = FLOW_VERTICAL
    children = array(rowsCount.get())
      .map(@(_, i) mkRow(i, Computed(@() rowsData.get()?[i]), sizes))
  }
}

let mkEditViewRowsData = @() Computed(@() [
  { time = -0.014, place = 1, progress = 85, raceFinishTime = -1, name = loc("coop/Bot52"), isPlayer = false }
  { time = 2.749, place = 2, progress = 80, raceFinishTime = -1, name = loc("coop/Bot429"), isPlayer = false }
  { time = 75.367, place = 3, progress = 79, raceFinishTime = -1, name = myUserName.get(), isPlayer = true }
  { time = 4.021, place = 4, progress = 73, raceFinishTime = -1, name = loc("coop/Bot265"), isPlayer = false }
])

let raceLeadershipEditView = @(options)
  mkRaceLeadership(mkEditViewRowsData(), getSizes(getFont(options)))

let raceLeadershipCtor = @() @() {
  watch = curUnitHudTuningOptions
  children = mkRaceLeadership(raceLeadershipPlayers, getSizes(getFont(curUnitHudTuningOptions.get())))
}

return {
  raceLeadershipCtor
  raceLeadershipEditView
}