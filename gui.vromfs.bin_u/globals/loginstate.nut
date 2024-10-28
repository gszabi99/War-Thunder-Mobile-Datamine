let { Computed } = require("frp")
let { get_settings_blk } = require("blkGetters")
let { is_ios, is_android, is_nswitch } = require("%sqstd/platform.nut")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let { number_of_set_bits } = require("%sqstd/math.nut")
let { shouldDisableMenu, isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let isAppLoaded = require("%globalScripts/isAppLoaded.nut")
let { isHMSAvailable = @() false } = require("android.account.huawei")
let { getBuildMarket = @() "googleplay" } = require("android.platform")

let LOGIN_STATE = { //bit mask
  //before full load
  AUTHORIZED                  = 0x00001 //succesfully connected to auth
  GAME_UPDATED                = 0x00002
  ONLINE_BINARIES_INITED      = 0x00004

  PROFILE_RECEIVED            = 0x00010
  CONFIGS_RECEIVED            = 0x00020
  MATCHING_CONNECTED          = 0x00040
  CONFIGS_INITED              = 0x00080

  ONLINE_SETTINGS_AVAILABLE   = 0x00100
  LEGAL_ACCEPTED              = 0x00200
  CONTACTS_LOGGED_IN          = 0x00400
  GOOGLE_CONSENT              = 0x00800
  IOS_IDFA                    = 0x01000
  CONSENT_WND                 = 0x02000

  //not required for login
  HANGAR_LOADED               = 0x10000
  LOGIN_STARTED               = 0x20000
  PURCHASES_RECEIVED          = 0x40000

  //masks
  NOT_LOGGED_IN               = 0x00000
  AUTH_AND_UPDATED            = 0x00003
  READY_TO_FULL_LOAD          = 0x00107
  READY_FOR_GOOGLE_CONSENT    = 0x00700
  READY_FOR_IDFA              = 0x00F00
  READY_FOR_OUR_CONSENT       = 0x01F00
  LOGGED_IN                   = 0x03FF7 // logged in to all hosts and all configs are loaded
}

let LOGIN_UPDATER_EVENT_ID = "loginUpdaterEvent"

let loginState = sharedWatched("loginState", @() LOGIN_STATE.NOT_LOGGED_IN)
let isLoginRequired = sharedWatched("isLoginRequired", @() !shouldDisableMenu && !isOfflineMenu)
let curLoginType = sharedWatched("curLoginType", @() "")
let authTags = sharedWatched("authTags", @() [])
let isLoginByGajin = sharedWatched("isLoginByGajin", @() false)
let legalListForApprove = sharedWatched("legalsToApprove", @() {})
let isMatchingOnline = sharedWatched("isMatchingOnline", @() false)
let isConsentAllowLogin = sharedWatched("isConsentAllowLogin", @() false)
let goodleConsent = sharedWatched("googleConsent", @() null)
let isGoogleConsentShowed = Computed(@() goodleConsent.get()?.isShowed ?? false)
let isGoogleConsentAllowAds = Computed(@() goodleConsent.get()?.canRequest ?? false)
let isPreviewIDFAShowed = sharedWatched("isPreviewIDFAShowed", @() false)
let isReadyForShowPreviewIdfa = sharedWatched("isReadyForShowPreviewIdfa", @() false)

function getLoginStateDebugStr(state = null) {
  state = state ?? loginState.value
  return ", ".join(
    (clone LOGIN_STATE).filter(@(bit) number_of_set_bits(bit) == 1 && (state & bit) != 0).keys())
}

let loginTypes = {
  LT_GAIJIN = "gaijin"
  LT_GOOGLE = "google"
  LT_APPLE = "apple"
  LT_FIREBASE = "firebase"
  LT_GUEST = "guest"
  LT_FACEBOOK = "facebook"
  LT_NSWITCH = "nswitch"
  LT_HUAWEI = "huawei"
}

let secondStepTypes = {
  SST_MAIL = "Mail"
  SST_GA = "GA"
  SST_GP = "GP"
  SST_UNKNOWN = "Unknown"
}
let isGoogleBuild = getBuildMarket() == "googleplay"
let isOnlyGuestLogin = get_settings_blk()?.onlyGuestLogin ?? false
local availableLoginTypes = { [loginTypes.LT_GAIJIN] = true }
if (is_ios) {
  availableLoginTypes[loginTypes.LT_APPLE] <- true
  availableLoginTypes[loginTypes.LT_FACEBOOK] <- true
  availableLoginTypes[loginTypes.LT_GUEST] <- true
} else if (is_nswitch) {
  availableLoginTypes = { [loginTypes.LT_NSWITCH] = true }
} else if (is_android) {
  if (isOnlyGuestLogin)
    availableLoginTypes = { [loginTypes.LT_FIREBASE] = true }
  else
    availableLoginTypes.__update({
      [loginTypes.LT_GOOGLE] = isGoogleBuild,
      [loginTypes.LT_FIREBASE] = true,
      [loginTypes.LT_FACEBOOK] = isGoogleBuild,
      [loginTypes.LT_HUAWEI] = isHMSAvailable(),
    })
}

let isOnlineSettingsAvailable = Computed(@() (loginState.value & LOGIN_STATE.ONLINE_SETTINGS_AVAILABLE) != 0)

return loginTypes.__merge(secondStepTypes, {
  LOGIN_STATE
  LOGIN_UPDATER_EVENT_ID
  loginState
  isLoginRequired
  curLoginType
  authTags
  isLoginByGajin
  availableLoginTypes
  legalListForApprove
  isMatchingOnline
  isConsentAllowLogin
  goodleConsent
  isGoogleConsentShowed
  isGoogleConsentAllowAds
  isReadyForShowPreviewIdfa
  isPreviewIDFAShowed

  isLoginStarted = Computed(@() (loginState.value & LOGIN_STATE.LOGIN_STARTED) != 0)
  isAuthorized = Computed(@() (loginState.value & LOGIN_STATE.AUTHORIZED) != 0)
  isOnlineSettingsAvailable
  isSettingsAvailable = Computed(@() isAppLoaded.value && (isOnlineSettingsAvailable.value || !isLoginRequired.value))
  isMatchingConnected = Computed(@() (loginState.value & LOGIN_STATE.MATCHING_CONNECTED) != 0)
  isProfileReceived = Computed(@() (loginState.value & LOGIN_STATE.PROFILE_RECEIVED) != 0)
  isContactsLoggedIn = Computed(@() (loginState.value & LOGIN_STATE.CONTACTS_LOGGED_IN) != 0)
  isOpenedLegalWnd = Computed(@() legalListForApprove.value.findvalue(@(v) v) != null)

  isLoggedIn = Computed(@() (loginState.value & LOGIN_STATE.LOGGED_IN) == LOGIN_STATE.LOGGED_IN)
  isAuthAndUpdated = Computed(@() (loginState.value & LOGIN_STATE.AUTH_AND_UPDATED) == LOGIN_STATE.AUTH_AND_UPDATED)
  isReadyToFullLoad = Computed(@() (loginState.value & LOGIN_STATE.READY_TO_FULL_LOAD) == LOGIN_STATE.READY_TO_FULL_LOAD)
  isReadyForGoogleConsent = Computed(@() (loginState.value & LOGIN_STATE.READY_FOR_GOOGLE_CONSENT) == LOGIN_STATE.READY_FOR_GOOGLE_CONSENT)
  isReadyForConsent = Computed(@() (loginState.value & LOGIN_STATE.READY_FOR_OUR_CONSENT) == LOGIN_STATE.READY_FOR_OUR_CONSENT)

  getLoginStateDebugStr
})