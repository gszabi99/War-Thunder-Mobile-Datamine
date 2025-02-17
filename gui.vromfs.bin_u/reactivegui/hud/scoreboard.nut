from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { ceil, round } = require("%sqstd/math.nut")
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { prettyScaleForSmallNumberCharVariants } = require("%globalsDarg/fontScale.nut")
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { localTeam, ticketsTeamA, ticketsTeamB, timeLeft, scoreLimit, gameType
} = require("%rGui/missionState.nut")
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")
let { secondsToTimeSimpleString } = require("%sqstd/time.nut")
let { isHudAttached } = require("%appGlobals/clientState/hudState.nut")
let { missionProgressType } = require("%appGlobals/clientState/missionState.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")

let secondsPerHour = 3600
let barRatio = 56.0 / 19
const SCORE_PLATES_TEAM_COUNT = 5

let scoreBarPlateHeight = hdpxi(15)
let scoreBarPlateWidth = (barRatio * scoreBarPlateHeight + 0.5).tointeger()
let scoreBarPadding = (0.15 * scoreBarPlateHeight).tointeger()
let scoreBarGap = (-0.4 * scoreBarPlateHeight).tointeger()
let scoreBarWidth = scoreBarGap * (SCORE_PLATES_TEAM_COUNT - 1) + SCORE_PLATES_TEAM_COUNT * scoreBarPlateWidth + 4 * scoreBarPadding
let scoreBarHeight = scoreBarPlateHeight + 2 * scoreBarPadding
let timerBgWidth   = (0.65 * scoreBarWidth).tointeger()
let timerBgHeight  = (57.0 / 131 * timerBgWidth).tointeger()
let gapToTimer = @(timerBgWidthV) -0.15 * timerBgWidthV
let scoreBarOffesetY = 0.45 * timerBgHeight

let timerBgColor = 0x4D000000

let localTeamTickets = Computed(@() localTeam.value == 2 ? ticketsTeamB.value : ticketsTeamA.value)
let enemyTeamTickets = Computed(@() localTeam.value == 2 ? ticketsTeamA.value : ticketsTeamB.value)

let scoresForOneKill = Computed(@() (scoreLimit.get().tofloat() / SCORE_PLATES_TEAM_COUNT).tointeger())
let needScoreBoard = Computed(@() (gameType.get() & (GT_MP_SCORE | GT_MP_TICKETS)) != 0)

let scoreParamsByTeam = {
  localTeam = {
    score = localTeamTickets
    fillColor = teamBlueColor
    halign = ALIGN_RIGHT
    image = "hud_healthbar_left_slot.svg"
  }
  enemyTeam = {
    score = enemyTeamTickets
    fillColor = teamRedColor
    halign = ALIGN_LEFT
    image = "hud_healthbar_right_slot.svg"
  }
}

function mkBar(image, size) {
  let ofs = round(1.4 * size[1]).tointeger()
  let texOffs = [0, ofs, 0, ofs]
  return {
    size
    rendObj = ROBJ_9RECT
    screenOffs = texOffs
    texOffs
    image = Picture($"ui/gameuiskin#{image}:{size[0]}:{size[1]}:P")
  }
}

let mkScoreBarBg = @(image, size) mkBar(image, size).__update({
  color = 0xFF000000
  valign = ALIGN_CENTER
})

function mkSplitScoreBar(teamName, scale) {
  let { score, fillColor, image, halign } = scoreParamsByTeam[teamName]
  let size = scaleArr([scoreBarPlateWidth, scoreBarPlateHeight], scale)
  let gap = round(scoreBarGap * scale).tointeger()
  let padding = max(round(scoreBarPadding * scale).tointeger(), 1)
  let bgSize = [SCORE_PLATES_TEAM_COUNT * (size[0] + gap) - gap + 4 * padding, size[1] + 2 * padding]

  let remainingPlatesCount = Computed(@() scoresForOneKill.value == 0 ? 0
    : ceil(score.value.tofloat() / scoresForOneKill.value).tointeger())

  let res = mkScoreBarBg(image, bgSize).__update({
    watch = remainingPlatesCount
    pos = [0, (scoreBarOffesetY * scale).tointeger()]
    padding = [padding, 2 * padding]
    halign,
    flow = FLOW_HORIZONTAL,
    gap
  })
  return @() res.__merge({
    children = array(remainingPlatesCount.value,
      {
        size
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#{image}:{size[0]}:{size[1]}:P")
        color = fillColor
      })
  })
}

