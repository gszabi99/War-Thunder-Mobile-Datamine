from "%globalsDarg/darg_library.nut" import *
let { warningHintsBlock, commonHintsBlock } = require("%rGui/hudHints/hintBlocks.nut")

return {
  size = [saSize[0] - hdpx(1100), SIZE_TO_CONTENT]
  pos = [0, 0.5 * saSize[1] + sh(18) - hdpx(74)]
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    warningHintsBlock
    commonHintsBlock
  ]
}
