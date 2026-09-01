from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.workcycle" import resetTimeout, clearTimer, deferOnce
from "mission" import get_mission_time
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/math.nut" import round_by_value
from "%rGui/style/hudColors.nut" import hudWhiteColor


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
    pos = const [pw(50), pw(-15)]
    rendObj = ROBJ_TEXT
    color = hudWhiteColor
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