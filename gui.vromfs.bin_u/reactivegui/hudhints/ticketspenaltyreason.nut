from "%globalsDarg/darg_library.nut" import *

let { register_command } = require("console")
let { rnd_int } = require("dagor.random")
let { eventbus_subscribe } = require("eventbus")
let { TeamTicketsPenaltyReason } = require("guiMission")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { localTeam } = require("%rGui/missionState.nut")
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")

let maxPenaltyLogEvents = 3
let iconWidth = hdpx(30)
let penaltyReasonW = iconWidth + hdpx(10)
let penaltyReasonH = hdpx(50)
let penaltyReasonGap = hdpx(5)
let animDuration = 0.3

let reasonIconConfig = {
  [TeamTicketsPenaltyReason.air_defense_died] = {
    icon = "ui/gameuiskin#air_defense.svg",
    iconOutline = "ui/gameuiskin#air_defense_outline.svg",
  },
  [TeamTicketsPenaltyReason.airport_died] = {
    icon = "ui/gameuiskin#airport.svg",
    iconOutline = "ui/gameuiskin#airport_outline.svg",
  },
  [TeamTicketsPenaltyReason.artillery_died] = {
    icon = "ui/gameuiskin#artillery.svg",
    iconOutline = "ui/gameuiskin#artillery_outline.svg",
  },
  [TeamTicketsPenaltyReason.boat_died] = {
    icon = "ui/gameuiskin#boat.svg",
    iconOutline = "ui/gameuiskin#boat_outline.svg",
  },
  [TeamTicketsPenaltyReason.bombing_zone_died] = {
    ally = {
      icon = "ui/gameuiskin#base_ally.svg",
      iconOutline = "ui/gameuiskin#base_ally_outline.svg",
    },
    enemy = {
      icon = "ui/gameuiskin#base_enemy.svg",
      iconOutline = "ui/gameuiskin#base_enemy_outline.svg",
    },
  },
  [TeamTicketsPenaltyReason.cargo_ship_died] = {
    icon = "ui/gameuiskin#cargo_ship.svg",
    iconOutline = "ui/gameuiskin#cargo_ship_outline.svg",
  },
  [TeamTicketsPenaltyReason.fortification_died] = {
    icon = "ui/gameuiskin#fortification.svg",
    iconOutline = "ui/gameuiskin#fortification_outline.svg",
  },
  [TeamTicketsPenaltyReason.navy_ship_died] = {
    icon = "ui/gameuiskin#navy_ship.svg",
    iconOutline = "ui/gameuiskin#navy_ship_outline.svg",
  },
  [TeamTicketsPenaltyReason.plane_died] = {
    icon = "ui/gameuiskin#plane.svg",
    iconOutline = "ui/gameuiskin#plane_outline.svg",
  },
  [TeamTicketsPenaltyReason.ship_died] = {
    icon = "ui/gameuiskin#navy_ship.svg",
    iconOutline = "ui/gameuiskin#navy_ship_outline.svg",
  },
  [TeamTicketsPenaltyReason.tank_died] = {
    icon = "ui/gameuiskin#medium_tank.svg",
    iconOutline = "ui/gameuiskin#medium_tank_outline.svg",
  },
  [TeamTicketsPenaltyReason.truck_aaa_died] = {
    icon = "ui/gameuiskin#truck_aaa.svg",
    iconOutline = "ui/gameuiskin#truck_aaa_outline.svg",
  },
  [TeamTicketsPenaltyReason.truck_died] = {
    icon = "ui/gameuiskin#truck.svg",
    iconOutline = "ui/gameuiskin#truck_outline.svg",
  },
  [TeamTicketsPenaltyReason.unknown] = null,
}

let stateAlly = require("%sqstd/mkEventLogState.nut")({
  persistId = "penaltyLogStateAlly"
  maxActiveEvents = maxPenaltyLogEvents
  defTtl = 5
})

let stateEnemy = require("%sqstd/mkEventLogState.nut")({
  persistId = "penaltyLogStateEnemy"
  maxActiveEvents = maxPenaltyLogEvents
  defTtl = 5
})

function clearEvents() {
  stateAlly.clearEvents()
  stateEnemy.clearEvents()
}

isInBattle.subscribe(@(_) clearEvents())

