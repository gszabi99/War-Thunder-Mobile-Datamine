from "%globalsDarg/darg_library.nut" import *
let { send, subscribe } = require("eventbus")
let { register_command } = require("console")
let { rnd_int } = require("dagor.random")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { chooseRandom } = require("%sqstd/rand.nut")
let { localPlayerColor } = require("%rGui/style/stdColors.nut")
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { myUserName, myUserRealName } = require("%appGlobals/profileStates.nut")
let { localMPlayerTeam } = require("%appGlobals/clientState/clientState.nut")
let { modifyOrAddEvent, removeEvent } = require("%rGui/hudHints/warningHintLogState.nut")
let { registerHintCreator } = require("%rGui/hudHints/hintCtors.nut")
let { rqPlayersAndDo } = require("rqPlayersAndDo.nut")
let { teamBlueLightColor, teamRedLightColor, mySquadLightColor } = require("%rGui/style/teamColors.nut")


let HINT_TYPE = "killStreak"
let iconSize = hdpxi(50)
let unknownSize = hdpxi(30)
local dbgTimeLeft = 0
//todo: export from native code to darg
const MP_TEAM_NEUTRAL = 0

let getPlayerColor = @(player) player.isLocal ? localPlayerColor
  : player?.isInHeroSquad ? mySquadLightColor
  : player.team == MP_TEAM_NEUTRAL ? null
  : player.team == localMPlayerTeam.value ? teamBlueLightColor
  : teamRedLightColor

let function getColoredName(player) {
  let color = getPlayerColor(player)
  let text = getPlayerName(player.name, myUserRealName.value, myUserName.value)
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

let function mkParticipantIcon(info, idx) {
  let { image, participant } = info
  return participant == null ? unknownIcon
    : {
        key = $"{participant.team}{idx}"
        size = [iconSize, iconSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#{image}.avif:{iconSize}:{iconSize}")
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
  let firstTeam = localMPlayerTeam.value == MP_TEAM_NEUTRAL ? 1 : localMPlayerTeam.value
  let list = { [true] = [], [false] = [] }
  foreach (p in participants)
    if (p.participant != null)
      list[p.participant.team == firstTeam].append(p) //warning disable: -bool-as-index //error must be only for arrays, not for table
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

registerHintCreator(HINT_TYPE, function(data) {
  let { timeSeconds = 0, locId = null, noKeyLocId = null, slotsCount = 1, player, participants }  = data

  return {
    key = HINT_TYPE
    size = [saSize[0] - hdpx(1100), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      participantsRow(participants, slotsCount)
      {
        size = [flex(), SIZE_TO_CONTENT]
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

subscribe("hint:event_start_time:show", function(data) {
  let { playerId = null, participant = [] }  = data
  let participants = type(participant) == "array" ? participant : [participant] //event data convert from blk, so when single participants it will be not array
  let rqPlayers = {}
  if (playerId != null)
    rqPlayers.player <- playerId
  participants.each(@(p, i) rqPlayers[i] <- p.participantId)
  rqPlayersAndDo(rqPlayers,
    function(answer) {
      let players = dbgTimeLeft <= 0 ? answer
        : answer.map(@(p, key) p ?? { name = "somebodyName", isLocal = rqPlayers[key] == 0, team = 2 - (rqPlayers[key] % 2) })
      let { player = null } = players
      let evt = data.__merge({
        id = HINT_TYPE,
        hType = HINT_TYPE,
        player
        participants = participants.map(@(p, i) p.__merge({ participant = players[i] }))
      })
    modifyOrAddEvent(evt, @(ev) ev?.id == HINT_TYPE)
  })
})
subscribe("hint:event_start_time:hide", @(_) removeEvent({ id = HINT_TYPE }))

let dbgIconsList = ["aircraft_fighter", "aircraft_attacker", "aircraft_bomber"]
let dbgTextsList = ["hints/event_start_time", "hints/event_can_join_ally", "hints/event_can_join_enemy", "hints/event_player_start_on"]
let function onDbgTimer() {
  if (dbgTimeLeft <= 0) {
    clearTimer(callee())
    send("hint:event_start_time:hide", {})
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
  send("hint:event_start_time:show", eventData)
}

let function startDebug() {
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
