//checked for explicitness
#no-root-fallback
#explicit-this

let platform = require("%sqstd/platform.nut")

return platform.__merge({
  // TODO: Remove those deprecated aliases
  targetPlatform = platform.platformId
  isPlatformPC = platform.is_pc

  // TODO: Remove all not supported platforms
  isPlatformXboxOne = false
  isPlatformPS4 = false
  isPlatformPS5 = false
  isPlatformSony = false
  isPlayerFromXboxOne = @(_name) false
  isPlayerFromPS4 = @(_name) false
  ps4RegionName = @() "ps4_not_supported"
})
