from "%globalsDarg/darg_library.nut" import *
let { clearTimer, setInterval } = require("dagor.workcycle")
let { get_local_mplayer } = require("mission")
let { getScaledFont, scaleFontWithTransform } = require("%globalsDarg/fontScale.nut")
let { mkPlaceIcon, playerPlaceIconSize } = require("%rGui/components/playerPlaceIcon.nut")
let { shortTextFromNum } = require("%rGui/textFormatByLang.nut")
let { battleCampaign, battleUnitClasses } = require("%appGlobals/clientState/missionState.nut")
let { playerTeamDamageStats, localPlayerDamageStats } = require("%rGui/mpStatistics/playersDamageStats.nut")
let { getScoreKey } = require("%rGui/mpStatistics/playersSortFunc.nut")
let { hudScoreTank } = require("%rGui/options/options/tankControlsOptions.nut")
let { playerUnitName } = require("%rGui/hudState.nut")

let countImageSize = evenPx(60)
let counterBgSize = evenPx(40)
let counterOffsets = hdpx(8)
let blinkTime = 0.3
let scoreTrigger = {}
let localMPlayer = Watched(null)
let defValueFont = fontVeryTiny

let icons = {
  damage = "ui/gameuiskin#damage_icon.svg"
  score = "ui/gameuiskin#score_icon.svg"
  groundKills = "ui/gameuiskin#tanks_destroyed_icon.svg"
  kills = "ui/gameuiskin#stats_airplanes_destroyed.svg"
}

let viewMuls = {
  score = 100.0
}

let scoreKey = Computed(@() getScoreKey(battleCampaign.get()))

function getViewScoreKey(campaign, unitClass, scoreTank) {
  if (campaign == "tanks" && scoreTank == "kills")
    return "groundKills"
  if (campaign == "air" && unitClass == "fighter")
    return "kills"
  return getScoreKey(campaign)
}
let curUnitClass = Computed(@() battleUnitClasses.get()?[playerUnitName.get()] ?? "")
let viewScoreKey = Computed(@() getViewScoreKey(battleCampaign.get(), curUnitClass.get(), hudScoreTank.get()))

let myPlace = Computed(function() {
  let key = scoreKey.value
  let myValue = localPlayerDamageStats.value?[key] ?? 0
  if (myValue <= 0)
    return -1
  local res = 1
  foreach(data in playerTeamDamageStats.value)
    if ((data?[key] ?? 0) > myValue)
      res++
  return res
})

let isPlaceVisible = Computed(@() myPlace.value > 0)

let mkValueText = @(value, font = defValueFont) {
  rendObj = ROBJ_TEXT
  text = shortTextFromNum(value.tointeger())
  transform = {}
  animations = [{
    prop = AnimProp.scale, from = [1.0, 1.0], to = [1.4, 1.4], easing = Blink
    duration = blinkTime, trigger = scoreTrigger
  }]
}.__update(font)

function mkImageWithCount(value, image, scale = 1) {
  let imgSize = scaleEven(countImageSize, scale)
  let font = getScaledFont(defValueFont, scale)
  return {
    size = array(2, scaleEven(playerPlaceIconSize, scale))
    halign = ALIGN_CENTER
    children = [
      {
        size = [imgSize, imgSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"{image}:{imgSize}:{imgSize}:P")
        keepAspect = true
        imageValign = ALIGN_CENTER
      }
      {
        minWidth = scaleEven(hdpx(70), scale)
        padding = [hdpx(3), hdpx(8), hdpx(4), hdpx(8)]
        vplace = ALIGN_BOTTOM

        rendObj = ROBJ_9RECT
        image = Picture($"ui/gameuiskin#hud_counter.svg:{counterBgSize}:{counterBgSize}:P")
        screenOffs = counterOffsets
        texOffs = counterOffsets

        halign = ALIGN_CENTER
        children = value instanceof Watched
          ? @() mkValueText(value.value, font).__update({ watch = value})
          : mkValueText(value, font)
      }
    ]
  }
}

let mkMyScores = @(score) mkImageWithCount(score, icons.score)
let mkMyDamage = @(score) mkImageWithCount(score, icons.damage)
let mkTankMyScores = @(score) @()
  mkImageWithCount(score, hudScoreTank.value == "kills" ? icons.groundKills : icons.score)
    .__update({ watch = hudScoreTank })
let mkAirMyScores = @(score) mkImageWithCount(score, icons.kills)


function mkMyPlaceUi(scale) {
  let size = scaleEven(playerPlaceIconSize, scale)
  let font = scaleFontWithTransform(fontTiny, scale, [0.5, 0.5])
  return @() {
    watch = [isPlaceVisible, myPlace]
    children = !isPlaceVisible.value ? null
      : mkPlaceIcon(myPlace.get(), size, font)
          .__update({
            key = myPlace.value
            transform = {}
            animations = [{
              prop = AnimProp.scale, from = [1.0, 1.0], to = [1.4, 1.4], easing = Blink
              duration = blinkTime, play = true
            }]
          })
  }
}

function updateLocalMPlayerForScore() {
  if (viewScoreKey.value != "score" && viewScoreKey.value != "damage")
    localMPlayer(get_local_mplayer())
}

let mkMyScoresUi = @(scale) function() {
  let res = { watch = [viewScoreKey, isPlaceVisible] }
  if (!isPlaceVisible.value)
    return res

  let key = viewScoreKey.value
  let mul = viewMuls?[key] ?? 1.0
  local score = Computed(@() mul * (localPlayerDamageStats.value?[key] ?? localMPlayer.value?[key] ?? 0))
  score.subscribe(@(_) anim_start(scoreTrigger))

  return res.__update({
    children = mkImageWithCount(score, icons?[key] ?? icons.score, scale)
      .__update({
        key = viewScoreKey
        function onAttach() {
          updateLocalMPlayerForScore()
          setInterval(1.0, updateLocalMPlayerForScore)
        }
        onDetach = @() clearTimer(updateLocalMPlayerForScore)
      })
  })
}

return {
  myPlace
  isPlaceVisible
  icons
  viewMuls

  mkMyScores
  mkMyDamage
  mkTankMyScores
  mkAirMyScores
  mkMyPlace = mkPlaceIcon
  mkImageWithCount

  mkMyPlaceUi
  mkMyScoresUi
}