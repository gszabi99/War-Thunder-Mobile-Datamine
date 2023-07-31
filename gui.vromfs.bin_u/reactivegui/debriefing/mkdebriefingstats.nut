from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { doesLocTextExist } = require("dagor.localize")
let { lerpClamped } = require("%sqstd/math.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { orderByItems } = require("%appGlobals/itemsState.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let playersSortFunc = require("%rGui/mpStatistics/playersSortFunc.nut")
let { gradRadial } = require("%rGui/style/gradients.nut")
let { startSound, stopSound } = require("sound_wt")
let { setTimeout, resetTimeout } = require("dagor.workcycle")

let statIncreaseAnimTimeMsec = 500
let iconSize = hdpxi(30)
let playerPlaceIconSize = [hdpx(80), hdpx(80)]
let endHeaderLineAnim = 1.0
let offsetTime = 0.1

let function playerPlaceCtor (place, startTimeMSec){
  let startTimeSec =  0.001 * (startTimeMSec - get_time_msec())
  return {
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_RIGHT
    valign = ALIGN_CENTER
    children = [
      {
        pos = [hdpx(7), 0]
        size = [hdpx(30), hdpx(30)]
        rendObj = ROBJ_IMAGE
        image = gradRadial
        color = place == 1 ? 0x40ffdb7b
          : place == 2 ? 0x407be1ff
          : 0x40ffb67b
        transform = {}
        animations = [
          {
            prop = AnimProp.scale, from = [1, 1], to = [5, 5],
            duration = 0.5, easing = CosineFull,  delay = startTimeSec, play = true
          }
        ]
      }
      {
        pos = [hdpx(33), 0]
        hplace = ALIGN_RIGHT
        size = playerPlaceIconSize
        rendObj = ROBJ_IMAGE
        image = place == 1 ? Picture("!ui/gameuiskin#player_rank_badge_gold.avif")
          : place == 2 ? Picture("!ui/gameuiskin#player_rank_badge_silver.avif")
          : Picture("!ui/gameuiskin#player_rank_badge_bronze.avif")
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = {
          rendObj = ROBJ_TEXT
          text = place
        }.__update(fontVeryTiny)
        transform = {}
        animations = [
          {
            prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3],
            duration = 0.5, easing = CosineFull, delay = startTimeSec, play = true
          }
        ]
      }
    ]
  }
}

let statsByCamp = {
  ships = [
    { locId = "debriefing/damageDealt", getVal = @(reward, _) reward?.damage.tointeger() ?? 0 }
    { locId = "debriefing/NavalKills", getVal = @(_, player) player?.navalKills ?? 0 }
    { locId = "debriefing/PlayerPlace", getVal = @(_,player) player?.place , valueCtor = playerPlaceCtor}
  ],

  tanks = [
    { locId = "debriefing/totalscore", getVal = @(reward, _) (100 * (reward?.dmgScoreBonus ?? 0)).tointeger() }
    { locId = "debriefing/GroundKills", getVal = @(_, player) player?.groundKills ?? 0 }
    { locId = "debriefing/AirKills", getVal = @(_, player) (player?.kills ?? 0) <= 0 ? null : player.kills }
    { locId = "debriefing/Captures", getVal = @(_, player) player?.captures ?? 0 }
    { locId = "debriefing/PlayerPlace", getVal = @(_, player) player?.place,  valueCtor = playerPlaceCtor}
  ],
}

let statsByCampSingle = {
  ships = [
    { locId = "debriefing/NavalKills", getVal = @(_, player) (player?.kills ?? 0) <= 0 ? null : player.kills }
  ],

  tanks = [
    { locId = "debriefing/GroundKills", getVal = @(_, player) (player?.kills ?? 0) <= 0 ? null : player.kills }
  ],
}

let stopCountSound = @() stopSound("coin_counter")

local maxSoundEndTime = 0
let function animatedCountSound(soundStartTime, soundEndTime, value) {
  if (value == 0)
    return
  if (soundEndTime > maxSoundEndTime)
    maxSoundEndTime = soundEndTime
  if (soundStartTime <= 0)
    startSound("coin_counter")
  else
    setTimeout(soundStartTime, @() startSound("coin_counter"))
  resetTimeout(maxSoundEndTime, stopCountSound)
}

