from "%globalsDarg/darg_library.nut" import *
from "math" import round
from "%appGlobals/profileStates.nut" import myUserName
from "%rGui/hud/hudTouchButtonStyle.nut" import borderColor
import "%rGui/hudHints/commonHintLogState.nut" as commonHintLogState
from "%rGui/hudHints/hintCtors.nut" import hintCtors, defaultHintCtor
import "%rGui/hudHints/killLogState.nut" as killLogState
import "%rGui/hudHints/logerrLogState.nut" as logerrLogState
import "%rGui/hudHints/mainHintLogState.nut" as mainHintLogState
import "%rGui/hudHints/resultsHintLogState.nut" as resultsHintLogState
import "%rGui/hudHints/warningHintLogState.nut" as warningHintLogState
from "%rGui/hudState.nut" import areHintsHidden
from "%rGui/hudTuning/cfg/cfgOptions.nut" import getElemFont, getTextWidth
from "%rGui/hudTuning/hudTuningBattleState.nut" import curUnitHudTuningOptions
from "%rGui/style/stdColors.nut" import localPlayerColor
from "%rGui/style/teamColors.nut" import teamBlueLightColor, teamRedLightColor


let { maxKillLogEvents } = killLogState


const maxChatLogWidth = hdpx(600)

let getChatFont = @(o) getElemFont(o, "chatLogAndKillLog")
let getChatWidth = @(o) round(maxChatLogWidth * getTextWidth(o, "chatLogAndKillLog")).tointeger()

let textsForLoggerEditView = @(userName) [
  $"{colorize(localPlayerColor, userName)} {loc("icon/hud_msg_mp_dmg/kill_s_s")} {
      colorize(teamRedLightColor, loc("coop/Bot53"))}",
  $"{colorize(teamBlueLightColor, loc("coop/Bot31"))}{colon} {loc("voice_message_attack_enemy_troops_2")}",
  $"{colorize(teamBlueLightColor, loc("coop/Bot34"))}{colon} {loc("voice_message_yes_0")}",
  $"{colorize(teamRedLightColor, loc("coop/Bot174"))} {loc("icon/hud_msg_mp_dmg/kill_s_s")} {
      colorize(teamBlueLightColor, loc("coop/Bot528"))}",
  $"{colorize(teamBlueLightColor, loc("coop/Bot92"))}{colon} {loc("voice_message_attack_enemy_base_1")}",
]

const hintsGapBase = hdpx(10)

let mkTextLogger = @(text) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
}

let mkTransition = @(uid, children, offset, zOrder, ovr) {
  key = uid
  zOrder
  size = FLEX
  halign = ALIGN_CENTER
  children
  transform = { translate = [0, offset] }
  transitions = [{ prop = AnimProp.translate, duration = 0.3, easing = InOutQuad }]
}.__update(ovr)

let mkHintsBlock = @(events, transOvr = {}, blockOvr = {}, fontStyle = {}, hintsGap = hintsGapBase) function mainHintsBlock() {
  local offset = 0
  let children = []
  if (areHintsHidden.get())
    return { watch = [events, areHintsHidden] }

  foreach (hint in events.get()) {
    let { hType = null, uid, zOrder = null } = hint
    let ctor = hintCtors?[hType] ?? defaultHintCtor
    let hintComp = ctor(hint, fontStyle)
    children.append(mkTransition(uid, hintComp, offset, zOrder, transOvr))
    offset += calc_comp_size(hintComp)[1] + hintsGap
  }

  return {
    watch = [events, areHintsHidden]
    size = [FLEX, max(offset - hintsGap, 0)]
    children
  }.__update(blockOvr)
}

let calcChatHeight = @(font, gap) gap * maxKillLogEvents
  + (maxKillLogEvents + 1) * round(font.fontSize * 1.35).tointeger()
let chatGap = @(font) min(round(font.fontSize * 0.20).tointeger(), hdpxi(10))

let chatLogAndKillLogPlace = @() function() {
  let maxWidth = getChatWidth(curUnitHudTuningOptions.get())
  let font = { maxWidth }
    .__merge(getChatFont(curUnitHudTuningOptions.get()))
  let gap = chatGap(font)
  return {
    watch = curUnitHudTuningOptions
    size = [maxWidth, calcChatHeight(font, gap)]
    flow = FLOW_VERTICAL
    gap
    children = [
      mkHintsBlock(killLogState.curEvents, { halign = ALIGN_LEFT }, {}, font, gap)
      mkHintsBlock(logerrLogState.curEvents, { halign = ALIGN_LEFT }, {}, font, gap)
    ]
  }
}

function chatLogAndKillLogEditView(options) {
  let font = getChatFont(options)
  let gap = chatGap(font)
  return @() {
    watch = myUserName
    size = [getChatWidth(options), calcChatHeight(font, gap)]
    rendObj = ROBJ_BOX
    valign = ALIGN_TOP
    flow = FLOW_VERTICAL
    padding = hdpx(5)
    gap = gap
    borderWidth = hdpx(3)
    borderColor
    children = textsForLoggerEditView(myUserName.get()).map(@(text) mkTextLogger(text).__update(font))
  }
}

return {
  mainHintsBlock = mkHintsBlock(mainHintLogState.curEvents, { valign = ALIGN_TOP })
  warningHintsBlock = mkHintsBlock(warningHintLogState.curEvents, {}, { minHeight = hdpx(40) })
  commonHintsBlock = mkHintsBlock(commonHintLogState.curEvents, {}, { minHeight = hdpx(33) })
  resultsHintsBlock = mkHintsBlock(resultsHintLogState.curEvents)
  logerrHintsBlock = mkHintsBlock(logerrLogState.curEvents, { halign = ALIGN_LEFT })
  chatLogAndKillLogPlace
  chatLogAndKillLogEditView
}