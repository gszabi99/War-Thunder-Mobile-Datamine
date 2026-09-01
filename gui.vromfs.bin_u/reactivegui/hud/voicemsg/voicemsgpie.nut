from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/pieMenu.nut" import mkPieMenu
from "%rGui/hud/voiceMsg/voiceMsgState.nut" import voiceMsgCfg, isVoiceMsgEnabled, isVoiceMsgStickActive,
  voiceMsgSelectedIdx


let voiceMsgPieComp = mkPieMenu(voiceMsgCfg, voiceMsgSelectedIdx)

function voiceMsgPie() {
  let res = { watch = [isVoiceMsgEnabled, isVoiceMsgStickActive] }
  return isVoiceMsgEnabled.get() && isVoiceMsgStickActive.get()
    ? res.__update(voiceMsgPieComp)
    : res
}

return voiceMsgPie