let ofs = 3.8
let full = 100.0 - ofs
function mkLinearScoreBar(teamName, scale) {
  let { score, fillColor, image, halign } = scoreParamsByTeam[teamName]
  let progress = Computed(@() scoreLimit.value == 0 ? 0 : clamp(score.value.tofloat() / scoreLimit.value, 0.0, 1.0))
  let padding = max(round(scoreBarPadding * scale).tointeger(), 1)
  let paddingInc = hdpxi(scale)
  return mkScoreBarBg(image, scaleArr([scoreBarWidth, scoreBarHeight], scale)).__update({
    pos = [0, (scoreBarOffesetY * scale).tointeger()]
    padding = [padding + paddingInc, 2 * padding + paddingInc]
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

let shortcutId = "ID_MPSTATSCREEN"
let shortcutImg = @(scale) @() {
  watch = isHudAttached
  hplace = ALIGN_LEFT
  vplace = ALIGN_CENTER
  pos = [hdpx(-70 * scale), hdpx(10 * scale)]
  children = !isHudAttached.get() ? null : mkGamepadShortcutImage(shortcutId, {}, scale)
}

let mkScoreBoard = @(scale) function() {
  let barCtor = missionProgressType.value == "split" ? mkSplitScoreBar : mkLinearScoreBar
  let tSize = scaleArr([timerBgWidth, timerBgHeight], scale)
  let font = prettyScaleForSmallNumberCharVariants(fontTiny, scale)
  return {
    key = "score_board"
    watch = missionProgressType
    hplace = ALIGN_CENTER
    behavior = Behaviors.Button
    cameraControl = true
    onClick = @() isHudAttached.get() ? toggleShortcut(shortcutId) : eventbus_send("toggleMpstatscreen", {})
    hotkeys = mkGamepadHotkey(shortcutId)
    sound = { click  = "click" }
    children = [
      shortcutImg(scale)
      {
        flow = FLOW_HORIZONTAL
        gap = gapToTimer(tSize[0])
        children = [
          barCtor("localTeam", scale)
          {
            rendObj = ROBJ_IMAGE
            size = tSize
            image = Picture($"ui/gameuiskin#hud_time_bg.svg:{tSize[0]}:{tSize[1]}:P")
            color = timerBgColor
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = @() {
              watch = timeLeft
              rendObj = ROBJ_TEXT
              text = timeLeft.get() >= secondsPerHour
                ? secondsToHoursLoc(timeLeft.get())
                : secondsToTimeSimpleString(timeLeft.get())
            }.__update(font)
          }
          barCtor("enemyTeam", scale)
        ]
      }
    ]
  }
}

let scoreBoardEditView = {
  flow = FLOW_HORIZONTAL
  gap = gapToTimer(timerBgWidth)
  children = [
    mkLinearScoreBar("localTeam", 1)
    {
      rendObj = ROBJ_IMAGE
      size = [timerBgWidth, timerBgHeight]
      image = Picture($"ui/gameuiskin#hud_time_bg.svg:{timerBgWidth}:{timerBgHeight}:P")
      color = timerBgColor
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = @() {
        watch = timeLeft
        rendObj = ROBJ_TEXT
        text = "xx:xx"
      }.__update(fontTiny)
    }
    mkLinearScoreBar("enemyTeam", 1)
  ]
}

return {
  needScoreBoard
  mkScoreBoard
  scoreBoard = mkScoreBoard(1)
  scoreBoardEditView
  scoreBoardHeight = timerBgHeight
}
