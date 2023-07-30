from "%globalsDarg/darg_library.nut" import *
let menuButton = require("%rGui/hud/mkMenuButton.nut")()
let tacticalMapTransparent = require("components/tacticalMapTransparent.nut")
let { logerrAndKillLogPlace } = require("%rGui/hudHints/hintBlocks.nut")

return {
  flow = FLOW_HORIZONTAL
  gap = hdpx(40)
  children = [
    menuButton
    {
      flow = FLOW_VERTICAL
      children = [
        tacticalMapTransparent
        logerrAndKillLogPlace
      ]
    }
  ]
}