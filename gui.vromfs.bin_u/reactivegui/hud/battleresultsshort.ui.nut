from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "guiMission" import GO_WIN, GO_FAIL
from "mission" import get_local_mplayer
from "sound_wt" import playSound
from "%appGlobals/clientState/clientState.nut" import isInDebriefing, isInBattle
from "%appGlobals/clientState/missionState.nut" import battleCampaign
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%rGui/components/playerPlaceIcon.nut" import mkPlaceIcon, playerPlaceIconSize
from "%rGui/debriefing/debriefingState.nut" import debriefingData
from "%rGui/hud/hudEventManager.nut" import subscribeHudEvent
from "%rGui/hud/myScores.nut" import mkImageWithCount, myPlace, isPlaceVisible, icons
from "%rGui/hudHints/hintBlocks.nut" import resultsHintsBlock
import "%rGui/hudHints/resultsHintLogState.nut" as resultsHintLogState
from "%rGui/missionState.nut" import isGtFFA
from "%rGui/mpStatistics/playersDamageStats.nut" import localPlayerDamageStats
from "%rGui/mpStatistics/playersSortFunc.nut" import getScoreFull
from "%rGui/shop/goodsPreview/goodsPreviewPkg.nut" import opacityAnims
from "%rGui/style/gradients.nut" import gradTranspDoubleSideX, gradDoubleTexOffset
from "%rGui/style/hudColors.nut" import hudWhiteColor, hudBlackColor, hudTransparentColor, hudDarkRedFade,
  hudBurgundyFade
from "%rGui/unlocks/streakPkg.nut" import mkStreakWithMultiplier, prepareStreaksArray


const changeTextBgColorDuration = 0.1
const textBlockBounceDuration = 0.3
const missionResultScaleDuration = 0.1
const missionResultOpacityDuration = 0.1
const textAppearanceDuration = 0.2
const textAppearanceDelay = textBlockBounceDuration
const borderColorTransitionDuration = 0.1
const placeInTeamTextOpacityDuration = 0.1
const placeInTeamTextOpacityDelay = 0.6
const earnedScoresOpacityDuration = placeInTeamTextOpacityDuration
const earnedScoresOpacityDelay = placeInTeamTextOpacityDelay + 0.1
const placeIconDelay = placeInTeamTextOpacityDelay + 0.5
const placeIconDuration = 0.4

let winBgColor = hudDarkRedFade
let failBgColor = hudBurgundyFade
let whiteBgColor = hudWhiteColor
let noBgColor = hudTransparentColor
let blackBgColor = hudBlackColor

const gap = hdpx(10)
const scoresGap = hdpx(100)
let scoresTextWidth = (saSize[0] - scoresGap) / 2
let scoresContentWidth = scoresTextWidth
const streakSize = hdpx(70)

let missionResult = Watched(null)
let needShowResultScreen = Computed(@() missionResult.get() == GO_WIN || missionResult.get() == GO_FAIL)

isInBattle.subscribe(@(v) v ? missionResult.set(null) : null)
isInDebriefing.subscribe(@(v) v ? missionResult.set(null) : null)
needShowResultScreen.subscribe(@(v) !v ? resultsHintLogState.clearEvents() : null)

let scoresByCampaign = {
  ships = [
    {
      getFromStats = getScoreFull
      locId = "debriefing/totalscore"
      iconId = "score"
    }
    {
      getFromStats = @(p) p?.damage ?? 0
      locId = "debriefing/damageDealt"
      iconId = "damage"
    }
  ]
  tanks = [
    {
      getFromStats = getScoreFull
      locId = "debriefing/totalscore"
      iconId = "score"
    }
    {
      getFromPlayer = @(p) p?.groundKills ?? 0
      locId = "debriefing/GroundKills"
      iconId = "groundKills"
    }
  ]
  air = [
    {
      getFromStats = getScoreFull
      locId = "debriefing/totalscore"
      iconId = "score"
    }
    {
      getFromPlayer = @(p) p?.kills ?? 0
      locId = "debriefing/AirKills"
      iconId = "kills"
    }
  ]
}

let resultText = {
  [GO_WIN]  = "".concat(loc("debriefing/victory"), "!"),
  [GO_FAIL] = "".concat(loc("debriefing/defeat"), "!"),
}
let resultTextFFA = {
  [GO_WIN]  = "".concat(loc("debriefing/victory"), "!"),
  [GO_FAIL] = "".concat(loc("MISSION_FINISHED"), "!"),
}
let getResultText = @(resultNum, isFFA) resultNum == null ? ""
  : (isFFA ? resultTextFFA : resultText)[resultNum]

