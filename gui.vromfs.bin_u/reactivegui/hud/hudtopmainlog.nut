from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/hudConfigParameters.nut" import getHudConfigParameter
import "%rGui/hud/hudDamageLog.nut" as hudDamageLog
from "%rGui/hudHints/hintBlocks.nut" import mainHintsBlock
from "%rGui/hudHints/lqTexturesWarning.nut" import lqTexturesWarningBattle


let hudTopMainLog = @() {
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    { size = const [SIZE_TO_CONTENT, hdpx(105)] }
    lqTexturesWarningBattle
    getHudConfigParameter("showDamageLog") ? hudDamageLog : null
    mainHintsBlock
  ]
}

return hudTopMainLog
