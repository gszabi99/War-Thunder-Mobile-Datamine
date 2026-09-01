from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/clientState/clientState.nut" import isInLoadingScreen
from "%appGlobals/loginState.nut" import isLoginStarted
from "%globalsDarg/components/titleLogo.nut" import mkTitleLogo
from "%globalsDarg/loading/loadingAnimBg.nut" import loadingAnimBg
import "%rGui/loading/loadingBeforeLogin.nut" as loadingBeforeLogin
import "%rGui/login/loginUpdater.nut" as mkLoginUpdater
from "%rGui/login/loginUpdaterState.nut" import isUpdateInProgress
import "%rGui/login/loginWnd.nut" as mkLoginWnd


let key = {}
return @() {
  watch = [isInLoadingScreen, isLoginStarted, isUpdateInProgress]
  key
  size = FLEX
  children = [
    loadingAnimBg
    isUpdateInProgress.get() ? mkLoginUpdater()
      : isInLoadingScreen.get() || isLoginStarted.get() ? loadingBeforeLogin
      : mkLoginWnd()
    mkTitleLogo({ margin = saBordersRv })
  ]
}