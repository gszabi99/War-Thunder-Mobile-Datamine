from "%globalsDarg/darg_library.nut" import *
let { is_android, is_pc, is_ios } = require("%sqstd/platform.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { attachedAdsButtons } = require("adsInternalState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let {
  isAdsAvailable = Watched(false),
  isAdsVisible = Watched(false),
  canShowAds = Watched(false),
  showAdsForReward = @(_) null
  onTryShowNotAvailableAds = @() false
} = is_android || is_pc ? require("byPlatform/adsAndroid.nut") //for pc it in the debug mode
  : is_ios ? require("byPlatform/adsIOS.nut")
  : null

isInMenu.subscribe(@(_) isAdsVisible(false)) //in case of some bug by ads update

let changeAttachedAdsButtons = @(v) attachedAdsButtons.set(attachedAdsButtons.get() + v)

function showNotAvailableAdsMsg() {
  if (!onTryShowNotAvailableAds())
    openFMsgBox({ text = loc("msg/adsNotReadyYet") })
}

return {
  isAdsAvailable
  isAdsVisible
  canShowAds
  showAdsForReward
  changeAttachedAdsButtons
  adsButtonCounter = {
    onAttach = @() changeAttachedAdsButtons(1)
    onDetach = @() changeAttachedAdsButtons(-1)
  }
  showNotAvailableAdsMsg
}