let textBgColor = Watched(whiteBgColor)
let showText = Watched(false)
let animatedTextBlock = @() {
  watch = [showText, textBgColor]
  size = FLEX
  rendObj = ROBJ_9RECT
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = textBgColor.get()
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
      onFinish = @() textBgColor.set(missionResult.get() == GO_WIN || isGtFFA.get() ? winBgColor : failBgColor) }
  ]
  children =
    showText.get()
      ? @() {
          watch = [missionResult, isGtFFA]
          rendObj = ROBJ_TEXT
          text = getResultText(missionResult.get(), isGtFFA.get())
          transform = {}
          animations = opacityAnims(missionResultOpacityDuration, 0)
            .append({
              prop = AnimProp.scale, from = [1.0, 1.0], to = [1.15, 1.15], duration = missionResultScaleDuration,
              easing = InQuad, play = true
            })
        }.__update(fontVeryLargeShaded)
      : {
          size = const [pw(60), hdpx(50)]
          rendObj = ROBJ_9RECT
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          image = gradTranspDoubleSideX
          texOffs = [0, gradDoubleTexOffset]
          screenOffs = [0, hdpx(250)]
          transform = { scale = [0.2, 1] }
          animations = [
            { prop = AnimProp.scale, to = [1, 1], duration = textAppearanceDuration,
              easing = InQuad, delay = textAppearanceDelay, play = true, onFinish = @() showText.set(true) }
          ]
        }
}

let resultTextBlock = @() {
  watch = textBgColor
  rendObj = ROBJ_BOX
  children = animatedTextBlock
  size = const [FLEX, hdpx(180)]
  borderColor = textBgColor.get() == whiteBgColor ? noBgColor : blackBgColor
  borderWidth = const [8, 0]
  transitions = [{ prop = AnimProp.borderColor, duration = borderColorTransitionDuration}]
}

let mkUserScoresText = @(text) {
  size = [scoresTextWidth, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
  text
}.__update(fontSmall)

let mkUserScores = @(valueComp, locId) {
  size = [saSize[0], SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = scoresGap
  animations = opacityAnims(earnedScoresOpacityDuration, earnedScoresOpacityDelay)
  children = [
    mkUserScoresText("".concat(loc(locId), colon)).__update({ halign = ALIGN_RIGHT })
    {
      size = [SIZE_TO_CONTENT, playerPlaceIconSize]
      halign = ALIGN_LEFT
      valign = ALIGN_CENTER
      children = valueComp
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
  children = 0 < (debriefingData.get()?.streaks.len() ?? 0)
    ? mkUserScores(achievements(debriefingData.get()?.streaks), "debriefing/Unlocks")
    : null
}

function battleResultsShort() {
  let res = {
    watch = [
      needShowResultScreen,
      battleCampaign,
      isPlaceVisible,
      localPlayerDamageStats,
      myPlace
    ]
  }
  if (!needShowResultScreen.get())
    return res

  let children = !isPlaceVisible.get() ? []
    : [mkUserScores(mkPlaceIcon(myPlace.get()), "debriefing/placeInMyTeam")]
        .extend((scoresByCampaign?[getCampaignPresentation(battleCampaign.get()).campaign] ?? [])
          .map(function(v) {
            let score = v?.getFromStats(localPlayerDamageStats.get())
                ?? v?.getFromPlayer(get_local_mplayer())
                ?? 0
            return mkUserScores(mkImageWithCount(score, icons?[v.iconId] ?? icons.score), v.locId)
          }))
  children.append(achievementsBlock)

  let baseResults = {
    size = FLEX
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap
    children = [
      resultsHintsBlock
      resultTextBlock
      {
        flow = FLOW_VERTICAL
        gap
        children
      }
    ]
  }

  return res.__update({
    rendObj = ROBJ_SOLID
    color = 0xAA000000
    size = FLEX
    padding = saBordersRv
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = baseResults
  })
}

function openResult(resultNum) {
  let soundName = resultNum == GO_WIN || isGtFFA.get() ? "message_win" : "message_loose"
  playSound(soundName)
  missionResult.set(resultNum)
}

subscribeHudEvent("MissionResult", function(data) {
  let { resultNum } = data
  if (resultNum == GO_WIN || resultNum == GO_FAIL)
    openResult(resultNum)
})

let toggleResult = @(resultNum) missionResult.get() == resultNum
  ? missionResult.set(null)
  : openResult(resultNum)

register_command(@() toggleResult(GO_WIN), "hud.showShortBattleResultWin")
register_command(@() toggleResult(GO_FAIL), "hud.showShortBattleResultFail")

return battleResultsShort
