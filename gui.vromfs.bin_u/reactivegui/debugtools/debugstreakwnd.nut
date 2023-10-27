from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { mkStreakIcon, multiStageUnlockIdConfig, getUnlockLocText } = require("%rGui/streak/streakPkg.nut")
let { get_unlocks_blk} = require("blkGetters")
let { ceil } = require("%sqstd/math.nut")
let { rnd_int } = require("dagor.random")

let isOpened = mkWatched(persist, "isOpened", false)
let close = @() isOpened(false)
let wndHeaderHeight = hdpx(60)
let hgap = hdpx(50)
let vgap = hdpx(20)
let iconSize = hdpx(140)

let columns = max(1, (sw(100).tofloat() / (iconSize + hgap)).tointeger())

let wndHeader = {
  size = [flex(), wndHeaderHeight]
  valign = ALIGN_CENTER
  children = [
    backButton(close)
    {
      rendObj = ROBJ_TEXT
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      color = 0xFFFFFFFF
      text = "ui.debug.streak"
      margin = [0, 0, 0, hdpx(15)]
    }.__update(fontBig)
  ]
}

function mkList() {
  let unlocks = (get_unlocks_blk() % "unlockable")?.filter(@(blk) blk?.type == "streak") ?? []
  unlocks.extend(multiStageUnlockIdConfig.reduce(@(res, val) res.append({ id = val[2], num = 2}, {id = val[3], num = 3}, {id = val.def, num = 9}), []))
  let rows = ceil(unlocks.len().tofloat() / columns)
  return {
    margin = [hdpx(20), hdpx(20), 0, 0]
    size = flex()
    flow = FLOW_VERTICAL
    gap = vgap
    halign = ALIGN_CENTER
    children = array(rows).map(@(_, row) {
      flow = FLOW_HORIZONTAL
      gap = hgap
      children = array(columns).map(function (_, column) {
        let idx = row * columns + column
        let item = unlocks?[idx] ?? {id = idx}
        return {
          size = [iconSize, SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          children = [
            mkStreakIcon(item.id, iconSize, item?.num)
            {
              size = [SIZE_TO_CONTENT, hdpx(20)]
              hplace = ALIGN_CENTER
              rendObj = ROBJ_TEXT
              text = getUnlockLocText(item.id, rnd_int(1, 3))
            }
          ]
        }
      })
    })
  }
}

let mkDebugStreakWnd = @() bgShaded.__merge({
  key = isOpened
  size = flex()
  padding = hdpx(40)
  flow = FLOW_VERTICAL
  children = [
    wndHeader
    mkList
  ]
  animations = wndSwitchAnim
})

registerScene("debugStreakWnd", mkDebugStreakWnd, close, isOpened)

register_command(@() isOpened(true), "ui.debug.streak")
