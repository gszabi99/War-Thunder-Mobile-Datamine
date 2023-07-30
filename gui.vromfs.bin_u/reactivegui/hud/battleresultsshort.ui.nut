from "%globalsDarg/darg_library.nut" import *
let eventbus = require("eventbus")
let { GO_WIN, GO_FAIL } = require("guiMission")
let { playSound } = require("sound_wt")
let { gradTranspDobuleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let playersSortFunc = require("%rGui/mpStatistics/playersSortFunc.nut")
let { battleCampaign } = require("%appGlobals/clientState/missionState.nut")
let { playersDamageStats, requestPlayersDamageStats } = require("%rGui/mpStatistics/playersDamageStats.nut")
let { opacityAnims } = require("%rGui/shop/goodsPreview/goodsPreviewPkg.nut")
let { setTimeout } = require("dagor.workcycle")

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
let iconPlaceDimension = hdpxi(130)

let localTeamListBase = Watched([])
let localTeamList = Computed(function() {
  let res = localTeamListBase.value.map(function(p) {
    let { damage = 0.0, score = 0.0 } = playersDamageStats.value?[p.id.tostring()]
    return p.__merge({ damage, score })
  })
  return res.sort(playersSortFunc(battleCampaign.value))
})
let missionResult = Watched(null)
let needShowResultScreen = Computed(@() missionResult.value == GO_WIN || missionResult.value == GO_FAIL)
let localUserPlace = Computed(function() {
  let localUserIndex = localTeamList.value.findindex(@(player) player.isLocal)
  return localUserIndex != null ? localUserIndex + 1 : null
})
let localUserScores = Computed(function() {
  let player = localTeamList.value.findvalue(@(p) p.isLocal)
  return player == null ? null
    : battleCampaign.value == "tanks" ? {
      text = loc("debriefing/earnedScores")
      value = (player?.score ?? 0) * 100
      }
    : {
      text = $"{loc("debriefing/damageDealt")}{colon}"
      value = (player?.damage ?? 0).tointeger()
    }
})

let iconForUserPosition = Computed(@() localUserPlace.value == 1 ? "ui/gameuiskin#player_rank_badge_gold.avif"
    : localUserPlace.value == 2 ? "ui/gameuiskin#player_rank_badge_silver.avif"
    : localUserPlace.value == 3 ? "ui/gameuiskin#player_rank_badge_bronze.avif"
    : null)

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
  image = gradTranspDobuleSideX
  texOffs = [0 , gradDoubleTexOffset]
  screenOffs = [0, hdpx(250)]
  transform = {}
  transitions = [{ prop = AnimProp.color, duration = changeTextBgColorDuration }]
  animations = [
    { prop = AnimProp.scale, from = [0.3, 0.1], to = [0.8, 0.1], duration = textBlockBounceDuration / 3,
      easing = InQuad, play = true }
    { prop = AnimProp.scale, from = [0.8, 0.1], to = [1.0, 1.0], duration = textBlockBounceDuration / 3,
      easing = InQuad, play = true, delay = textBlockBounceDuration / 3 }
    { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.05, 1.2], duration = textBlockBounceDuration / 3,
      easing = CosineFull, play = true, delay = (textBlockBounceDuration / 3) * 2,
      onFinish = @() textBgColor(missionResult.value == GO_FAIL ? failBgColor : winBgColor) }
  ]
  children = [
    showText.value
        ? {
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
        image = gradTranspDobuleSideX
        texOffs = [0 , gradDoubleTexOffset]
        screenOffs = [0, hdpx(250)]
        transform = { scale = [0.2, 1] }
        animations = [
          { prop = AnimProp.scale, to = [1, 1], duration = textAppearanceDuration,
            easing = InQuad, delay = textAppearanceDelay, play = true, onFinish = @() showText(true) }
        ]
      }
  ]
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

eventbus.subscribe("MpStatistics_TeamsList", @(teams) localTeamListBase(teams?.data[0]))

let placeInTeam = @() {
  watch = [iconForUserPosition, localUserPlace]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = sh(localUserPlace.value > 3 ? 0 : 5)
  animations = opacityAnims(placeInTeamTextOpacityDuration, placeInTeamTextOpacityDelay)
  children = [
    { rendObj = ROBJ_TEXT, text = loc("debriefing/placeInMyTeam") }.__update(fontSmallAccented)
    {
      transform = {}
      animations = [
        { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.25, 1.25], duration = placeIconDuration / 2,
          easing = InQuad, delay = placeIconDelay, play = true,
          sound = { start = setTimeout(placeIconDelay, @() playSound("place"))}}
        { prop = AnimProp.scale, from = [1.25, 1.25], to = [1, 1], play = true,
          delay = placeIconDelay + placeIconDuration / 2,
          duration = placeIconDuration / 2, easing = InQuad }
      ]
      children = [
        iconForUserPosition.value
          ? {
          rendObj = ROBJ_IMAGE,
          size = [iconPlaceDimension, iconPlaceDimension]
          image = Picture($"{iconForUserPosition.value}:{iconPlaceDimension}")
          transform = {}
          } : null
        { rendObj = ROBJ_TEXT, text = localUserPlace.value,
          size = [iconPlaceDimension, iconPlaceDimension],
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER,
          fontFx = FFT_GLOW
        }.__update(fontSmallAccented)
      ]
    }
  ]
}

let earnedScores = @(text, value) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = sh(2)
  animations = opacityAnims(earnedScoresOpacityDuration, earnedScoresOpacityDelay)
  children = [
    { rendObj = ROBJ_TEXT, text = text }.__update(fontSmall)
    { rendObj = ROBJ_TEXT, text = value }.__update(fontSmall)
  ]
}

let function battleResultsShort() {
  let res = { watch = needShowResultScreen }

  if (needShowResultScreen.value)
    res.__update({
      rendObj = ROBJ_SOLID
      color = 0xAA000000
      size = flex()
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      children = [
        resultTextBlock
        @() {
          watch = localUserScores
          flow = FLOW_VERTICAL
          children = [
            placeInTeam
            localUserScores.value ? earnedScores(localUserScores.value.text, localUserScores.value.value) : null
          ]
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
  requestPlayersDamageStats()
  missionResult(resultNum)
})

return battleResultsShort
