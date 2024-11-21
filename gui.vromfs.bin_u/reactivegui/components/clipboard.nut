from "%globalsDarg/darg_library.nut" import *
let { set_clipboard_text } = require("dagor.clipboard")
let { showHint } = require("%rGui/tooltip.nut")

let CLIPBOARD_HINT_SHOW_TIME = 2

function copyToClipboard(evt, text) {
  set_clipboard_text(text)
  showHint(evt.targetRect, loc("msgbox/copied"), CLIPBOARD_HINT_SHOW_TIME)
}

return {
  copyToClipboard
}
