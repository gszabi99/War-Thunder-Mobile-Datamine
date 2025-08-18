from "%globalsDarg/darg_library.nut" import *
let { is_android, is_pc, is_ios } = require("%sqstd/platform.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { attachedAdsButtons } = require("%rGui/ads/adsInternalState.nut")
let debugAs = require("dagor.system").get_arg_value_by_name("debugAs")
let {
  isAdsAvailable = Watched(false),
  isAdsVisible = Watched(false),
  isLoaded = Watched(false),
  isInited = Watched(false),
  showAdsForReward = @(_) null
} = is_ios || debugAs == "ios" ? require("%rGui/ads/byPlatform/adsIOS.nut")
  : is_android || is_pc ? require("%rGui/ads/byPlatform/adsAndroid.nut") 
  : null

isInMenu.subscribe(@(_) isAdsVisible(false)) 

let changeAttachedAdsButtons = @(v) attachedAdsButtons.set(attachedAdsButtons.get() + v)

return {
  isAdsAvailable
  isAdsVisible
  isLoaded
  isProviderInited = Computed(@() isInited.get())
  showAdsForReward
  changeAttachedAdsButtons
  adsButtonCounter = {
    onAttach = @() changeAttachedAdsButtons(1)
    onDetach = @() changeAttachedAdsButtons(-1)
  }
}