let function mkAnimatedCount(value, startTime, ovr = {}) {
  let endTime = startTime + statIncreaseAnimTimeMsec
  let soundStartTime = (startTime - get_time_msec()) * 0.001
  let soundEndTime = (endTime - get_time_msec()) * 0.001
  return {
    size = flex()
    rendObj = ROBJ_TEXT
    halign = ALIGN_RIGHT
    color = 0xFFFFFFFF
    text = 0
    behavior = Behaviors.RtPropUpdate
    onAttach = @() animatedCountSound(soundStartTime, soundEndTime, value)
    onDetach = stopCountSound
    update = function() {
      let curTime = get_time_msec()
      if (curTime < startTime)
        return null
      return {
        text = curTime >= endTime ? decimalFormat(value)
          : decimalFormat(lerpClamped(startTime, endTime, 0, value, curTime).tointeger())
      }
    }
  }.__update(fontTiny, ovr)
}

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  color = 0xFFFFFFFF
  text
}.__update(fontTiny)

let mkStat = @(text, value, startTime, valueCtor)
{
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      text
      color = 0xFFFFFFFF
      hplace = ALIGN_LEFT
    }.__update(fontTiny),
    (valueCtor ?? mkAnimatedCount)(value, startTime)
  ]
}

let function mkItemsUsedRows(itemsUsed, startTime) {
  let items = []
  foreach (id, data in itemsUsed)
    items.append(data.__merge({ id, order = orderByItems?[id] ?? orderByItems.len() }))
  items.sort(@(a, b) a.order <=> b.order)
  return items.map(function(item, i) {
    let start = startTime + offsetTime * 1000 * i
    let { id, count = 0, used = 0 } = item
    local locId = $"debriefing/spent/{id}"
    if (!doesLocTextExist(locId))
      locId = "debriefing/spent/default"
    let usedWidth = max(calc_str_box(decimalFormat(used), fontTiny)[0],
                        calc_str_box(decimalFormat(0),    fontTiny)[0])
    return {
      size = [hdpx(570), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children =
        mkTextRow(loc(locId, { count = used }),
          mkText,
          {
            ["{countAnim}"] = mkAnimatedCount(used, start,//warning disable: -forgot-subst
              { size = [usedWidth, SIZE_TO_CONTENT], halign = ALIGN_CENTER })
          })
        .append(
          mkAnimatedCount(count, start)
          mkCurrencyImage(id, iconSize, {margin = [0, 0, 0, hdpx(5)]})
        )
    }
  })
}

let function mkDebriefingStats(data, startAnimTime) {
  let { isSingleMission = false, reward = {}, players = {}, userId = -1, campaign = "",
    itemsUsed = {}, userName = ""} = data
  let stats = (isSingleMission ? statsByCampSingle : statsByCamp)?[campaign] ?? []
  local player = players?[userId.tostring()]

  if (!isSingleMission) {
    let mplayersList = players.values().filter(@(v) v?.team == player?.team)
      .map(function(p) {
        let isLocal = p.userId == userId
        let pUserIdStr = p.userId.tointeger()
        return p.__merge({
          userId = pUserIdStr
          isLocal
          isDead = false
          name = isLocal ? userName
            : p.isBot ? loc(p.name)
            : p.name
          score = p?.dmgScoreBonus ?? 0.0
        })
      })
      .sort(playersSortFunc(campaign))

    let place = (mplayersList.findindex(@(v) v.userId == player?.userId ) ?? 0) + 1
    player = player?.__merge({ place })
  }

  let statsContent = stats.map(function(s, i) {
    let val = s.getVal(reward, player)
    return val == null ? null : mkStat(loc(s.locId), val, (startAnimTime + offsetTime * 1000 * i), s?.valueCtor)
  })

  let children = statsContent.extend(mkItemsUsedRows(itemsUsed, startAnimTime + offsetTime * 1000 * statsContent.len()))

  return children.len() == 0
    ? {
        debriefingStats = {}
        statsAnimEndTime = 0
      }
    : {
        debriefingStats = {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          children
        }
        statsAnimEndTime = endHeaderLineAnim + offsetTime * children.len()
      }
}

return {
  mkDebriefingStats
}