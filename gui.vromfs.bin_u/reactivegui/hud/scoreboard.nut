from "%globalsDarg/darg_library.nut" import *

let { eventbus_send } = require("eventbus")
let { ceil } = require("%sqstd/math.nut")
let { localTeam, ticketsTeamA, ticketsTeamB, timeLeft, scoreLimit
} = require("%rGui/missionState.nut")
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")
let { secondsToTimeSimpleString } = require("%sqstd/time.nut")
let { getSvgImage } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { missionProgressType } = require("%appGlobals/clientState/missionState.nut")


let barRatio = 56.0 / 19
const SCORE_PLATES_TEAM_COUNT = 5

let scoreBarPlateHeight = hdpxi(15)
let scoreBarPlateWidth = (barRatio * scoreBarPlateHeight + 0.5).tointeger()
let scoreBarPadding = (0.15 * scoreBarPlateHeight).tointeger()
let scoreBarGap = (-0.4 * scoreBarPlateHeight).tointeger()
let scoreBarWidth = scoreBarGap * (SCORE_PLATES_TEAM_COUNT - 1) + SCORE_PLATES_TEAM_COUNT * scoreBarPlateWidth + 4 * scoreBarPadding
let scoreBarHeight = scoreBarPlateHeight + 2 * scoreBarPadding
let timerBgWidth   = (0.55 * scoreBarWidth).tointeger()
let timerBgHeight  = (57.0 / 131 * timerBgWidth).tointeger()
let localTeamTickets = Computed(@() localTeam.value == 2 ? ticketsTeamB.value : ticketsTeamA.value)
let enemyTeamTickets = Computed(@() localTeam.value == 2 ? ticketsTeamA.value : ticketsTeamB.value)

let scoresForOneKill = Computed(@() (scoreLimit.value.tofloat() / SCORE_PLATES_TEAM_COUNT).tointeger())

let scoreParamsByTeam = {
  localTeam = {
    score = localTeamTickets
    fillColor = teamBlueColor
    halign = ALIGN_RIGHT
    image = "hud_healthbar_left_slot"
  }
  enemyTeam = {
    score = enemyTeamTickets
    fillColor = teamRedColor
    halign = ALIGN_LEFT
    image = "hud_healthbar_right_slot"
  }
}

function mkBar(image, width, height) {
  let ofs = (1.4 * height).tointeger()
  let texOffs = [0, ofs, 0, ofs]
  return {
    size = [width, height]
    rendObj = ROBJ_9RECT
    screenOffs = texOffs
    texOffs
    image = getSvgImage(image, (barRatio * height).tointeger(), height)
  }
}

let mkScoreBarBg = @(image) mkBar(image, scoreBarWidth, scoreBarHeight).__update({
  pos = [0, 0.45 * timerBgHeight]
  padding = [scoreBarPadding, 2 * scoreBarPadding]
  color = 0xFF000000
  valign = ALIGN_CENTER
})

function mkSplitScoreBar(teamName) {
  let { score, fillColor, image, halign } = scoreParamsByTeam[teamName]
  let remainingPlatesCount = Computed(@() scoresForOneKill.value == 0 ? 0
    : ceil(score.value.tofloat() / scoresForOneKill.value).tointeger())
  let res = mkScoreBarBg(image).__update({
    watch = remainingPlatesCount,
    halign,
    flow = FLOW_HORIZONTAL,
    gap = scoreBarGap
  })
  return @() res.__merge({
    children = array(remainingPlatesCount.value,
      {
        size = [scoreBarPlateWidth, scoreBarPlateHeight]
        rendObj = ROBJ_IMAGE
        image = getSvgImage(image, scoreBarPlateWidth, scoreBarPlateHeight)
        color = fillColor
      })
  })
}

let ofs = 3.8
let full = 100.0 - ofs
function mkLinearScoreBar(teamName) {
  let { score, fillColor, image, halign } = scoreParamsByTeam[teamName]
  let progress = Computed(@() scoreLimit.value == 0 ? 0 : clamp(score.value.tofloat() / scoreLimit.value, 0.0, 1.0))
  return mkScoreBarBg(image).__update({
    padding = [scoreBarPadding + 1, 2 * scoreBarPadding + 1]
    halign
    children = @() {
      watch = progress
      size = flex()
      color = fillColor
      fillColor
      lineWidth = 2
      rendObj = ROBJ_VECTOR_CANVAS
      commands = [
        halign == ALIGN_RIGHT
          ? [VECTOR_POLY, 100, 100, full, 0, full - full * progress.value, 0, 100.0 - full * progress.value, 100]
          : [VECTOR_POLY, 0, 100, ofs, 0, ofs + full * progress.value, 0, full * progress.value, 100]
      ]
    }
  })
}

function scoreBoard() {
  let barCtor = missionProgressType.value == "split" ? mkSplitScoreBar : mkLinearScoreBar
  return {
    key = "score_board"
    watch = missionProgressType
    hplace = ALIGN_CENTER
    behavior = Behaviors.Button
    flow = FLOW_HORIZONTAL
    gap = -0.15 * timerBgWidth
    onClick = @() eventbus_send("toggleMpstatscreen", {})
    sound = { click  = "click" }
    children = [
      barCtor("localTeam")
      {
        rendObj = ROBJ_IMAGE
        size = [ timerBgWidth, timerBgHeight ]
        image = getSvgImage("hud_time_bg", timerBgWidth, timerBgHeight)
        color = Color(0, 0, 0, 77)
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = @() {
          watch = timeLeft
          rendObj = ROBJ_TEXT
          text = secondsToTimeSimpleString(timeLeft.value)
        }.__update(fontTiny)
      }
      barCtor("enemyTeam")
    ]
  }
}

let scoreBoardEditView = {
  flow = FLOW_HORIZONTAL
  gap = -0.15 * timerBgWidth
  children = [
    mkLinearScoreBar("localTeam")
    {
      rendObj = ROBJ_IMAGE
      size = [timerBgWidth, timerBgHeight]
      image = getSvgImage("hud_time_bg", timerBgWidth, timerBgHeight)
      color = Color(0, 0, 0, 77)
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = @() {
        watch = timeLeft
        rendObj = ROBJ_TEXT
        text = "xx:xx"
      }.__update(fontTiny)
    }
    mkLinearScoreBar("enemyTeam")
  ]
}

return {
  scoreBoard
  scoreBoardEditView
}
