from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { mkStreakIcon, multiStageUnlockIdConfig, getUnlockLocText, getUnlockDescLocText
} = require("%rGui/unlocks/streakPkg.nut")
let { get_unlocks_blk} = require("blkGetters")
let { ceil } = require("%sqstd/math.nut")
let { rnd_int } = require("dagor.random")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")

let isOpened = mkWatched(persist, "isOpened", false)
let close = @() isOpened(false)
let wndHeaderHeight = hdpx(60)
let opacityGradientSize = saBorders[1]
let wndContentHeight = saSize[1] - wndHeaderHeight + opacityGradientSize
let hgap = hdpx(50)
let vgap = hdpx(20)
let iconSize = hdpx(140)

let columns = max(1, (saSize[0].tofloat() / (iconSize + hgap)).tointeger())

let wndHeader = {
  size = [flex(), wndHeaderHeight]
  valign = ALIGN_CENTER
  children = [
    backButton(close)
    {
      rendObj = ROBJ_TEXT
      size = FLEX_H
      halign = ALIGN_CENTER
      color = 0xFFFFFFFF
      text = "ui.debug.streak"
      margin = const [0, 0, 0, hdpx(15)]
    }.__update(fontBig)
  ]
}

function mkList() {
  let unlocks = (get_unlocks_blk() % "unlockable")?.filter(@(blk) blk?.type == "streak") ?? []
  unlocks.extend(multiStageUnlockIdConfig.reduce(@(res, val) res.append({ id = val[2], num = 2}, {id = val[3], num = 3}, {id = val.def, num = 9}), []))
  let rows = ceil(unlocks.len().tofloat() / columns).tointeger()
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = vgap
    halign = ALIGN_CENTER
    children = array(rows).map(@(_, row) {
      flow = FLOW_HORIZONTAL
      gap = hgap
      children = array(columns).map(function (_, column) {
        let idx = row * columns + column
        let item = unlocks?[idx]
        let repeatInARow = rnd_int(1, 3)
        let stateFlags = Watched(0)
        return item == null ? null
          : {
              key = item
              size = [iconSize, SIZE_TO_CONTENT]
              flow = FLOW_VERTICAL
              halign = ALIGN_CENTER
              behavior = Behaviors.Button
              onElemState = withTooltip(stateFlags, item, @() getUnlockDescLocText(item.id, repeatInARow))
              onDetach = tooltipDetach(stateFlags)
              children = [
                mkStreakIcon(item.id, iconSize, item?.num)
                {
                  size = [iconSize + hgap, SIZE_TO_CONTENT]
                  rendObj = ROBJ_TEXTAREA
                  behavior = Behaviors.TextArea
                  halign = ALIGN_CENTER
                  text = getUnlockLocText(item.id, repeatInARow)
                }
              ]
            }
      })
    })
  }
}

let pannableArea = verticalPannableAreaCtor(wndContentHeight, [opacityGradientSize, opacityGradientSize])
let mkDebugStreakWnd = @() bgShaded.__merge({
  key = isOpened
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  children = [
    wndHeader
    pannableArea(mkList)
  ]
  animations = wndSwitchAnim
})

registerScene("debugStreakWnd", mkDebugStreakWnd, close, isOpened)

register_command(@() isOpened(true), "ui.debug.streak")
