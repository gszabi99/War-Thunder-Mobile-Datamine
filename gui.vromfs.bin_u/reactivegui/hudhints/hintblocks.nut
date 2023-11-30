from "%globalsDarg/darg_library.nut" import *
let mainHintLogState = require("mainHintLogState.nut")
let warningHintLogState = require("warningHintLogState.nut")
let logerrLogState = require("logerrLogState.nut")
let killLogState = require("killLogState.nut")
let commonHintLogState = require("commonHintLogState.nut")
let resultsHintLogState = require("resultsHintLogState.nut")
let { hintCtors, defaultHintCtor } = require("hintCtors.nut")

let hintsGap = hdpx(10)

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
let logerrAndKillLogPlace = {
  size = [0.3 * saSize[0], SIZE_TO_CONTENT] //FIXME: animations or position break when not fixed. So better to move all width consts to separate file, or push as param.
  flow = FLOW_VERTICAL
  children = [
    killLogBlock
    logerrHintsBlock
  ]
}

return {
  mainHintsBlock = mkHintsBlock(mainHintLogState.curEvents, { valign = ALIGN_TOP })
  warningHintsBlock = mkHintsBlock(warningHintLogState.curEvents, {}, { minHeight = hdpx(33) })
  commonHintsBlock = mkHintsBlock(commonHintLogState.curEvents)
  resultsHintsBlock = mkHintsBlock(resultsHintLogState.curEvents)
  logerrHintsBlock
  logerrAndKillLogPlace
}