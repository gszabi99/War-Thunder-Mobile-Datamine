from "%globalsDarg/darg_library.nut" import *

let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { backButton, backButtonWidth } = require("%rGui/components/backButton.nut")
let { bgMessage, bgHeader, bgShaded } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")


let REWARDS_PREVIEW_MODAL_UID = "rewardsPreviewModal"

let closeRewardsPreviewModal = @() removeModalWindow(REWARDS_PREVIEW_MODAL_UID)
let backButtonSize = [backButtonWidth / 2, backButtonWidth / 2]
let backBtn = @(handleClick) backButton(function() {
    closeRewardsPreviewModal()
    if(handleClick)
      handleClick()
  },
  {
    size = backButtonSize
    image = Picture($"ui/gameuiskin#mark_cross_white.svg:{backButtonSize[0]}:{backButtonSize[1]}")
  })

let openRewardsPreviewModal = @(content, title, onClick = null)
  addModalWindow(bgShaded.__merge({
    key = REWARDS_PREVIEW_MODAL_UID
    animations = wndSwitchAnim
    onDetach = onClick
    size = [sw(100), sh(100)]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      key = {}
      transform = {}
      safeAreaMargin = saBordersRv
      behavior = Behaviors.BoundToArea
      children = bgMessage.__merge({
        minWidth = hdpx(800)
        flow = FLOW_VERTICAL
        valign = ALIGN_TOP
        halign = ALIGN_CENTER
        stopMouse = true
        children = [
          bgHeader.__merge({
            size = [flex(), SIZE_TO_CONTENT]
            padding = hdpx(20)
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = [
              {
                size = [flex(), SIZE_TO_CONTENT]
                hplace = ALIGN_RIGHT
                halign = ALIGN_RIGHT
                children = backBtn(onClick)
              }
              {
                rendObj = ROBJ_TEXT
                text = title
              }.__update(fontSmallAccented)
            ]
          })
          content
        ]
      })
    }
  }))

return {
  openRewardsPreviewModal
  closeRewardsPreviewModal
}
