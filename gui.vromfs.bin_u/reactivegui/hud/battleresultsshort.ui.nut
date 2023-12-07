from "%globalsDarg/darg_library.nut" import *
let eventbus = require("eventbus")
let { get_local_mplayer } = require("mission")
let { GO_WIN, GO_FAIL } = require("guiMission")
let { playSound } = require("sound_wt")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { isInDebriefing, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { battleCampaign } = require("%appGlobals/clientState/missionState.nut")
let { localPlayerDamageStats } = require("%rGui/mpStatistics/playersDamageStats.nut")
let { opacityAnims } = require("%rGui/shop/goodsPreview/goodsPreviewPkg.nut")
let { mkPlaceIcon, playerPlaceIconSize } = require("%rGui/components/playerPlaceIcon.nut")
let { mkImageWithCount, myPlace, isPlaceVisible, icons, viewMuls } = require("%rGui/hud/myScores.nut")
let { debriefingData } = require("%rGui/debriefing/debriefingState.nut")
let resultsHintLogState = require("%rGui/hudHints/resultsHintLogState.nut")
let { resultsHintsBlock } = require("%rGui/hudHints/hintBlocks.nut")
let { mkStreakWithMultiplier, prepareStreaksArray } = require("%rGui/streak/streakPkg.nut")

let changeTextBgColorDuration = 0.1
let textBlockBounceDuration = 0.3
let missionResultScaleDuration = 0.1
let missionResultOpacityDuration = 0.1
let textAppearanceDuration = 0.2
let textAppearanceDelay = textBlockBounceDuration
let borderColorTransitionDuration = 0.1
let placeInTeamTextOpacityDuration = 0.1
let placeInTeamTextOpacityDelay = 0.6
let earnedScoresOpacityDuration = placeInTeamTextOpacityDuration
let earnedScoresOpacityDelay = placeInTeamTextOpacityDelay + 0.1
let placeIconDelay = placeInTeamTextOpacityDelay + 0.5
let placeIconDuration = 0.4

let winBgColor = 0x66663900
let failBgColor = 0x66550101
let whiteBgColor = 0xFFFFFF
let noBgColor = 0x00000000
let blackBgColor = 0xFF000000

let gap = hdpx(10)
let scoresGap = hdpx(100)
let scoresTextWidth = (saSize[0] - scoresGap) / 2
let scoresContentWidth = scoresTextWidth
let missionResult = Watched(null)
let needShowResultScreen = Computed(@() missionResult.value == GO_WIN || missionResult.value == GO_FAIL)
let streakSize = hdpx(70)

let scoresByCampaign = {
  ships = [
    {
      name = "damage"
      locId = "debriefing/damageDealt"
    }
  ]
  tanks = [
    {
      name = "score"
      locId = "debriefing/totalscore"
    }
    {
      name = "groundKills"
      locId = "debriefing/GroundKills"
    }
  ]
}

let resultLocId = {
  [GO_WIN] = "debriefing/victory",
  [GO_FAIL] = "debriefing/defeat"
}

let textBgColor = Watched(whiteBgColor)
let showText = Watched(false)
let animatedTextBlock = @() {
  watch = [showText, missionResult, textBgColor]
  size = flex()
  rendObj = ROBJ_9RECT
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = textBgColor.value
  image = gradTranspDoubleSideX
  texOffs = [0 , gradDoubleTexOffset]
  screenOffs = [0, hdpx(250)]
  transform = {}
  transitions = [{ prop = AnimProp.color, duration = changeTextBgColorDuration }]
  animations = [
    { prop = AnimProp.scale, from = [0.7, 0.1], to = [0.8, 0.1], duration = textBlockBounceDuration / 3,
      easing = InQuad, play = true }
    { prop = AnimProp.scale, from = [0.8, 0.1], to = [1.0, 1.0], duration = textBlockBounceDuration / 3,
      easing = InQuad, play = true, delay = textBlockBounceDuration / 3 }
    { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.05, 1.2], duration = textBlockBounceDuration / 3,
      easing = CosineFull, play = true, delay = (textBlockBounceDuration / 3) * 2,
      onFinish = @() textBgColor(missionResult.value == GO_FAIL ? failBgColor : winBgColor) }
  ]
  children =
    showText.value
      ? @() {
        watch = missionResult
        rendObj = ROBJ_TEXT
        text = $"{loc(resultLocId?[missionResult.value] ?? "")}!"
        transform = {}
        animations = opacityAnims(missionResultOpacityDuration, 0)
          .append({
            prop = AnimProp.scale, from = [1.0, 1.0], to = [1.15, 1.15], duration = missionResultScaleDuration,
            easing = InQuad, play = true
          })
      }.__update(fontVeryLargeShaded)
      : {
        size = [pw(60), hdpx(50)]
        rendObj = ROBJ_9RECT
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        image = gradTranspDoubleSideX
        texOffs = [0 , gradDoubleTexOffset]
        screenOffs = [0, hdpx(250)]
        transform = { scale = [0.2, 1] }
        animations = [
          { prop = AnimProp.scale, to = [1, 1], duration = textAppearanceDuration,
            easing = InQuad, delay = textAppearanceDelay, play = true, onFinish = @() showText(true) }
        ]
      }
}

