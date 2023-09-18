from "%globalsDarg/darg_library.nut" import *
let { isLoginStarted } = require("%appGlobals/loginState.nut")
let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let mkLoginWnd = require("loginWnd.nut")
let { isUpdateInProgress } = require("loginUpdaterState.nut")
let mkLoginUpdater = require("loginUpdater.nut")
let { loadingAnimBg } = require("%globalsDarg/loading/loadingAnimBg.nut")
let { mkTitleLogo } = require("%globalsDarg/components/titleLogo.nut")
let { gradientLoadingTip } = require("%rGui/loading/mkLoadingTip.nut")

let key = {}
return @() {
  watch = [isInLoadingScreen, isLoginStarted, isUpdateInProgress]
  key
  size = flex()
  children = [
    loadingAnimBg
    isUpdateInProgress.value ? mkLoginUpdater()
      : isInLoadingScreen.value || isLoginStarted.value ? gradientLoadingTip
      : mkLoginWnd()
    mkTitleLogo({ margin = saBordersRv })
  ]
}