from "%globalsDarg/darg_library.nut" import *

let { get_mission_time } = require("mission")
let { eventbus_send } = require("eventbus")
let { register_command, command } = require("console")
let { MISSION_CAPTURING_ZONE } = require("guiMission")
let { HIT_CAMERA_START, HIT_CAMERA_FINISH, DM_HIT_RESULT_NONE, DM_HIT_RESULT_KILL } = require("hitCamera")
let { setInterval, clearTimer, defer } = require("dagor.workcycle")
let { rnd_float } = require("dagor.random")
let { chooseRandom } = require("%sqstd/rand.nut")
let { HUD_MSG_STREAK_EX } = require("hudMessages")

const DEFAULT_FREQUENCY = 10

let frequency = mkWatched(persist, "frequency", DEFAULT_FREQUENCY)
let isActive = mkWatched(persist, "isActive", false)

let samplesHintMission = [
  "hints/tutorial_tank_hello"
  "hints/ten_minutes_left"
  "hints/killall"
]
let samplesHintObjective = [
  "avg_Conq_objective"
  "avg_Capt_objective_01"
  "t2_stop_breakthrough"
]
let samplesHintCommon = [
  "hint:have_art_support:show"
  "hint:repair_module:show"
  "hint:shoot_when_tank_stop:show"
]

let approximateIntervalSec = @(t) 1.0 / DEFAULT_FREQUENCY / t

let testsCfg = {
  hintsMission = {
    possibility = approximateIntervalSec(2.5)
    show = @() eventbus_send("hint:missionHint:set", { locId = chooseRandom(samplesHintMission), time = 3.0 })
  }
  hintsMissionBottom = {
    possibility = approximateIntervalSec(5.0)
    show = @() eventbus_send("hint:missionHint:set",
      { locId = chooseRandom(samplesHintMission), time = 3.0, hintType = "bottom" })
  }
  hintsObjective = {
    possibility = approximateIntervalSec(2.0)
    show = @() eventbus_send("HudMessage", { id = 0, type = 0, show = true, text = loc(chooseRandom(samplesHintObjective)) })
  }
  hintsCommon = {
    possibility = approximateIntervalSec(2.5)
    show = @() eventbus_send(chooseRandom(samplesHintCommon), {})
  }
  hintWarning = {
    possibility = approximateIntervalSec(2.5)
    show = @() eventbus_send("onShowReturnToMapMessage", chooseRandom([
      { showMessage = true, endTime = get_mission_time() }
      { showMessage = false }
    ]))
    hide = @() eventbus_send("onShowReturnToMapMessage", { showMessage = false })
  }
  hintObstacle = {
    possibility = approximateIntervalSec(3.0)
    show = @() command("hud.debug.obstacleNearHint")
  }
  hintCapturingZone = {
    possibility = approximateIntervalSec(5.0)
    show = @() eventbus_send("zoneCapturingEvent", {
      text = loc("NET_YOU_CAPTURING_LA")
      eventId = MISSION_CAPTURING_ZONE
      isMyTeam = true
      isHeroAction = true
      zoneName = "A"
      captureProgress = 0.7
    })
  }
  hintsKillStreak = {
    possibility = approximateIntervalSec(5.0)
    show = @() command("hud.debug.killStreakHint")
  }
  hudTimers = {
    possibility = approximateIntervalSec(4.5)
    show = @() command("hud.debug.randomTimer")
  }
  killLogMsgs = {
    possibility = approximateIntervalSec(5.0)
    show = @() command("hud.debug.killMessage")
  }
  hitCam = {
    possibility = approximateIntervalSec(5.0)
    show = @() eventbus_send("hitCamera", chooseRandom([
      { mode = HIT_CAMERA_START, result = DM_HIT_RESULT_KILL, info = {} }
      { mode = HIT_CAMERA_FINISH, result = DM_HIT_RESULT_NONE, info = {} }
    ]))
    hide = @() eventbus_send("hitCamera", { mode = HIT_CAMERA_FINISH, result = DM_HIT_RESULT_NONE, info = {} })
  }
  hintStreak = {
    possibility = approximateIntervalSec(5.0)
    show = @() eventbus_send("HudMessage", {
      type = HUD_MSG_STREAK_EX
      unlockId = "first_blood"
      stage = 1
      wp = 100
      exp = 200
    })
  }
}

function act() {
  foreach (test in testsCfg) {
    let { show, possibility } = test
    let rnd = rnd_float(0.0, 1.0)
    if (possibility >= rnd)
      show()
  }
}

function spamStart() {
  setInterval(1.0 / frequency.value, act)
  defer(act)
}

function spamStop() {
  clearTimer(act)
  foreach (test in testsCfg)
    if (test?.hide != null)
      defer(test.hide)
}

isActive.subscribe(@(v) v ? spamStart() : spamStop())
if (isActive.value)
  spamStart()

frequency.subscribe(function(_) {
  if (isActive.value) {
    spamStop()
    spamStart()
  }
})

let toggleSpam = @() isActive(!isActive.value)
let setSpeedMul = @(speedMul = 1.0) frequency(DEFAULT_FREQUENCY * speedMul)

register_command(toggleSpam, "hud.debug.spam")
register_command(setSpeedMul, "hud.debug.spam.set_speed_mul")
