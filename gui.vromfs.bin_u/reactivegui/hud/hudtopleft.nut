from "%globalsDarg/darg_library.nut" import *
let menuButton = require("%rGui/hud/mkMenuButton.nut")()
let { logerrAndKillLogPlace } = require("%rGui/hudHints/hintBlocks.nut")
let { tacticalMapSize } = require("%rGui/hud/components/tacticalMap.nut")

return {
  flow = FLOW_HORIZONTAL
  gap = hdpx(40)
  children = [
    menuButton
    {
      flow = FLOW_VERTICAL
      children = [
        { size = tacticalMapSize }
        logerrAndKillLogPlace
      ]
    }
  ]
}