let resultTextBlock = @() {
  watch = textBgColor
  rendObj = ROBJ_BOX
  children = animatedTextBlock
  size = [flex(), hdpx(180)]
  borderColor = textBgColor.value == whiteBgColor ? noBgColor : blackBgColor
  borderWidth = [8, 0]
  transitions = [{ prop = AnimProp.borderColor, duration = borderColorTransitionDuration}]
}

let mkUserScores = @(valueCtor, locId) {
  size = [saSize[0], SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = scoresGap
  animations = opacityAnims(earnedScoresOpacityDuration, earnedScoresOpacityDelay)
  children = [
    {
      halign = ALIGN_RIGHT
      size = [scoresTextWidth, SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXT
      text = "".concat(loc(locId), colon)
    }.__update(fontSmall)
    {
      size = [SIZE_TO_CONTENT, playerPlaceIconSize]
      halign = ALIGN_LEFT
      valign = ALIGN_CENTER
      children = valueCtor
      transform = {}
      animations = [
        { prop = AnimProp.scale, to = [1.25, 1.25], duration = placeIconDuration / 2,
          easing = InQuad, delay = placeIconDelay, play = true,
          sound = { start = "place" }}
        { prop = AnimProp.scale, from = [1.25, 1.25], to = [1, 1], play = true,
          delay = placeIconDelay + placeIconDuration / 2,
          duration = placeIconDuration / 2, easing = InQuad }
      ]
    }
  ]
}

let achievements = function(streaks) {
  let itemOffset = @(children, idx, offset) {
    key = {}
    transform = { translate = [idx * offset, 0] }
    children
  }
  let streaksArr = prepareStreaksArray(streaks)
  let streaksArrSize = streaksArr.len()
  local offset = streakSize
  if (offset * streaksArrSize > scoresContentWidth)
    offset = scoresContentWidth / streaksArrSize;

  return streaksArr.map(@(val, idx) itemOffset(mkStreakWithMultiplier(val.id, val?.completed ?? 0, streakSize, val?.stage), idx, offset))
}

let achievementsBlock = @() {
  watch = [debriefingData]
  children = 0 < (debriefingData.value?.streaks.len() ?? 0)
    ? mkUserScores(achievements(debriefingData.value?.streaks), loc("debriefing/Unlocks"))
    : null
}

let function battleResultsShort() {
  let res = { watch = needShowResultScreen }
  let children = !isPlaceVisible.value ? []
                 : [ mkUserScores(mkPlaceIcon(myPlace.value), loc("debriefing/placeInMyTeam")) ]
                   .extend(scoresByCampaign?[battleCampaign.value]
                     .map(function(v) {
                       let mul = viewMuls?[v.name] ?? 1.0
                       let score = localPlayerDamageStats.value?[v.name] ?? get_local_mplayer()?[v.name] ?? 0
                       return mkUserScores(mkImageWithCount(mul * score, icons?[v.name]), v.locId)
                     }))
  children.append(achievementsBlock)

  if (needShowResultScreen.value)
    res.__update({
      rendObj = ROBJ_SOLID
      color = 0xAA000000
      size = flex()
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap
      children = [
        resultsHintsBlock
        resultTextBlock
        @() {
          watch = [battleCampaign, isPlaceVisible, localPlayerDamageStats, myPlace]
          flow = FLOW_VERTICAL
          gap
          children
        }
      ]
    })

  return res
}

eventbus.subscribe("MissionResult", function(data) {
  let { resultNum } = data
  if (resultNum != GO_WIN && resultNum != GO_FAIL)
    return
  let soundName = resultNum == GO_WIN ? "message_win" : "message_loose"
  playSound(soundName)
  eventbus.send("MpStatistics_GetTeamsList", {})
  missionResult(resultNum)
})

isInBattle.subscribe(@(v) v ? missionResult(null) : null)
isInDebriefing.subscribe(@(v) v ? missionResult(null) : null)
needShowResultScreen.subscribe(@(v) !v ? resultsHintLogState.clearEvents() : null)

return battleResultsShort
