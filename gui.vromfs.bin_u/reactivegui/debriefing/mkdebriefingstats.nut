from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")
let { doesLocTextExist } = require("dagor.localize")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { orderByItems } = require("%appGlobals/itemsState.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { getScoreKeyRaw } = require("%rGui/mpStatistics/playersSortFunc.nut")
let { gradRadial } = require("%rGui/style/gradients.nut")
let { startSound, stopSound } = require("sound_wt")
let { playerPlaceIconSize, mkPlaceIcon } = require("%rGui/components/playerPlaceIcon.nut")
let mkAnimatedCountText = require("mkAnimatedCountText.nut")

let statIncreaseAnimTimeMsec = 500
let iconSize = hdpxi(30)
let iconInlineSize = fontTiny.fontSize
let iconInlineGap = round(iconInlineSize * 0.4).tointeger()
let endHeaderLineAnim = 1.0
let offsetTime = 0.1

let activeCounters = Watched({})
let isCounterActive = keepref(Computed(@() activeCounters.get().len() > 0))

let placeGlowColor = [0x40bbbbbb, 0x40ffdb7b, 0x407be1ff, 0x40ffb67b]

let function playerPlaceCtor(_uid, place, startTime) {
  return {
    size = [flex(), playerPlaceIconSize]
    halign = ALIGN_RIGHT
    children = {
      size = [hdpx(20), flex()] //width of single number in the score for correct align
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = [
        {
          size = [playerPlaceIconSize, playerPlaceIconSize]
          rendObj = ROBJ_IMAGE
          image = gradRadial
          color = placeGlowColor?[place] ?? placeGlowColor[0]
          transform = { scale = [0.3, 0.3] }
          animations = [
            {
              prop = AnimProp.scale, to = [2, 2],
              duration = 0.5, easing = CosineFull,  delay = startTime, play = true
            }
          ]
        }
        mkPlaceIcon(place).__update({
          transform = {}
          animations = [
            {
              prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3],
              duration = 0.5, easing = CosineFull, delay = startTime, play = true
            }
          ]
        })
      ]
    }
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

isCounterActive.subscribe(@(v) v ? startSound("coin_counter") : stopSound("coin_counter"))

let function setCounterActive(uid, isActive) {
  if (isActive != (uid in activeCounters.get()))
    activeCounters.mutate(function(v) {
      if (isActive)
        v[uid] <- true
      else
        delete v[uid]
    })
}

let animCountBaseComp = {
    size = flex()
    rendObj = ROBJ_TEXT
    halign = ALIGN_RIGHT
    color = 0xFFFFFFFF
}.__update(fontTiny)

let mkAnimatedCount = @(uid, value, startTime, baseComp = animCountBaseComp)
  mkAnimatedCountText(uid, value, startTime, statIncreaseAnimTimeMsec, setCounterActive, baseComp)

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  color = 0xFFFFFFFF
  text
}.__update(fontTiny)

let mkInlineIcon = @(children) {
  size = [iconInlineSize, iconInlineSize]
  margin = [0, 0, 0, iconInlineGap]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children
}

let mkStat = @(uid, text, value, startTime, valueCtor) {
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
    (valueCtor ?? mkAnimatedCount)(uid, value, startTime)
  ]
}

let function mkItemsUsedRows(itemsUsed, delay) {
  let items = []
  foreach (id, data in itemsUsed)
    items.append(data.__merge({ id, order = orderByItems?[id] ?? orderByItems.len() }))
  items.sort(@(a, b) a.order <=> b.order)
  return items.map(function(item, i) {
    let startTime = delay + (offsetTime * i)
    let { id, count = 0, used = 0 } = item
    local locId = $"debriefing/spent/{id}"
    if (!doesLocTextExist(locId))
      locId = "debriefing/spent/default"
    let usedWidth = max(calc_str_box(decimalFormat(used), fontTiny)[0],
                        calc_str_box(decimalFormat(0),    fontTiny)[0])
    return {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children =
        mkTextRow(loc(locId, { count = used }),
          mkText,
          {
            ["{countAnim}"] = mkAnimatedCount(id, used, startTime, //warning disable: -forgot-subst
              { size = [usedWidth, SIZE_TO_CONTENT], halign = ALIGN_CENTER })
          })
        .append(
          mkAnimatedCount($"count_{id}", count, startTime)
          mkInlineIcon(mkCurrencyImage(id, iconSize))
        )
    }
  })
}

let function getPlayerPlace(campaign, player, allPlayers) {
  let key = getScoreKeyRaw(campaign)
  let score = player?[key] ?? 0
  let { team = null } = player
  if (score <= 0 || team == null)
    return null

  local place = 1
  foreach(p in allPlayers)
    if (p.team == team && (p?[key] ?? 0) > score)
      place++
  return place
}

let function mkDebriefingStats(data, startAnimTime) {
  let { isSingleMission = false, reward = {}, players = {}, userId = -1, campaign = "",
    itemsUsed = {} } = data
  let stats = (isSingleMission ? statsByCampSingle : statsByCamp)?[campaign] ?? []
  local player = players?[userId.tostring()]

  if (!isSingleMission && player != null) {
    let place = getPlayerPlace(campaign, player, players)
    if (place != null)
      player = player.__merge({ place })
  }

  local idx = 0
  let statsContent = stats.map(function(s, uid) {
    let val = s.getVal(reward, player)
    return val == null ? null : mkStat(uid, loc(s.locId), val, startAnimTime + (offsetTime * idx++), s?.valueCtor)
  }).filter(@(v) v != null)

  let children = statsContent.extend(mkItemsUsedRows(itemsUsed, startAnimTime + (statsContent.len() * offsetTime)))

  return children.len() == 0
    ? {
        debriefingStats = null
        statsAnimEndTime = 0
      }
    : {
        debriefingStats = {
          size = [hdpx(750), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          children
        }
        statsAnimEndTime = endHeaderLineAnim + offsetTime * children.len()
      }
}

return {
  mkDebriefingStats
}