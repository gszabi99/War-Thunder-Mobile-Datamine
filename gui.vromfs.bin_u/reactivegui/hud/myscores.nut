from "%globalsDarg/darg_library.nut" import *
let { clearTimer, setInterval } = require("dagor.workcycle")
let { get_local_mplayer } = require("mission")
let { mkPlaceIcon, playerPlaceIconSize } = require("%rGui/components/playerPlaceIcon.nut")
let { shortTextFromNum } = require("%rGui/textFormatByLang.nut")
let { battleCampaign } = require("%appGlobals/clientState/missionState.nut")
let { playerTeamDamageStats, localPlayerDamageStats } = require("%rGui/mpStatistics/playersDamageStats.nut")
let { getScoreKey, getScoreKeyAir } = require("%rGui/mpStatistics/playersSortFunc.nut")
let { hudScoreTank } = require("%rGui/options/options/tankControlsOptions.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")

let countImageSize = evenPx(60)
let counterBgSize = evenPx(40)
let counterOffsets = hdpx(8)
let blinkTime = 0.3
let scoreTrigger = {}
let localMPlayer = Watched(null)

let icons = {
  damage = "ui/gameuiskin#damage_icon.svg"
  score = "ui/gameuiskin#score_icon.svg"
  groundKills = "ui/gameuiskin#tanks_destroyed_icon.svg"
  kills = "ui/gameuiskin#stats_airplanes_destroyed.svg"
}

let viewMuls = {
  score = 100.0
}

let scoreKey = Computed(@() battleCampaign.get() == "air"
  ? getScoreKeyAir(curUnit.get()?.unitClass)
  : getScoreKey(battleCampaign.value))

function getViewScoreKey(campaign, scoreTank, unit){
  if(campaign == "tanks" && scoreTank == "kills")
    return "groundKills"
  if(campaign == "air")
    return getScoreKeyAir(unit?.unitClass)
  return getScoreKey(campaign)
}
let viewScoreKey = Computed(@() getViewScoreKey( battleCampaign.get(), hudScoreTank.get(), curUnit.get()))

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

let mkValueText = @(value) {
  rendObj = ROBJ_TEXT
  text = shortTextFromNum(value.tointeger())
  transform = {}
  animations = [{
    prop = AnimProp.scale, from = [1.0, 1.0], to = [1.4, 1.4], easing = Blink
    duration = blinkTime, trigger = scoreTrigger
  }]
}.__update(fontVeryTiny)

let mkImageWithCount = @(value, image) {
  size = [playerPlaceIconSize, playerPlaceIconSize]
  halign = ALIGN_CENTER
  children = [
    {
      size = [countImageSize, countImageSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"{image}:{countImageSize}:{countImageSize}:P")
      keepAspect = true
      imageValign = ALIGN_CENTER
    }
    {
      minWidth = hdpx(70)
      padding = [hdpx(3), hdpx(8), hdpx(4), hdpx(8)]
      vplace = ALIGN_BOTTOM

      rendObj = ROBJ_9RECT
      image = Picture($"ui/gameuiskin#hud_counter.svg:{counterBgSize}:{counterBgSize}:P")
      screenOffs = counterOffsets
      texOffs = counterOffsets

      halign = ALIGN_CENTER
      children = value instanceof Watched
        ? @() mkValueText(value.value).__update({ watch = value})
        : mkValueText(value)
    }
  ]
}

let mkMyScores = @(score) mkImageWithCount(score, icons.score)
let mkMyDamage = @(score) mkImageWithCount(score, icons.damage)
let mkTankMyScores = @(score) @()
  mkImageWithCount(score, hudScoreTank.value == "kills" ? icons.groundKills : icons.score)
    .__update({ watch = hudScoreTank })
let mkAirMyScores = @(score) @()
  mkImageWithCount(score, curUnit.get()?.unitClass == "fighter" ? icons.kills : icons.score)
    .__update({ watch = curUnit })


let myPlaceUi = @() {
  watch = [isPlaceVisible, myPlace]
  children = !isPlaceVisible.value ? null
    : mkPlaceIcon(myPlace.value).__update({
        key = myPlace.value
        transform = {}
        animations = [{
          prop = AnimProp.scale, from = [1.0, 1.0], to = [1.4, 1.4], easing = Blink
          duration = blinkTime, play = true
        }]
      })
}

function updateLocalMPlayerForScore() {
  if (viewScoreKey.value != "score" && viewScoreKey.value != "damage")
    localMPlayer(get_local_mplayer())
}

function myScoresUi() {
  let res = { watch = [viewScoreKey, isPlaceVisible] }
  if (!isPlaceVisible.value)
    return res

  let key = viewScoreKey.value
  let mul = viewMuls?[key] ?? 1.0
  local score = Computed(@() mul * (localPlayerDamageStats.value?[key] ?? localMPlayer.value?[key] ?? 0))
  score.subscribe(@(_) anim_start(scoreTrigger))

  return res.__update({
    children = mkImageWithCount(score, icons?[key] ?? icons.score)
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

  myPlaceUi
  myScoresUi
}