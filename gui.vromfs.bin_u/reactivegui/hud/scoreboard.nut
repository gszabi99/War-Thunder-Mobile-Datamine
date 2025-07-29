from "%globalsDarg/darg_library.nut" import *
let { setInterval, clearTimer } = require("dagor.workcycle")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { ceil, round, floor } = require("%sqstd/math.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { getBombingZones } = require("guiMission")
let { secondsToTimeSimpleString } = require("%sqstd/time.nut")
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { prettyScaleForSmallNumberCharVariants } = require("%globalsDarg/fontScale.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { isHudAttached } = require("%appGlobals/clientState/hudState.nut")
let { missionProgressType } = require("%appGlobals/clientState/missionState.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { isInMpBattle, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { localTeam, ticketsTeamA, ticketsTeamB, timeLeft, scoreLimit, gameType
} = require("%rGui/missionState.nut")
let { teamBlueColor, teamRedColor, teamBlueDarkColor, teamRedDarkColor } = require("%rGui/style/teamColors.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")
let { ticketPenaltyReasonAllyLogPlace, ticketPenaltyReasonEnemyLogPlace } = require("%rGui/hudHints/ticketsPenaltyReason.nut")

let secondsPerHour = 3600
let barRatio = 56.0 / 19
const SCORE_PLATES_TEAM_COUNT = 5

let scoreBarPlateHeight = hdpxi(15)
let scoreBarPlateWidth = (barRatio * scoreBarPlateHeight + 0.5).tointeger()
let scoreBarPadding = (0.15 * scoreBarPlateHeight).tointeger()
let scoreBarGap = (-0.4 * scoreBarPlateHeight).tointeger()
let scoreBarWidth = scoreBarGap * (SCORE_PLATES_TEAM_COUNT - 1) + SCORE_PLATES_TEAM_COUNT * scoreBarPlateWidth + 4 * scoreBarPadding
let scoreBarHeight = scoreBarPlateHeight + 2 * scoreBarPadding
let baseIconSize = (scoreBarHeight * 1.4)
let timerBgWidth   = (0.65 * scoreBarWidth).tointeger()
let timerBgHeight  = (57.0 / 131 * timerBgWidth).tointeger()
let gapToTimer = @(timerBgWidthV) -0.15 * timerBgWidthV
let scoreBarOffesetY = 0.45 * timerBgHeight
let penaltyReasonBlockSize = [hdpx(130), hdpx(60)]

let timerBgColor = 0x4D000000

let localTeamTickets = Computed(@() localTeam.value == 2 ? ticketsTeamB.value : ticketsTeamA.value)
let enemyTeamTickets = Computed(@() localTeam.value == 2 ? ticketsTeamA.value : ticketsTeamB.value)

let scoresForOneKill = Computed(@() (scoreLimit.get().tofloat() / SCORE_PLATES_TEAM_COUNT).tointeger())
let needScoreBoard = Computed(@() (gameType.get() & (GT_MP_SCORE | GT_MP_TICKETS)) != 0)

let battleBasesRaw = hardPersistWatched("battleBasesRaw",[])

let mkBasesByTeam = @(isLocal) Computed(function() {
  let bases = battleBasesRaw.get().filter(@(b) isLocal ? b.team == localTeam.get() : b.team != localTeam.get()) ?? []
  let airField = bases.findvalue(@(v) v.isAirfield)
  return airField != null ? [airField] : bases
})

let localTeamBasesToShow = mkBasesByTeam(true)
let enemyTeamBasesToShow = mkBasesByTeam(false)

let updateBZones = @() battleBasesRaw.set(getBombingZones() ?? [])
eventbus_subscribe("onBombingZoneDamaged", @(_) updateBZones())
eventbus_subscribe("onBombingZoneStateChanged", @(_) updateBZones())

let scoreParamsByTeam = {
  localTeam = {
    score = localTeamTickets
    prevScore = Watched(null)
    fillColor = teamBlueColor
    fillDisabledColor = teamBlueDarkColor
    halign = ALIGN_RIGHT
    image = "hud_healthbar_left_slot.svg"
    baseImage = "base_ally"
    bases = localTeamBasesToShow
    baseCount = Computed(@() localTeamBasesToShow.get().len())
    penaltyLog = ticketPenaltyReasonAllyLogPlace
  }
  enemyTeam = {
    score = enemyTeamTickets
    prevScore = Watched(null)
    fillColor = teamRedColor
    fillDisabledColor = teamRedDarkColor
    halign = ALIGN_LEFT
    image = "hud_healthbar_right_slot.svg"
    baseImage = "base_enemy"
    bases = enemyTeamBasesToShow
    baseCount = Computed(@() enemyTeamBasesToShow.get().len())
    penaltyLog = ticketPenaltyReasonEnemyLogPlace
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

isInBattle.subscribe(function(v) {
  if (v)
    return
  scoreParamsByTeam.each(@(team) team.prevScore.set(null))
  battleBasesRaw.set([])
})

function mkBasesIndicators(scoreParams, basesBlockHeight, iconSize) {
  let { bases, baseCount, baseImage, fillColor, fillDisabledColor, halign } = scoreParams
  return @() {
    watch = baseCount
    rendObj = ROBJ_BOX
    size = [SIZE_TO_CONTENT, basesBlockHeight]
    pos = [0, basesBlockHeight]
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    halign
    children = array(baseCount.get()).map(function(_, i) {
      let b = Computed(@(prev) isEqual(bases.get()?[i], prev) ? prev : bases.get()?[i])
      return @() {
        watch = b
        size = [basesBlockHeight, basesBlockHeight]
        rendObj = ROBJ_VECTOR_CANVAS
        fillColor = b.get().zoneIntegrity > 0 ? 0xFF000000 : 0x55000000
        color = b.get().zoneIntegrity > 0 ? 0xFF000000 : 0x55000000
        lineWidth = 2
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        commands = [
          [VECTOR_ELLIPSE, 50, 50, 50, 50],
        ]
        children = [
          b.get().zoneIntegrity == 0 ? null : {
            size = [basesBlockHeight, basesBlockHeight]
            rendObj = ROBJ_PROGRESS_CIRCULAR
            keepAspect = true
            image = Picture($"ui/gameuiskin#circular_progress_1.svg:{basesBlockHeight}:{basesBlockHeight}:P")
            bgColor = fillColor
            fgColor = 0xFF000000
            fValue = 1 - b.get().zoneIntegrity
          },
          {
            size = iconSize
            rendObj = ROBJ_IMAGE
            keepAspect = true
            image = Picture($"ui/gameuiskin#{b.get().isAirfield ? "airport" : baseImage}.svg:{iconSize}:{iconSize}:P")
            color = b.get().zoneIntegrity > 0 ? fillColor : fillDisabledColor
          },
        ]
      }
    })
  }
}

let getScoreBarAttentionAnimations = @(trigger) [
  {
    prop = AnimProp.fillColor,
    to = 0xFFFFFFFF,
    duration = 1.5,
    trigger,
    loop = true,
    easing = CosineFull
  }
  {
    prop = AnimProp.color,
    to = 0xFFFFFFFF,
    duration = 1.5,
    trigger,
    loop = true,
    easing = CosineFull
  }
]

function mkLinearScoreBarWithScore(teamName, scale) {
  let { score, fillColor, image, halign, prevScore, penaltyLog } = scoreParamsByTeam[teamName]
  let progress = Computed(@() scoreLimit.get() == 0 ? 0 : clamp(score.get().tofloat() / scoreLimit.get(), 0.0, 1.0))
  let padding = max(round(scoreBarPadding * scale).tointeger(), 1)
  let paddingInc = hdpxi(scale)
  function updateScore() {
    if (score.get() != prevScore.get() && prevScore.get() != null) {
      let diff = score.get() - prevScore.get()
      let shift = (diff > 0 ? ceil : floor)(0.2 * diff)
      prevScore.set(prevScore.get() + shift)
    }
  }

  let progressBarSize = scaleArr([scoreBarWidth, scoreBarHeight], scale)
  let penaltyBlockSize = scaleArr(penaltyReasonBlockSize, scale)
  let iconSize = round(baseIconSize * scale / 2) * 2
  let basesBlockHeight = progressBarSize[1] * 2
  return mkScoreBarBg(image, progressBarSize).__update({
    padding = [padding + paddingInc, 2 * padding + paddingInc]
    halign
    children = [
      @() {
        watch = progress
        size = flex()
        color = fillColor
        fillColor
        lineWidth = 2
        rendObj = ROBJ_VECTOR_CANVAS
        commands = [
          halign == ALIGN_RIGHT
            ? [VECTOR_POLY, 100, 100, full, 0, full - full * progress.get(), 0, 100.0 - full * progress.get(), 100]
            : [VECTOR_POLY, 0, 100, ofs, 0, ofs + full * progress.get(), 0, full * progress.get(), 100]]
        animations = getScoreBarAttentionAnimations($"{teamName}AirportDamaged")
      }
      @() {
        watch = prevScore
        key = updateScore
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXT
        color = 0xFFFFFFFF
        halign = ALIGN_CENTER
        vplace = ALIGN_CENTER
        text = prevScore.get()
        function onAttach() {
          if (prevScore.get() == null)
            prevScore.set(score.get())
          setInterval(0.05, updateScore)
        }
        onDetach = @() clearTimer(updateScore)
      }.__update(fontVeryVeryTinyShaded)
      {
        size = penaltyBlockSize
        pos = [halign == ALIGN_LEFT ? progressBarSize[0] : -progressBarSize[0], -progressBarSize[1]]
        valign = ALIGN_BOTTOM
        halign
        children = penaltyLog
      }
      mkBasesIndicators(scoreParamsByTeam[teamName], basesBlockHeight, iconSize)
    ]
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

let barCtors = {
  split = mkSplitScoreBar,
  airGS = mkLinearScoreBarWithScore
}

let mkScoreBoard = @(scale) function() {
  let barCtor = barCtors?[missionProgressType.get()] ?? mkLinearScoreBar
  let tSize = scaleArr([timerBgWidth, timerBgHeight], scale)
  let font = prettyScaleForSmallNumberCharVariants(fontTiny, scale)
  return {
    key = "score_board"
    watch = [missionProgressType, isInMpBattle, curCampaign]
    hplace = ALIGN_CENTER
    behavior = isInMpBattle.get() ? Behaviors.Button : null
    cameraControl = true
    onClick = isInMpBattle.get() ? @() eventbus_send("toggleMpstatscreen", {}) : null
    hotkeys = mkGamepadHotkey(shortcutId)
    sound = { click = "click" }
    children = [
      isInMpBattle.get() ? shortcutImg(scale) : null
      {
        flow = FLOW_HORIZONTAL
        gap = missionProgressType.get() == "airGS" ? -hdpx(round(5 * scale).tointeger()) : gapToTimer(tSize[0])
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
