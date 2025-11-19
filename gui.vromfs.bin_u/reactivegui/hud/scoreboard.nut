from "%globalsDarg/darg_library.nut" import *
let { setInterval, clearTimer } = require("dagor.workcycle")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { ceil, round, floor, tan, PI } = require("%sqstd/math.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { getBombingZones } = require("guiMission")
let { secondsToTimeSimpleString } = require("%sqstd/time.nut")
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { prettyScaleForSmallNumberCharVariants } = require("%globalsDarg/fontScale.nut")
let { isHudAttached } = require("%appGlobals/clientState/hudState.nut")
let { missionProgressType } = require("%appGlobals/clientState/missionState.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { isInMpBattle, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { localTeam, ticketsTeamA, ticketsTeamB, timeLeft, scoreLimit, gameType,
  isGtRace, isGtBattleRoyale
} = require("%rGui/missionState.nut")
let { teamBlueColor, teamRedColor, teamBlueDarkColor, teamRedDarkColor } = require("%rGui/style/teamColors.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")
let { ticketPenaltyReasonAllyLogPlace, ticketPenaltyReasonEnemyLogPlace } = require("%rGui/hudHints/ticketsPenaltyReason.nut")
let { mkPlaceIcon } = require("%rGui/components/playerPlaceIcon.nut")
let { mkImageWithCount } = require("%rGui/hud/myScores.nut")
let { mkMissionVar } = require("%rGui/hud/missionVariableState.nut")
let { playersByTeam, startContinuousUpdate, stopContinuousUpdate } = require("%rGui/mpStatistics/playersByTeamState.nut")
let { cellTextProps } = require("%rGui/mpStatistics/mpStatsTable.nut")
let { hudWhiteColor, hudBlackColor, hudTranslucentBlackColor, hudSilverGray, hudSmokyBlack } = require("%rGui/style/hudColors.nut")
let { raceCurrentLap, raceTotalLaps, raceCurrentCheckpoint, raceTotalCheckpoints, hasRaceState, raceTime
} = require("raceState.nut")


let scoreBlockAngle = 30
let scoreVerticalGap = hdpx(8)
let secondsPerHour = 3600
let barRatio = 56.0 / 19
const SCORE_PLATES_TEAM_COUNT = 5

let battleRoyaleScoreBoardCfg = {
  aliveImage = "ui/gameuiskin#selected_icon_tank.svg"
  killImage = "ui/gameuiskin#tanks_destroyed_icon.svg"
  killProperty = "groundKills"
}

let scoreBarPlateHeight = hdpxi(15)
let scoreBarPlateWidth = (barRatio * scoreBarPlateHeight + 0.5).tointeger()
let scoreBarPadding = (0.15 * scoreBarPlateHeight).tointeger()
let scoreBarGap = (-0.4 * scoreBarPlateHeight).tointeger()
let scoreBarWidth = scoreBarGap * (SCORE_PLATES_TEAM_COUNT - 1) + SCORE_PLATES_TEAM_COUNT * scoreBarPlateWidth + 4 * scoreBarPadding
let scoreBarHeight = scoreBarPlateHeight + 2 * scoreBarPadding
let baseIconSize = (scoreBarHeight * 1.4)
let timerBgWidth   = (0.65 * scoreBarWidth).tointeger()
let timerBgHeight  = (57.0 / 131 * timerBgWidth).tointeger()
let raceCPBarWidth = hdpx(450)
let gapToTimer = @(timerBgWidthV) -0.15 * timerBgWidthV
let scoreBarOffesetY = 0.45 * timerBgHeight
let penaltyReasonBlockSize = [hdpx(130), hdpx(60)]

let timerBgColor = hudSmokyBlack

let timeWarningIconSide = hdpxi(40)
let aliveAmountIconSide = hdpxi(80)

let localTeamTickets = Computed(@() localTeam.get() == 2 ? ticketsTeamB.get() : ticketsTeamA.get())
let enemyTeamTickets = Computed(@() localTeam.get() == 2 ? ticketsTeamA.get() : ticketsTeamB.get())

let scoresForOneKill = Computed(@() (scoreLimit.get().tofloat() / SCORE_PLATES_TEAM_COUNT).tointeger())
let needScoreBoard = Computed(@() (gameType.get() & (GT_MP_SCORE | GT_MP_TICKETS | GT_FFA | GT_RACE)) != 0)
let scoreBoardType = Computed(@() isGtRace.get() ? "race"
  : isGtBattleRoyale.get() ? "battle_royale"
  : "common")

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
  color = hudBlackColor
  valign = ALIGN_CENTER
})

