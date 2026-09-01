from "%globalsDarg/darg_library.nut" import *
from "dagor.clipboard" import set_clipboard_text
from "%rGui/tooltip.nut" import showHint


const CLIPBOARD_HINT_SHOW_TIME = 2

function copyToClipboard(evt, text) {
  set_clipboard_text(text)
  showHint(evt.targetRect, loc("msgbox/copied"), CLIPBOARD_HINT_SHOW_TIME)
}

return {
  copyToClipboard
}
