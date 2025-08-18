from "%globalsDarg/darg_library.nut" import *
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { levelUpSizePx, levelUpFlag } = require("%rGui/levelUp/levelUpFlag.nut")
let { register_command } = require("console")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")

const WND_UID = "debug_level_up_flag"
let isOpened = mkWatched(persist, "isOpened", false)
let close = @() isOpened.set(false)
let animKey = Watched(0)

let flag = @() {
  watch = animKey
  children = levelUpFlag(levelUpSizePx[1], 16, 2, 0.5, { key = animKey.get() })
}

let openImpl = @() addModalWindow({
  key = WND_UID
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = flag
  onClick = @() animKey.set(animKey.get() + 1)
  hotkeys = [[btnBEscUp, { action = close, description = loc("Cancel") }]]
})

if (isOpened.get())
  openImpl()
isOpened.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))

register_command(@() isOpened.set(!isOpened.get()), "debug.levelUpHeader")