from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { isLoaded } = require("adsState.nut")
let { isOpenedAdsPreloaderWnd, closeAdsPreloader, hasAdsPreloadError, debugAdsWndParams } = require("adsInternalState.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { openMsgBox, closeMsgBox } = require("%rGui/components/msgBox.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { spinner } = require("%rGui/components/spinner.nut")

let canClosePreloader = Watched(false)
let setCanClosePreloader = @() canClosePreloader.set(true)

let CLOSE_BUTTON_DELAYED_TIME = 2.0
let DELAYED_TIME_AFTER_START_ADS = 15.0
let PRELOAD_WND_UID = "adsPreloaderWnd"
let MSG_UID_LEAVE_WINDOW = "leaveWindowAdsPreloader"

hasAdsPreloadError.subscribe(function(v) {
  if (!v || !isOpenedAdsPreloaderWnd.get() || !!debugAdsWndParams.get())
    return
  closeAdsPreloader()
  openMsgBox({ text = loc("error/ads/fail") })
})

isLoaded.subscribe(function(v) {
  if (v && isOpenedAdsPreloaderWnd.get()) {
    canClosePreloader.set(false)
    resetTimeout(DELAYED_TIME_AFTER_START_ADS, setCanClosePreloader)
  } else {
    clearTimer(setCanClosePreloader)
  }
})

let content = @()
  modalWndBg.__merge({
    size = const [hdpx(800), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    valign = ALIGN_TOP
    stopMouse = true
    children = [
      @() modalWndHeader(isLoaded.get() ? loc("shop/watchAdvert/trying") : loc("shop/watchAdvert/loading"),
        { watch = isLoaded })
      {
        size = FLEX_H
        flow = FLOW_VERTICAL
        valign = ALIGN_TOP
        padding = hdpx(40)
        gap = hdpx(40)
        children = [
          {
            hplace = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = spinner
          }
          @() {
            watch = canClosePreloader
            size = [SIZE_TO_CONTENT, defButtonHeight]
            vplace = ALIGN_BOTTOM
            hplace = ALIGN_CENTER
            children = canClosePreloader.get() ? textButtonPrimary(loc("msgbox/btn_cancel"), closeAdsPreloader) : null
          }
        ]
      }
    ]
  })

isOpenedAdsPreloaderWnd.subscribe(function(v) {
  removeModalWindow(PRELOAD_WND_UID)
  if (!v)
    return closeMsgBox(MSG_UID_LEAVE_WINDOW)
  addModalWindow(bgShaded.__merge({
    key = PRELOAD_WND_UID
    animations = wndSwitchAnim
    function onClick() {
      if (canClosePreloader.get())
        openMsgBox({
          uid = MSG_UID_LEAVE_WINDOW
          text = loc("msgbox/leaveWindow")
          buttons = [
            { id = "cancel", isCancel = true }
            { id = "ok", styleId = "PRIMARY", cb = closeAdsPreloader }
          ]
        })
    }
    function onAttach() {
      canClosePreloader.set(false)
      resetTimeout(CLOSE_BUTTON_DELAYED_TIME, setCanClosePreloader)
    }
    function onDetach() {
      clearTimer(setCanClosePreloader)
      hasAdsPreloadError.set(false)
    }
    sound = { click = "click" }
    size = const [sw(100), sh(100)]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = content
  }))
})