from "%globalsDarg/darg_library.nut" import *
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { levelUpSizePx, levelUpFlag } = require("levelUpFlag.nut")
let { register_command } = require("console")

const WND_UID = "debug_level_up_flag"
let isOpened = mkWatched(persist, "isOpened", false)
let close = @() isOpened(false)
let animKey = Watched(0)

let flag = @() {
  watch = animKey
  children = levelUpFlag(levelUpSizePx[1], 5, 0.5, { key = animKey.value })
}

let openImpl = @() addModalWindow({
  key = WND_UID
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = flag
  onClick = @() animKey(animKey.value + 1)
  hotkeys = [["^Esc", { action = close, description = loc("Cancel") }]]
})

if (isOpened.value)
  openImpl()
isOpened.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))

register_command(@() isOpened(!isOpened.value), "debug.levelUpHeader")