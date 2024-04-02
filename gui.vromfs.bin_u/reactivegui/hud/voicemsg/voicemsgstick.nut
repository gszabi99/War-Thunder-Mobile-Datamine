from "%globalsDarg/darg_library.nut" import *
let { mkMiniStick, stickHeadSize } = require("%rGui/hud/miniStick.nut")
let { isVoiceMsgStickActive, voiceMsgStickDelta, voiceMsgCooldownEndTime, COOLDOWN_TIME_SEC, isVoiceMsgEnabled
} = require("%rGui/hud/voiceMsg/voiceMsgState.nut")

let stickHeadIconSize = (stickHeadSize * 0.5 + 0.5).tointeger()
let stickHeadIcon = {
  size = [stickHeadIconSize, stickHeadIconSize]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#voice_messages.svg:{stickHeadIconSize}:{stickHeadIconSize}:P")
  keepAspect = true
  color = 0xFFFFFFFF
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
}
