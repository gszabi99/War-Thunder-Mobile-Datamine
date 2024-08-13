from "%globalsDarg/darg_library.nut" import *
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { isPreviewIDFAShowed, isReadyForShowPreviewIdfa } = require("%appGlobals/loginState.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")

let PREWIEW_IDFA_WND_UID = "previewIDFAWnd"

function onSubmit() {
  sendUiBqEvent("ads_consent_idfa", { id = "submit_preview" })
  isPreviewIDFAShowed.set(true)
  isReadyForShowPreviewIdfa.set(false)
}

let sizeWnd = [hdpx(1200), hdpx(800)]

let textBlock = @(text, color){
  maxWidth = sizeWnd[0] * 0.7
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color
}.__update(fontTinyAccented)

let showPreviewWnd = @()
  addModalWindow({
    key = PREWIEW_IDFA_WND_UID
    size = flex()
    padding = saBordersRv
    rendObj = ROBJ_SOLID
    color = 0xD211141A
    onClick = onSubmit
    onAttach = @() sendUiBqEvent("ads_consent_idfa", { id = "open_preview" })

    children = {
      size = sizeWnd
      padding = hdpx(30)
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      halign = ALIGN_RIGHT
      rendObj = ROBJ_IMAGE
      image = Picture("ui/bkg/login_track_window.avif")
      children = [
        {
          vplace = ALIGN_TOP
          children = textBlock(loc("msg/IDFAWndDescription", { btn = colorize(0xFF699dcd, loc("msg/Allow")) }), 0xFFFFFFFF)
        }
        {
          size = [hdpx(425), hdpx(80)]
          pos = [-hdpx(120), -hdpx(140)]
          vplace = ALIGN_BOTTOM
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = textBlock(loc("msg/Allow"), 0xFF106099).__update(fontBig)
        }
        {
          pos = [-hdpx(150), 0]
          vplace = ALIGN_BOTTOM
          children = textButtonPrimary(loc("msgbox/btn_continue"), onSubmit)
        }
      ]
    }
    animations = wndSwitchAnim
  })

if(isReadyForShowPreviewIdfa.get())
  showPreviewWnd()

isReadyForShowPreviewIdfa.subscribe(function(v) {
  removeModalWindow(PREWIEW_IDFA_WND_UID)
  if (!v)
    return
  showPreviewWnd()
})