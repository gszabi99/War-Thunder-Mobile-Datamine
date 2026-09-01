from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout, clearTimer
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/ads/adsInternalState.nut" import isOpenedAdsPreloaderWnd, closeAdsPreloader, hasAdsPreloadError,
  debugAdsWndParams, isShowStarted
from "%rGui/ads/adsState.nut" import isLoaded
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeader
from "%rGui/components/msgBox.nut" import openMsgBox, closeMsgBox
from "%rGui/components/spinner.nut" import spinner
from "%rGui/components/textButton.nut" import textButtonCommon
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


let canClosePreloader = Watched(false)
let setCanClosePreloader = @() canClosePreloader.set(true)

const CLOSE_BUTTON_DELAYED_TIME = 2.0
const DELAYED_TIME_AFTER_START_ADS = 15.0
const PRELOAD_WND_UID = "adsPreloaderWnd"
const MSG_UID_LEAVE_WINDOW = "leaveWindowAdsPreloader"

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
            children = canClosePreloader.get() ? textButtonCommon(utf8ToUpper(loc("msgbox/btn_cancel")), closeAdsPreloader) : null
          }
        ]
      }
    ]
  })

isOpenedAdsPreloaderWnd.subscribe(function(v) {
  removeModalWindow(PRELOAD_WND_UID)
  if (!v) {
    isShowStarted.set(false)
    return closeMsgBox(MSG_UID_LEAVE_WINDOW)
  }
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