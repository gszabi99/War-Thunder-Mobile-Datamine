from "%globalsDarg/darg_library.nut" import *
let { isLoginStarted } = require("%appGlobals/loginState.nut")
let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let loginWnd = require("loginWnd.nut")
let { isUpdateInProgress } = require("loginUpdaterState.nut")
let loginUpdater = require("loginUpdater.nut")
let { loadingAnimBg } = require("%globalsDarg/loading/loadingAnimBg.nut")
let { titleLogo } = require("%globalsDarg/components/titleLogo.nut")
let { gradientLoadingTip } = require("%rGui/loading/mkLoadingTip.nut")

let key = {}
return @() {
  watch = [isInLoadingScreen, isLoginStarted, isUpdateInProgress]
  key
  size = flex()
  children = [
    loadingAnimBg
    isUpdateInProgress.value ? loginUpdater
      : isInLoadingScreen.value || isLoginStarted.value ? gradientLoadingTip
      : loginWnd
    titleLogo.__merge({ margin = saBordersRv })
  ]
}