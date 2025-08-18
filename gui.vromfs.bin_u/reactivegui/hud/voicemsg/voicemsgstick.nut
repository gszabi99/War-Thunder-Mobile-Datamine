from "%globalsDarg/darg_library.nut" import *
let { SAILBOAT } = require("%appGlobals/unitConst.nut")
let { mkMiniStick, stickHeadSize } = require("%rGui/hud/miniStick.nut")
let { isVoiceMsgAllowedInMission, isVoiceMsgStickActive, voiceMsgStickDelta,
  voiceMsgCooldownEndTime, COOLDOWN_TIME_SEC, isVoiceMsgEnabled
} = require("%rGui/hud/voiceMsg/voiceMsgState.nut")
let { hudUnitType } = require("%rGui/hudState.nut")
let { tuningUnitType } = require("%rGui/hudTuning/hudTuningState.nut")

let stickHeadIconSize = 2 * (stickHeadSize / 4.0 + 0.5).tointeger()

function stickHeadIcon(scale, isEnabled) {
  let size = scaleEven(stickHeadIconSize, scale)
  let icon = Computed(@() (tuningUnitType.get() ?? hudUnitType.get()) == SAILBOAT ? "hud_consumable_pirate_commands.svg"
    : "voice_messages.svg")
  return @() {
    watch = icon
    size = [size, size]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#{icon.get()}:{size}:{size}:P")
    keepAspect = true
    color = 0xFFFFFFFF
    opacity = isEnabled ? 1.0 : 0.5
  }
}

let { stickControl, stickView } = mkMiniStick({
  isStickActive = isVoiceMsgStickActive
  stickDelta = voiceMsgStickDelta
  stickHeadChild = stickHeadIcon
  stickCooldownEndTime = voiceMsgCooldownEndTime
  stickCooldownTimeSec = Watched(COOLDOWN_TIME_SEC)
  isStickEnabled = isVoiceMsgEnabled
})

return {
  voiceMsgStickBlock = stickControl
  voiceMsgStickView = stickView
  isVoiceMsgStickVisibleInBattle = isVoiceMsgAllowedInMission
}
