from "%globalsDarg/darg_library.nut" import *
let { mkPieMenu } = require("%rGui/hud/pieMenu.nut")
let { voiceMsgCfg, isVoiceMsgEnabled, isVoiceMsgStickActive, voiceMsgSelectedIdx
} = require("%rGui/hud/voiceMsg/voiceMsgState.nut")

let voiceMsgPieComp = mkPieMenu(voiceMsgCfg, voiceMsgSelectedIdx)

function voiceMsgPie() {
  let res = { watch = [isVoiceMsgEnabled, isVoiceMsgStickActive] }
  return isVoiceMsgEnabled.get() && isVoiceMsgStickActive.get()
    ? res.__update(voiceMsgPieComp)
    : res
}

return voiceMsgPie
