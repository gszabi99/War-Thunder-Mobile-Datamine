from "%globalsDarg/darg_library.nut" import *
let { is_android, is_pc, is_ios } = require("%sqstd/platform.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let {
  isAdsAvailable = Watched(false),
  isAdsVisible = Watched(false),
  canShowAds = Watched(false),
  showAdsForReward = @(_) null
} = is_android || is_pc ? require("byPlatform/adsAndroid.nut") //for pc it in the debug mode
  : is_ios ? require("byPlatform/adsIOS.nut")
  : null

isInMenu.subscribe(@(_) isAdsVisible(false)) //in case of some bug by ads update

return {
  isAdsAvailable
  isAdsVisible
  canShowAds
  showAdsForReward
}