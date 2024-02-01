from "%globalsDarg/darg_library.nut" import *

let isExperienceWndOpen = Watched(false)

function openExpWnd() {
  isExperienceWndOpen(true)
}

return {
  openExpWnd
  isExperienceWndOpen
}