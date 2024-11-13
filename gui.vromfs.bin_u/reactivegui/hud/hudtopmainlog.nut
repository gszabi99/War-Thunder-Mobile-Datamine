from "%globalsDarg/darg_library.nut" import *
let hudDamageLog = require("%rGui/hud/hudDamageLog.nut")
let { mainHintsBlock } = require("%rGui/hudHints/hintBlocks.nut")
let { getHudConfigParameter } = require("%rGui/hud/hudConfigParameters.nut")
let { lqTexturesWarningBattle } = require("%rGui/hudHints/lqTexturesWarning.nut")

let hudTopMainLog = @() {
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    { size = [SIZE_TO_CONTENT, hdpx(105)] }
    lqTexturesWarningBattle
    getHudConfigParameter("showDamageLog") ? hudDamageLog : null
    mainHintsBlock
  ]
}

return hudTopMainLog
