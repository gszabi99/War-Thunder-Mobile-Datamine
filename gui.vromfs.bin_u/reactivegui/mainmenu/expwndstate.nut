from "%globalsDarg/darg_library.nut" import *

let isExpirienceWndOpen = Watched(false)

let function openExpWnd() {
  isExpirienceWndOpen(true)
}

return {
  openExpWnd
  isExpirienceWndOpen
}