from "%globalsDarg/darg_library.nut" import *

let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")


let REWARDS_PREVIEW_MODAL_UID = "rewardsPreviewModal"

let closeRewardsPreviewModal = @() removeModalWindow(REWARDS_PREVIEW_MODAL_UID)

let openRewardsPreviewModal = @(content, title, onClick = null)
  addModalWindow(bgShaded.__merge({
    key = REWARDS_PREVIEW_MODAL_UID
    animations = wndSwitchAnim
    onDetach = onClick
    size = const [sw(100), sh(100)]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = modalWndBg.__merge({
      minWidth = SIZE_TO_CONTENT
      flow = FLOW_VERTICAL
      valign = ALIGN_TOP
      halign = ALIGN_CENTER
      stopMouse = true
      children = [
        modalWndHeaderWithClose(title,
          function() {
            closeRewardsPreviewModal()
            onClick?()
          },
          { minWidth = SIZE_TO_CONTENT })
        content
      ]
    })
  }))

return {
  openRewardsPreviewModal
  closeRewardsPreviewModal
}
