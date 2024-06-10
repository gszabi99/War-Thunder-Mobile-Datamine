from "%globalsDarg/darg_library.nut" import *
let mainHintLogState = require("mainHintLogState.nut")
let warningHintLogState = require("warningHintLogState.nut")
let logerrLogState = require("logerrLogState.nut")
let killLogState = require("killLogState.nut")
let commonHintLogState = require("commonHintLogState.nut")
let resultsHintLogState = require("resultsHintLogState.nut")
let { hintCtors, defaultHintCtor, maxChatLogWidth, maxChatLogHeight } = require("hintCtors.nut")
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { myUserName } = require("%appGlobals/profileStates.nut")
let { localPlayerColor } = require("%rGui/style/stdColors.nut")
let { teamBlueLightColor, teamRedLightColor } = require("%rGui/style/teamColors.nut")

let textsForLoggerEditView = [
  $"{colorize(localPlayerColor, myUserName.get())} {loc("icon/hud_msg_mp_dmg/kill_s_s")} {
      colorize(teamRedLightColor, loc("coop/Bot53"))}",
  $"{colorize(teamBlueLightColor, loc("coop/Bot31"))}{colon} {loc("voice_message_attack_enemy_troops_2")}",
  $"{colorize(teamBlueLightColor, loc("coop/Bot34"))}{colon} {loc("voice_message_yes_0")}",
]

let hintsGap = hdpx(10)

let mkTextLogger = @(text) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color = 0xFFFFFFFF
  fontFx = FFT_GLOW
  fontFxFactor = max(64, hdpx(64))
  fontFxColor = 0xFF000000
}

let mkTransition = @(uid, children, offset, zOrder, ovr) {
  key = uid
  zOrder
  size = flex()
  halign = ALIGN_CENTER
  children
  transform = { translate = [0, offset] }
  transitions = [{ prop = AnimProp.translate, duration = 0.3, easing = InOutQuad }]
}.__update(ovr)

let mkHintsBlock = @(events, transOvr = {}, blockOvr = {}) function mainHintsBlock() {
  local offset = 0
  let children = []
  foreach (hint in events.value) {
    let { hType = null, uid, zOrder = null } = hint
    let ctor = hintCtors?[hType] ?? defaultHintCtor
    let hintComp = ctor(hint)
    children.append(mkTransition(uid, hintComp, offset, zOrder, transOvr))
    offset += calc_comp_size(hintComp)[1] + hintsGap
  }

  return {
    watch = events
    size = [flex(), max(offset - hintsGap, 0)]
    children
  }.__update(blockOvr)
}

let logerrHintsBlock = mkHintsBlock(logerrLogState.curEvents, { halign = ALIGN_LEFT })
let killLogBlock = mkHintsBlock(killLogState.curEvents, { halign = ALIGN_LEFT })
let chatLogAndKillLogPlace = @() {
  size = [maxChatLogWidth, maxChatLogHeight] //FIXME: animations or position break when not fixed. So better to move all width consts to separate file, or push as param.
  flow = FLOW_VERTICAL
  children = [
    killLogBlock
    logerrHintsBlock
  ]
}

let chatLogAndKillLogEditView = {
  size = [maxChatLogWidth, maxChatLogHeight]
  rendObj = ROBJ_BOX
  valign = ALIGN_TOP
  flow = FLOW_VERTICAL
  padding = hdpx(5)
  gap = hdpx(10)
  borderWidth = hdpx(3)
  borderColor
  children = textsForLoggerEditView.map(@(text) mkTextLogger(text).__update(fontTiny))
}

return {
  mainHintsBlock = mkHintsBlock(mainHintLogState.curEvents, { valign = ALIGN_TOP })
  warningHintsBlock = mkHintsBlock(warningHintLogState.curEvents, {}, { minHeight = hdpx(33) })
  commonHintsBlock = mkHintsBlock(commonHintLogState.curEvents)
  resultsHintsBlock = mkHintsBlock(resultsHintLogState.curEvents)
  logerrHintsBlock
  chatLogAndKillLogPlace
  chatLogAndKillLogEditView
}