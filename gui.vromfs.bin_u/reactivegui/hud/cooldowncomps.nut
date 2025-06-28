from "%globalsDarg/darg_library.nut" import *
let { round_by_value } = require("%sqstd/math.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { resetTimeout, clearTimer, deferOnce } = require("dagor.workcycle")
let { get_mission_time } = require("mission")
let { register_command } = require("console")


let isDebugMode = hardPersistWatched("cooldownComps.isDebugMode", false)
let cooldownsLeft = Watched({})

let calcDelay = @(cdLeftRaw) (cdLeftRaw >= 10)
  ? clamp(cdLeftRaw - cdLeftRaw.tointeger() + 0.1, 0.5, 1.0)
  : clamp(cdLeftRaw - ((cdLeftRaw * 10).tointeger() / 10.0) + 0.01, 0.05, 0.1)

function updateCdTimer(id, endTime, updateCdTimerCb) {
  let cooldownLeft = max(endTime - get_mission_time(), 0.0)
  cooldownsLeft.mutate(@(v) v[id] <- cooldownLeft)
  if (cooldownLeft <= 0.0) {
    clearTimer(updateCdTimerCb)
    cooldownsLeft.mutate(@(v) v.$rawdelete(id))
    return
  }
  let delay = calcDelay(cooldownLeft)
  deferOnce(@() resetTimeout(delay, updateCdTimerCb))
}

function mkCooldownText(id, endTime) {
  let updateCdTimerCb = @() updateCdTimer(id, endTime, updateCdTimerCb)
  let cdLeft = Computed(@() cooldownsLeft.get()?[id] ?? 0.0)
  let res = {
    watch = cdLeft
    key = $"cooldown_text_{id}_{endTime}"
    onAttach = updateCdTimerCb
    function onDetach() {
      clearTimer(updateCdTimerCb)
      cooldownsLeft.mutate(@(v) v.$rawdelete(id))
    }
  }
  return @() res.__update(cdLeft.get() <= 0.0 ? {} : {
    pos = [pw(50), pw(-15)]
    rendObj = ROBJ_TEXT
    color = 0xFFFFFFFF
    text = round_by_value(cdLeft.get(), cdLeft.get() >= 10 ? 1 : 0.1)
  })
}

let mkItemWithCooldownText = @(id, item, size, hasCooldown, endTime) @() {
  watch = isDebugMode
  size
  children = !hasCooldown || !isDebugMode.get() ? item
    : [
        item
        mkCooldownText(id, endTime)
      ]
}

register_command(
  function() {
    isDebugMode.set(!isDebugMode.get())
    console_print($"hasHudCooldown = {isDebugMode.get()}") 
  },
  "debug.toggleHudCooldown")

return {
  mkItemWithCooldownText
}