function mkSplitScoreBar(teamName, scale) {
  let { score, fillColor, image, halign } = scoreParamsByTeam[teamName]
  let size = scaleArr([scoreBarPlateWidth, scoreBarPlateHeight], scale)
  let gap = round(scoreBarGap * scale).tointeger()
  let padding = max(round(scoreBarPadding * scale).tointeger(), 1)
  let bgSize = [SCORE_PLATES_TEAM_COUNT * (size[0] + gap) - gap + 4 * padding, size[1] + 2 * padding]

  let remainingPlatesCount = Computed(@() scoresForOneKill.get() == 0 ? 0
    : ceil(score.get().tofloat() / scoresForOneKill.get()).tointeger())

  let res = mkScoreBarBg(image, bgSize).__update({
    watch = remainingPlatesCount
    pos = [0, (scoreBarOffesetY * scale).tointeger()]
    padding = [padding, 2 * padding]
    halign,
    flow = FLOW_HORIZONTAL,
    gap
  })
  return @() res.__merge({
    children = array(remainingPlatesCount.get(),
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
  let progress = Computed(@() scoreLimit.get() == 0 ? 0 : clamp(score.get().tofloat() / scoreLimit.get(), 0.0, 1.0))
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
          ? [VECTOR_POLY, 100, 100, full, 0, full - full * progress.get(), 0, 100.0 - full * progress.get(), 100]
          : [VECTOR_POLY, 0, 100, ofs, 0, ofs + full * progress.get(), 0, full * progress.get(), 100]
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
    onAttach = updateBZones
    children = array(baseCount.get()).map(function(_, i) {
      let b = Computed(@(prev) isEqual(bases.get()?[i], prev) ? prev : bases.get()?[i])
      return @() {
        watch = b
        size = [basesBlockHeight, basesBlockHeight]
        rendObj = ROBJ_VECTOR_CANVAS
        fillColor = b.get().zoneIntegrity > 0 ? hudBlackColor : hudTranslucentBlackColor
        color = b.get().zoneIntegrity > 0 ? hudBlackColor : hudTranslucentBlackColor
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
            fgColor = hudBlackColor
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
    to = hudWhiteColor,
    duration = 1.5,
    trigger,
    loop = true,
    easing = CosineFull
  }
  {
    prop = AnimProp.color,
    to = hudWhiteColor,
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
        color = hudWhiteColor
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

let scoreBoardBase = {
  key = "score_board"
  hplace = ALIGN_CENTER
  cameraControl = true
  hotkeys = mkGamepadHotkey(shortcutId)
  sound = { click = "click" }
}

let mkTime = @(timer, ovr) @() {
  watch = timer
  rendObj = ROBJ_TEXT
  text = timer.get() < 0 ? ""
    : timer.get() >= secondsPerHour ? secondsToHoursLoc(timer.get())
    : secondsToTimeSimpleString(timer.get())
}.__update(ovr)

let mkScoreBoard = @(scale) function() {
  let barCtor = barCtors?[missionProgressType.get()] ?? mkLinearScoreBar
  let tSize = scaleArr([timerBgWidth, timerBgHeight], scale)
  let font = prettyScaleForSmallNumberCharVariants(fontTiny, scale)
  return scoreBoardBase.__merge({
    watch = [missionProgressType, isInMpBattle]
    behavior = isInMpBattle.get() ? Behaviors.Button : null
    onClick = isInMpBattle.get() ? @() eventbus_send("toggleMpstatscreen", {}) : null
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
            children = mkTime(timeLeft, font)
          }
          barCtor("enemyTeam", scale)
        ]
      }
    ]
  })
}

function findLocalPlayerProperty(teams, propertyName, defValue) {
  foreach (team in teams) {
    let localP = team.findvalue(@(p) p?.isLocal)
    if (localP)
      return localP?[propertyName] ?? defValue
  }
  return defValue
}

let mkIcon = @(icon, size, color = hudWhiteColor) {
  size
  rendObj = ROBJ_IMAGE
  color
  image = Picture($"{icon}:{size[0]}:{size[1]}:P")
  keepAspect = KEEP_ASPECT_FIT
}

function mkTimeWarningBattleRoyale(scale) {
  let timeWarningIconSize = scaleArr([timeWarningIconSide, timeWarningIconSide], scale)
  let timeWarningIconActiveSize = scaleArr([round(timeWarningIconSide / 40.0 * 84).tointeger(), timeWarningIconSide], scale)
  let isBattleRoyaleZoneShrink = mkMissionVar("BRzoneShrink", false)
  let iconNormal = mkIcon("ui/gameuiskin#hud_danger_timer.svg", timeWarningIconSize)
  let iconActive = mkIcon("ui/gameuiskin#hud_danger_timer_active.svg", timeWarningIconActiveSize)
  return @() {
    watch = isBattleRoyaleZoneShrink
    size = timeWarningIconSize
    halign = ALIGN_CENTER
    children = isBattleRoyaleZoneShrink.get() ? iconActive : iconNormal
  }
}

function mkScoreBoardBattleRoyale(scale) {
  let place = Computed(@() findLocalPlayerProperty(playersByTeam.get(), "place", 0))
  let kills = Computed(@()
    findLocalPlayerProperty(playersByTeam.get(), battleRoyaleScoreBoardCfg.killProperty, 0))
  let aliveAmount = Computed(@() (playersByTeam.get()?.findvalue(@(_) true) ?? [])
    .filter(@(p) p != null && (!p.isDead || p.isTemporary))
    .len())

  let blockSize = scaleArr([timerBgWidth, timerBgHeight], scale)
  let aliveAmountIconSize = scaleArr([aliveAmountIconSide, aliveAmountIconSide], scale)
  let fontTinyScaled = prettyScaleForSmallNumberCharVariants(fontTiny, scale)
  let fontTinyAccentedScaled = prettyScaleForSmallNumberCharVariants(fontTinyAccented, scale)
  let fontMonoTinyScaled = prettyScaleForSmallNumberCharVariants(fontMonoTiny, scale)

  let zoneTimer = mkMissionVar("BRzoneTimer", 0)

  return scoreBoardBase.__merge({
    behavior = Behaviors.Button
    onClick = @() eventbus_send("toggleMpstatscreen", {})
    onAttach = startContinuousUpdate
    onDetach = stopContinuousUpdate
    children = [
      shortcutImg(scale)
      {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = scaleEven(hdpx(44), scale)
        children = [
          @() {
            watch = aliveAmount
            size = blockSize
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            halign = ALIGN_RIGHT
            gap = scaleEven(hdpx(8), scale)
            margin = scaleArr([0, hdpx(12)], scale)
            children = [
              mkIcon(battleRoyaleScoreBoardCfg.aliveImage, aliveAmountIconSize, hudSilverGray)
              cellTextProps.__merge({ text = aliveAmount.get() }, fontTinyAccentedScaled)
            ]
          }
          {
            size = blockSize
            rendObj = ROBJ_SOLID
            flow = FLOW_HORIZONTAL
            color = timerBgColor
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            gap = scaleEven(hdpx(8), scale)
            children = [
              mkTimeWarningBattleRoyale(scale)
              mkTime(zoneTimer, fontMonoTinyScaled)
            ]
          }
          @() {
            watch = place
            size = blockSize
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            halign = ALIGN_LEFT
            children = [
              mkPlaceIcon(place.get(), scaleEven(evenPx(100), scale), fontTinyScaled)
              mkImageWithCount(kills, battleRoyaleScoreBoardCfg.killImage, scale)
            ]
          }
        ]
      }
    ]
  })
}

let getEmptyPartWidth = @(height, angle) tan(angle * (PI / 180)) * height
let getEmptyWidthRatioPercent = @(size, angle) getEmptyPartWidth(size[1], angle) * 100 / size[0]

let baseShape = {
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(2)
  fillColor = timerBgColor
  color = timerBgColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
}

function mkIsoscelesTrapezoid(size, angle, ovr = {}) {
  let emptyWidthPercent = getEmptyWidthRatioPercent(size, angle)
  return baseShape.__merge({
    size
    commands = [
      [ VECTOR_POLY,
        0, 0,
        100, 0,
        100 - emptyWidthPercent, 100,
        emptyWidthPercent, 100 ]
    ]
  }, ovr)
}

function mkParallelogram(size, angle, ovr = {}) {
  let emptyWidthPercent = getEmptyWidthRatioPercent(size, angle)
  return baseShape.__merge({
    size
    commands = [
      [ VECTOR_POLY,
        emptyWidthPercent, 0,
        100, 0,
        100 - emptyWidthPercent, 100,
        0, 100 ]
    ]
  }, ovr)
}

function mkScoreBoardRace(scale) {
  let cpBlockSize = scaleArr([raceCPBarWidth, timerBgHeight], scale)
  let rowHeight = cpBlockSize[1]
  let vGap = round(scoreVerticalGap * scale).tointeger()
  let extraWidth = getEmptyPartWidth(rowHeight, scoreBlockAngle).tointeger()
  let extraWidthRow = 2 * getEmptyPartWidth(rowHeight + vGap, scoreBlockAngle).tointeger()
  let hGap = vGap - extraWidth

  let firstRowWidthSum = (cpBlockSize[0] + extraWidthRow - hGap).tointeger()
  let timeBlockSize = [(firstRowWidthSum * 0.333).tointeger(), rowHeight]
  let lapBlockSize = [firstRowWidthSum - timeBlockSize[0], rowHeight]
  let timeBlockSize1Lap = [cpBlockSize[0] - extraWidthRow, rowHeight]

  let fontMonoTinyScaled = prettyScaleForSmallNumberCharVariants(fontMonoTiny, scale)
  let raceLapText = Computed(@() loc("hud/race/lap",
    { current = raceCurrentLap.get(), total = raceTotalLaps.get() }))
  let raceCheckpountText = Computed(@() loc("hud/race/checkpoint",
    { current = raceCurrentCheckpoint.get(), total = raceTotalCheckpoints.get() }))

  let checkpointsInfo = mkIsoscelesTrapezoid(cpBlockSize, scoreBlockAngle,
    {
      children = @() {
        watch = raceCheckpountText
        rendObj = ROBJ_TEXT
        text = raceCheckpountText.get()
      }.__update(fontTiny)
    })
  let lapsInfo = mkParallelogram(lapBlockSize, scoreBlockAngle,
    {
      children = @() {
        watch = raceLapText
        rendObj = ROBJ_TEXT
        text = raceLapText.get()
      }.__update(fontTiny)
    })
  let timeInfo = mkIsoscelesTrapezoid(timeBlockSize, scoreBlockAngle,
    { children = mkTime(raceTime, fontMonoTinyScaled) })
  let timeInfo1Lap = mkIsoscelesTrapezoid(timeBlockSize1Lap, scoreBlockAngle,
    { children = mkTime(raceTime, fontMonoTinyScaled) })

  return scoreBoardBase.__merge({
    behavior = Behaviors.Button
    onClick = @() eventbus_send("toggleMpstatscreen", {})
    onAttach = startContinuousUpdate
    onDetach = stopContinuousUpdate
    children = [
      shortcutImg(scale)
      @() {
        watch = [hasRaceState, raceTotalLaps]
        flow = FLOW_VERTICAL
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        gap = scoreVerticalGap
        children = !hasRaceState.get() ? timeInfo1Lap
          : raceTotalLaps.get() <= 1
            ? [
                checkpointsInfo
                timeInfo1Lap
              ]
          : [
              {
                flow = FLOW_HORIZONTAL
                gap = hGap
                children = [
                  timeInfo
                  lapsInfo
                ]
              }
              checkpointsInfo
            ]
      }
    ]
  })
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

let scoreBoardCfgByType = {
  common = {
    comp = mkScoreBoard(1)
    ctor = mkScoreBoard
    addMyScores = true
  }
  battle_royale = {
    comp = mkScoreBoardBattleRoyale(1)
    ctor = mkScoreBoardBattleRoyale
  }
  race = {
    comp = mkScoreBoardRace(1)
    ctor = mkScoreBoardRace
  }
}


return {
  needScoreBoard
  scoreBoardEditView
  scoreBoardHeight = timerBgHeight

  scoreBoardType
  scoreBoardCfgByType
}
