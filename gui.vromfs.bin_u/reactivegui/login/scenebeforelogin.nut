from "%globalsDarg/darg_library.nut" import *
let { isLoginStarted } = require("%appGlobals/loginState.nut")
let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let mkLoginWnd = require("%rGui/login/loginWnd.nut")
let { isUpdateInProgress } = require("%rGui/login/loginUpdaterState.nut")
let mkLoginUpdater = require("%rGui/login/loginUpdater.nut")
let { loadingAnimBg } = require("%globalsDarg/loading/loadingAnimBg.nut")
let loadingBeforeLogin = require("%rGui/loading/loadingBeforeLogin.nut")
let { mkTitleLogo } = require("%globalsDarg/components/titleLogo.nut")

let key = {}
return @() {
  watch = [isInLoadingScreen, isLoginStarted, isUpdateInProgress]
  key
  size = flex()
  children = [
    loadingAnimBg
    isUpdateInProgress.get() ? mkLoginUpdater()
      : isInLoadingScreen.get() || isLoginStarted.get() ? loadingBeforeLogin
      : mkLoginWnd()
    mkTitleLogo({ margin = saBordersRv })
  ]
}