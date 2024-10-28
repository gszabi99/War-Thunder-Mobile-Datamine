from "%globalsDarg/darg_library.nut" import *
let { is_android, is_pc, is_ios } = require("%sqstd/platform.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { attachedAdsButtons } = require("adsInternalState.nut")
let debugAs = require("dagor.system").get_arg_value_by_name("debugAs")
let {
  isAdsAvailable = Watched(false),
  isAdsVisible = Watched(false),
  isLoaded = Watched(false),
  showAdsForReward = @(_) null
} = is_ios || debugAs == "ios" ? require("byPlatform/adsIOS.nut")
  : is_android || is_pc ? require("byPlatform/adsAndroid.nut") //for pc it in the debug mode
  : null

isInMenu.subscribe(@(_) isAdsVisible(false)) //in case of some bug by ads update

let changeAttachedAdsButtons = @(v) attachedAdsButtons.set(attachedAdsButtons.get() + v)

return {
  isAdsAvailable
  isAdsVisible
  isLoaded
  showAdsForReward
  changeAttachedAdsButtons
  adsButtonCounter = {
    onAttach = @() changeAttachedAdsButtons(1)
    onDetach = @() changeAttachedAdsButtons(-1)
  }
}