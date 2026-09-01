from "%globalsDarg/darg_library.nut" import *
from "%sqstd/platform.nut" import is_android, is_pc, is_ios
from "%appGlobals/clientState/clientState.nut" import isInMenu
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/ads/adsInternalState.nut" import attachedAdsButtons


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

isInMenu.subscribe(@(_) isAdsVisible.set(false)) 

let battleAdsBonusesCfg = Computed(@() serverConfigs.get()?.gameProfile.battleAdBonuses ?? {})

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
  battleAdsBonusesCfg
}