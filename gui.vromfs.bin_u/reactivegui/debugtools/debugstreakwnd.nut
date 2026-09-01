from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_unlocks_blk
from "console" import register_command
from "dagor.random" import rnd_int
from "%sqstd/math.nut" import ceil
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/navState.nut" import registerScene
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/tooltip.nut" import withTooltip, tooltipDetach
from "%rGui/unlocks/streakPkg.nut" import mkStreakIcon, multiStageUnlockIdConfig, getUnlockLocText, getUnlockDescLocText


let isOpened = mkWatched(persist, "isOpened", false)
let close = @() isOpened.set(false)
const wndHeaderHeight = hdpx(60)
let opacityGradientSize = saBorders[1]
let wndContentHeight = saSize[1] - wndHeaderHeight + opacityGradientSize
const hgap = hdpx(50)
const vgap = hdpx(20)
const iconSize = hdpx(140)

let columns = max(1, (saSize[0].tofloat() / (iconSize + hgap)).tointeger())

let wndHeader = {
  size = const [FLEX, wndHeaderHeight]
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
  let unlocks = multiStageUnlockIdConfig
    .reduce(@(res, val) res.extend([2, 3, 9, 11, 99].map(@(num) { id = val?[num] ?? val.def, num } )), [])
    .extend((get_unlocks_blk() % "unlockable")?.filter(@(blk) blk?.type == "streak") ?? [])
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
              size = const [iconSize, SIZE_TO_CONTENT]
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
                  text = getUnlockLocText(item.id, item?.num ?? repeatInARow)
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
  size = FLEX
  padding = saBordersRv
  flow = FLOW_VERTICAL
  children = [
    wndHeader
    pannableArea(mkList)
  ]
  animations = wndSwitchAnim
})

registerScene("debugStreakWnd", mkDebugStreakWnd, close, isOpened)

register_command(@() isOpened.set(true), "ui.debug.streak")