function onMpTeamTicketsPenalty(v) {
  if (v.reason == 0 || v.penalty == 0)
    return
  local shouldShowIcon = true
  let isLocal = v.team == localTeam.get()
  let state = isLocal ? stateAlly : stateEnemy
  if (v.reason == 5) {
    anim_start($"{isLocal ? "localTeam" : "enemyTeam"}AirportDamaged")
    shouldShowIcon = !state.curEvents.get().findvalue(@(e) e.reason == 5)
  }
  let iconConfig = reasonIconConfig?[v.reason][isLocal ? "ally" : "enemy"] ?? reasonIconConfig?[v.reason] ?? {}
  state.addEvent({
    reason = v.reason,
    text = $"{v.penalty}",
    isLocal
  }.__update(shouldShowIcon ? iconConfig : {}))
}

eventbus_subscribe("onMpTeamTicketsPenalty", onMpTeamTicketsPenalty)

function mkIcon(data) {
  let { icon = null, iconOutline = null, isLocal } = data
  if (!icon)
    return null
  let imgSize = array(2, iconWidth).map(@(v) v.tointeger())
  return {
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = imgSize
        keepAspect = true
        image = Picture($"{iconOutline}:{imgSize[0]}:{imgSize[1]}:P")
        color = 0xFF000000
      }
      {
        rendObj = ROBJ_IMAGE
        size = imgSize
        keepAspect = true
        image = Picture($"{icon}:{imgSize[0]}:{imgSize[1]}:P")
        color = isLocal ? teamBlueColor : teamRedColor
      }
    ]
  }
}

function mkPenaltyReason(data, fontOvr) {
  let content = [
    mkIcon(data)
    {
      rendObj = ROBJ_TEXT
      text = data.text
    }.__update(fontOvr)
  ]
  return {
    size = [penaltyReasonW, flex()]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    children = content
  }
}

let mkTransition = @(uid, children, offset, zOrder, isLeft) {
  key = uid
  zOrder
  size = [penaltyReasonW, penaltyReasonH]
  halign = ALIGN_CENTER
  children = {
    size = [penaltyReasonW, penaltyReasonH]
    children
    transform = { translate = [0, 0] }
    animations = [
      { prop = AnimProp.opacity, duration = animDuration, easing = OutQuad, from = 0, to = 1, play = true }
      { prop = AnimProp.translate, duration = animDuration, easing = InQuad, from = [isLeft ? -penaltyReasonW : penaltyReasonW, 0], play = true }
      { prop = AnimProp.translate, duration = animDuration, easing = OutQuad, to = [isLeft ? penaltyReasonW : -penaltyReasonW, 0], playFadeOut = true }
      { prop = AnimProp.opacity, duration = animDuration, easing = OutQuad, to = 0, playFadeOut = true }
    ]
  }
  transform = { translate = [isLeft ? -offset : offset, 0] }
  transitions = [{ prop = AnimProp.translate, duration = animDuration, easing = InOutQuad }]
}

let ticketPenaltyReasonLogPlace = function(events, isLeft) {
  local offset = 0
  let children = []
  foreach (event in events.get()) {
    let { uid, zOrder = null } = event
    let penaltyReason = mkPenaltyReason(event, fontVeryVeryTinyShaded)
    children.append(mkTransition(uid, penaltyReason, offset, zOrder, isLeft))
    offset += penaltyReasonW + penaltyReasonGap
  }

  return {
    watch = events
    size = [penaltyReasonW * 3, penaltyReasonH]
    halign = isLeft ? ALIGN_RIGHT : ALIGN_LEFT
    gap = penaltyReasonGap
    children
  }
}

register_command(function() {
  onMpTeamTicketsPenalty({
    reason = rnd_int(1, TeamTicketsPenaltyReason.len() - 1)
    penalty = -rnd_int(100, 499)
    team = localTeam.get()
  })
}, "debug.ticketsPenaltyAlly")

register_command(function() {
  onMpTeamTicketsPenalty({
    reason = rnd_int(1, TeamTicketsPenaltyReason.len() - 1)
    penalty = -rnd_int(100, 499)
    team = localTeam.get() == 1 ? 2 : 1
  })
}, "debug.ticketsPenaltyEnemy")

return {
  ticketsPenaltyReasonAlly = stateAlly.__merge({ maxPenaltyLogEvents })
  ticketsPenaltyReasonEnemy = stateEnemy.__merge({ maxPenaltyLogEvents })
  ticketPenaltyReasonAllyLogPlace = @() ticketPenaltyReasonLogPlace(stateAlly.curEvents, true)
  ticketPenaltyReasonEnemyLogPlace = @() ticketPenaltyReasonLogPlace(stateEnemy.curEvents, false)
}