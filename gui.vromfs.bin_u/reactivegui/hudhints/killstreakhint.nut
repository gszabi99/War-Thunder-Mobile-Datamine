from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { get_mplayer_by_id } = require("mission")
let { register_command } = require("console")
let { rnd_int } = require("dagor.random")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { chooseRandom } = require("%sqstd/rand.nut")
let { localPlayerColor } = require("%rGui/style/stdColors.nut")
let { localMPlayerTeam } = require("%appGlobals/clientState/clientState.nut")
let { modifyOrAddEvent, removeEvent } = require("%rGui/hudHints/warningHintLogState.nut")
let { registerHintCreator } = require("%rGui/hudHints/hintCtors.nut")
let { teamBlueLightColor, teamRedLightColor, mySquadLightColor } = require("%rGui/style/teamColors.nut")


let HINT_TYPE = "killStreak"
let iconSize = hdpxi(50)
let unknownSize = hdpxi(30)
local dbgTimeLeft = 0

const MP_TEAM_NEUTRAL = 0

let getPlayerColor = @(player) player.isLocal ? localPlayerColor
  : player?.isInHeroSquad ? mySquadLightColor
  : player.team == MP_TEAM_NEUTRAL ? null
  : player.team == localMPlayerTeam.get() ? teamBlueLightColor
  : teamRedLightColor

function getColoredName(player) {
  let color = getPlayerColor(player)
  let text = player.name
  return color == null ? text : colorize(color, text)
}

let unknownIcon = {
  size = [iconSize, iconSize]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    size = [unknownSize, unknownSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#btn_help.svg:{unknownSize}:{unknownSize}")
    color = 0xFFA0A0A0
  }
}

function mkParticipantIcon(info, idx) {
  let { image, participant } = info
  let imageFinal = image == null ? "icon_primary_attention.svg" : $"{image}.avif"
  return participant == null ? unknownIcon
    : {
        key = $"{participant.team}{idx}"
        size = [iconSize, iconSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#{imageFinal}:{iconSize}:{iconSize}")
        color = getPlayerColor(participant)
        transform = {}
        animations = [
          { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.3, easing = OutQuad, play = true }
          { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.2, 1.2], duration = 0.7,
            easing = DoubleBlink, play = true }
          { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, easing = OutQuad, playFadeOut = true }
        ]
      }
}

let participantsRow = @(participants, slotsCount) function() {
  let firstTeam = localMPlayerTeam.get() == MP_TEAM_NEUTRAL ? 1 : localMPlayerTeam.get()
  let list = { [true] = [], [false] = [] }
  foreach (p in participants)
    if (p.participant != null)
      list[p.participant.team == firstTeam].append(p) 
  foreach (key, l in list)
    list[key] = l.map(mkParticipantIcon).resize(slotsCount, unknownIcon)
  return {
    watch = localMPlayerTeam
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    valign = ALIGN_CENTER
    children = list[true]
      .append({
        rendObj = ROBJ_TEXT
        text = loc("country/VS")
        color = 0xFFFFFFFF
      }.__update(fontTinyShaded))
      .extend(list[false])
  }
}

registerHintCreator(HINT_TYPE, function(data, _) {
  let { timeSeconds = 0, locId = null, noKeyLocId = null, slotsCount = 1, player, participants }  = data

  return {
    key = HINT_TYPE
    size = [saSize[0] - hdpx(1100), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      participantsRow(participants, slotsCount)
      {
        size = FLEX_H
        halign = ALIGN_CENTER
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        fontFxColor = Color(0, 0, 0, 50)
        fontFxFactor = min(64, hdpx(64))
        fontFx = FFT_GLOW
        text = loc(locId ?? noKeyLocId, {
          time = $"{timeSeconds}{loc("debriefing/timeSec")}",
          player = player == null ? "???" : getColoredName(player)
        })
      }.__update(fontTinyShaded)
    ]
    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.3, easing = OutQuad, play = true }
      { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.2, 1.2], duration = 0.7,
        easing = DoubleBlink, play = true }
      { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, easing = OutQuad, playFadeOut = true }
    ]
  }
})

eventbus_subscribe("hint:event_start_time:show", function(data) {
  let { playerId = null, participant = [] }  = data
  let player = playerId != null ? get_mplayer_by_id(playerId) : null
  let participants = (type(participant) == "array" ? participant : [participant]) 
    .map(@(v) v.__merge({ participant = get_mplayer_by_id(v.participantId) }))
  if (dbgTimeLeft > 0)
    participants.each(@(v, i) v.participant = v.participant ??
      { name = "somebodyName", isLocal = i == 0, team = 2 - (i % 2) })
  let evt = data.__merge({
    id = HINT_TYPE,
    hType = HINT_TYPE,
    player
    participants
  })
  modifyOrAddEvent(evt, @(ev) ev?.id == HINT_TYPE)
})
eventbus_subscribe("hint:event_start_time:hide", @(_) removeEvent({ id = HINT_TYPE }))

let dbgIconsList = ["aircraft_fighter", "aircraft_attacker", "aircraft_bomber"]
let dbgTextsList = ["hints/event_start_time", "hints/event_can_join_ally", "hints/event_can_join_enemy", "hints/event_player_start_on"]
function onDbgTimer() {
  if (dbgTimeLeft <= 0) {
    clearTimer(callee())
    eventbus_send("hint:event_start_time:hide", {})
    return
  }

  let total = rnd_int(1, 6)
  let eventData = {
    timeSeconds = dbgTimeLeft--
    locId = chooseRandom(dbgTextsList)
    slotsCount = 3
    playerId = total > 1 ? 1 : 0
    participant = array(total)
      .map(@(_, i) { image = chooseRandom(dbgIconsList), participantId = i })
  }
  eventbus_send("hint:event_start_time:show", eventData)
}

function startDebug() {
  if (dbgTimeLeft > 0) {
    dbgTimeLeft = 0
    clearTimer(onDbgTimer)
  }
  else {
    dbgTimeLeft = 30
    setInterval(1.0, onDbgTimer)
  }
  onDbgTimer()
}

register_command(startDebug, "hud.debug.killStreakHint")
