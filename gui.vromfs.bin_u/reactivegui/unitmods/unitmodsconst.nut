from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/tabs.nut" import tabExtraWidth
from "%rGui/style/gamercardStyle.nut" import gamercardHeight
from "%rGui/style/stdColors.nut" import selectColor


let tabContentMargin = [hdpx(10), hdpx(20)]

const modH = hdpx(130)
const modW = hdpx(302)

const blocksLineSize = hdpx(4)
const blocksPadding = hdpx(30)

let knobSize = evenPx(40)
const contentGamercardGap = hdpx(24)

return {
  tabH = modH
  tabW = modW + tabExtraWidth
  slotsBlockMargin = hdpx(12)
  catsBlockHeight = saSize[1] - gamercardHeight - contentGamercardGap
  tabContentMargin

  modH
  modW
  modsGap = hdpx(10)
  modsWidth = saSize[0] - modW - hdpx(60)
  modContentMargin = hdpxi(10)

  equippedFrameWidth = hdpx(4)
  equippedColor = 0xFFFFFFFF
  activeColor = selectColor

  blocksLineSize
  blocksPadding
  blocksGap = blocksPadding - blocksLineSize
  contentGamercardGap

  knobSize
  knobGap = hdpx(2)
  tabsOvr = { margin = [0, knobSize / 2, 0, knobSize / 2 - tabExtraWidth]}

  iconsCfg = {
    tank = {
      img = "selected_icon_tank.svg"
      imgOutline = "selected_icon_tank_outline.svg"
      size = const [hdpxi(95), hdpxi(41)]
    }
    ship = {
      img = "selected_icon.svg"
      imgOutline = "selected_icon_outline.svg"
      size = const [hdpxi(44), hdpxi(51)]
    }
  }

  hasAlwaysModsBtnByCamp = {
    air = true
    tanks = true
  }
}