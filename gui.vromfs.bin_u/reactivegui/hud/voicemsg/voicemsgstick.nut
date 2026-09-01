from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import SAILBOAT
from "%rGui/hud/miniStick.nut" import mkMiniStick, stickHeadSize
from "%rGui/hud/stickState.nut" import STICK
from "%rGui/hud/voiceMsg/voiceMsgState.nut" import isVoiceMsgAllowedInMission, isVoiceMsgStickActive,
  voiceMsgStickDelta, voiceMsgCooldownEndTime, COOLDOWN_TIME_SEC, isVoiceMsgEnabled
from "%rGui/hudStateExt.nut" import hudUnitType
from "%rGui/hudTuning/hudTuningState.nut" import tuningUnitType
from "%rGui/style/hudColors.nut" import hudWhiteColor


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
    color = hudWhiteColor
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
  gamepadParams = {shortcutId = "ID_VOICE_MSG", activeStick = STICK.LEFT}
})

return {
  voiceMsgStickBlock = stickControl
  voiceMsgStickView = stickView
  isVoiceMsgStickVisibleInBattle = isVoiceMsgAllowedInMission
}
