from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { register_command } = require("console")
let { lerp, lerpClamped } = require("%sqstd/math.nut")
let { chooseRandom } = require("%sqstd/rand.nut")
let { activeTimers, timersVisibility, removeTimer, getTimerCountdownSec } = require("hudTimersState.nut")
let { get_time_msec } = require("dagor.time")
let { playerUnitName } = require("%rGui/hudState.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { setTimeout } = require("dagor.workcycle")

let grey = 0xFF787878
let darkRed = 0xFFDD1111

let timerSize = hdpx(64).tointeger()
let icoSize = hdpx(38).tointeger()

let timers = [
  {
    id = "repair_status"
    color = grey
    icon = @(_) "ui/gameuiskin#icon_repair_in_progress.svg"
  },
  {
    id = "repair_auto_status"
    color = grey
    icon = @(unitName) getUnitType(unitName) == SHIP ? "ui/gameuiskin#ship_crew_driver.avif"
      : "ui/gameuiskin#track_state_indicator.svg"
  },
  {
    id = "rearm_primary_status"
    color = 0xFFFFFFFF
    icon = @(_) "ui/gameuiskin#icon_weapons_in_progress.svg"
  },
  {
    id = "rearm_secondary_status"
    color = 0xFFFFFFFF
    icon = @(_) "ui/gameuiskin#icon_weapons_in_progress.svg"
  },
  {
    id = "rearm_machinegun_status"
    color = 0xFFFFFFFF
    icon = @(_) "ui/gameuiskin#icon_weapons_in_progress.svg"
  },
  {
    id = "rearm_aps_status"
    color = 0xFFFFFFFF
    icon = @(_) "ui/gameuiskin#icon_weapons_in_progress.svg"
  },
  {
    id = "rearm_rocket_status"
    color = 0xFFFFFFFF
    icon = @(_) "ui/gameuiskin#icon_rocket_in_progress.svg"
  },
  {
    id = "rearm_smoke_status"
    color = 0xFFFFFFFF
    icon = @(_) "ui/gameuiskin#icon_smoke_screen_in_progress.svg"
  },
  {
    id = "driver_status"
    color = darkRed
    icon = @(unitName) getUnitType(unitName) == SHIP ? "ui/gameuiskin#ship_crew_driver.avif"
      : "ui/gameuiskin#crew_driver_indicator.svg"
  },
  {
    id = "gunner_status"
    color = darkRed
    icon = @(unitName) getUnitType(unitName) == SHIP ? "ui/gameuiskin#ship_crew_gunner.avif"
      : "ui/gameuiskin#crew_gunner_indicator.svg"
  },
  {
    id = "loader_status"
    color = darkRed
    icon = @(_) "ui/gameuiskin#crew_loader_indicator.svg"
  },
  {
    id = "healing_status"
    color = 0xFFFFFFFF
    icon = @(_) "ui/gameuiskin#medic_status_indicator.avif"
  },
  {
    id = "repair_breaches_status"
    color = grey
    icon = @(_) "ui/gameuiskin#icon_repair_in_progress.svg"
  },
  {
    id = "unwatering_status"
    color = grey
    icon = @(_) "ui/gameuiskin#unwatering_in_progress.avif"
  },
  {
    id = "extinguish_status"
    color = darkRed
    icon = @(_) "ui/gameuiskin#fire_indicator.svg"
  },
  {
    id = "replenish_status"
    color = 0xFFFFFFFF
    icon = @(_) "ui/gameuiskin#icon_weapons_relocation_in_progress.svg"
  },
  {
    id = "move_cooldown_status"
    color = 0xFFFFFFFF
    icon = @(_) "ui/gameuiskin#icon_repair_in_progress.svg"
  },
  {
    id = "battery_status"
    color = darkRed
    icon = @(_) "ui/gameuiskin#icon_battery_in_progress.svg"
  },
]

function progressCircle(timer) {
  let { startTime = 0, endTime = 0, isForward = true, isPaused = false } = timer
  let timeLeft = endTime - get_time_msec()
  local startValue = startTime >= endTime ? 1.0
    : lerpClamped(startTime, endTime, 0.0, 1.0, get_time_msec())
  if (!isForward)
    startValue = 1.0 - startValue

  return {
    size = [timerSize, timerSize]
    rendObj = ROBJ_PROGRESS_CIRCULAR
    image = Picture($"ui/gameuiskin#circular_progress_1.svg:{timerSize}:{timerSize}")
    fgColor = 0xFFFFFFFF
    bgColor = 0x33555555
    fValue = isForward ? 1.0 : 0.0
    animations = timeLeft <= 0 ? null
      : [{ prop = AnimProp.fValue, from = startValue, duration = !isPaused ? 0.001 * timeLeft : 1000000.0, play = true }]
  }
}

let timerIcon = @(timerCfg, timer) function() {
  let res = { watch = playerUnitName }
  let icon = timerCfg.icon(playerUnitName.value)
  if (icon == null)
    return res
  let { winkPeriod = 0 } = timer
  return res.__update({
    key = winkPeriod
    size = [icoSize, icoSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"{icon}:{icoSize}:{icoSize}")
    color = timerCfg.color
    animations = winkPeriod <= 0 ? null
      : [{ prop = AnimProp.opacity, from = 0.5, to = 1.0, duration = winkPeriod,
          easing = CosineFull, play = true, loop = true }]
  })
}

let timerTextStyle = {
  size = const [hdpx(100), SIZE_TO_CONTENT] 
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  color = 0xFFFFFFFF
}.__update(fontTinyShaded)

function timerText(id, timer) {
  let { needCountdown = false, text = null } = timer
  if (!needCountdown)
    return timerTextStyle.__merge({ key = id, text })

  let timeLeft = getTimerCountdownSec(id)
  return @() timerTextStyle.__merge({
    watch = timeLeft
    key = id
    text = timeLeft.value == 0 ? "" : timeLeft.value
  })
}

let timerVisual = @(timerCfg, timer) {
  key = timer
  size = [timerSize, timerSize]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    progressCircle(timer)
    timerIcon(timerCfg, timer)
    timerText(timerCfg.id, timer)
  ]
}

