from "%globalsDarg/darg_library.nut" import *
let { is_android, is_pc, is_ios } = require("%sqstd/platform.nut")
let {
  isAdsAvailable = Watched(false),
  canShowAds = Watched(false),
  showAdsForReward = @(_) null
} = is_android || is_pc ? require("byPlatform/adsAndroid.nut") //for pc it in the debug mode
  : is_ios ? require("byPlatform/adsIOS.nut")
  : null

return {
  isAdsAvailable
  canShowAds
  showAdsForReward
}