function timerPlace(timerCfg, idx, total) {
  let timer = Computed(@() activeTimers.get()?[timerCfg.id])
  return @() {
    watch = timer
    size = [timerSize, timerSize]
    key = timerCfg
    children = timer.value == null ? null : timerVisual(timerCfg, timer.value)

    transform = { translate = [lerp(-1.0, 1.0, -timerSize, timerSize, -0.5 * total + idx), 0] }
    transitions = [{ prop = AnimProp.translate, duration = 0.3, easing = OutQuad }]
    animations = [
      { prop = AnimProp.opacity, from = 0, to = 1.0, duration = 0.3, easing = OutQuad, play = true }
      { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.15, easing = OutQuad, playFadeOut = true }
    ]
  }
}

function hudTimers() {
  let filtered = timers.filter(@(t) t.id in timersVisibility.get())
  let total = filtered.len()
  return {
    watch = timersVisibility
    size = [total * timerSize, timerSize]
    halign = ALIGN_CENTER
    children = filtered.map(@(t, i) timerPlace(t, i, total))
  }
}

function randomTimer() {
  let id = chooseRandom(timers).id
  if (id in activeTimers.get()) {
    removeTimer(id)
    return
  }
  activeTimers.mutate(function(at) {
    let timeLeft = chooseRandom([1, 3, 5, 10, 15])
    at[id] <- {
      startTime = get_time_msec() + (1000 * chooseRandom([0, 0, 0, -1, -2, -3])).tointeger()
      endTime = get_time_msec() + (1000 * timeLeft).tointeger()
      winkPeriod = chooseRandom([0, 0, 1.5, 3])
      needCountdown = chooseRandom([false, true])
      isForward = chooseRandom([false, true])
    }
    setTimeout(timeLeft, @() removeTimer(id))
  })
}

register_command(randomTimer, "hud.debug.randomTimer")

return hudTimers