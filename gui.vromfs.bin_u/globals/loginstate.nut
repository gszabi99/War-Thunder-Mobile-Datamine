from "blkGetters" import get_settings_blk
from "frp" import Computed
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/math.nut" import number_of_set_bits
from "%sqstd/platform.nut" import is_ios, is_android, is_nswitch
import "%globalScripts/isAppLoaded.nut" as isAppLoaded
from "%appGlobals/clientState/initialState.nut" import shouldDisableMenu, isOfflineMenu
from "%appGlobals/curCircuitOverride.nut" import isExternalOperator


let { isHMSAvailable = @() false } = require("android.account.huawei")
let { getBuildMarket = @() "googleplay" } = require("android.platform")

let LOGIN_STATE = { 
  
  AUTHORIZED                  = 0x00001 
  GAME_UPDATED                = 0x00002
  ONLINE_BINARIES_INITED      = 0x00004

  PROFILE_RECEIVED            = 0x00010
  CONFIGS_RECEIVED            = 0x00020
  MATCHING_CONNECTED          = 0x00040
  CONFIGS_INITED              = 0x00080

  ONLINE_SETTINGS_AVAILABLE   = 0x00100
  LEGAL_ACCEPTED              = 0x00200
  CONTACTS_LOGGED_IN          = 0x00400
  TCF_CONSENT                 = 0x00800
  CONSENT_WND                 = 0x01000
  IOS_IDFA                    = 0x02000
  GOOGLE_CONSENT              = 0x04000

  
  HANGAR_LOADED               = 0x10000
  LOGIN_STARTED               = 0x20000
  PURCHASES_RECEIVED          = 0x40000

  
  NOT_LOGGED_IN               = 0x00000
  AUTH_AND_UPDATED            = 0x00003
  READY_TO_FULL_LOAD          = 0x00107
  READY_FOR_TCF_CONSENT       = 0x10700
  READY_FOR_OUR_CONSENT       = 0x00F00
  READY_FOR_IDFA              = 0x01F00
  READY_FOR_GOOGLE_CONSENT    = 0x03F00
  LOGGED_IN                   = 0x07FF7 
}

const LOGIN_UPDATER_EVENT_ID = "loginUpdaterEvent"

let loginState = hardPersistWatched("loginState", LOGIN_STATE.NOT_LOGGED_IN)
let isLoginRequired = hardPersistWatched("isLoginRequired", !shouldDisableMenu && !isOfflineMenu)
let curLoginType = hardPersistWatched("curLoginType", "")
let authTags = hardPersistWatched("authTags", [])
let isLoginByGajin = hardPersistWatched("isLoginByGajin", false)
let legalListForApprove = hardPersistWatched("legalsToApprove", {})
let isMatchingOnline = hardPersistWatched("isMatchingOnline", false)
let isConsentAllowLogin = hardPersistWatched("isConsentAllowLogin", false)
let goodleConsent = hardPersistWatched("googleConsent", null)
let isGoogleConsentShowed = Computed(@() goodleConsent.get()?.isShowed ?? false)
let isPreviewIDFAShowed = hardPersistWatched("isPreviewIDFAShowed", false)
let isReadyForShowPreviewIdfa = hardPersistWatched("isReadyForShowPreviewIdfa", false)
let isTcfConsentAllowLogin = hardPersistWatched("isTcfConsentAllowLogin", false)
let needLogoutAfterSession = hardPersistWatched("needLogoutAfterSession", false)

function getLoginStateDebugStr(state = null) {
  state = state ?? loginState.get()
  return ", ".join(
    (clone LOGIN_STATE).filter(@(bit) number_of_set_bits(bit) == 1 && (state & bit) != 0).keys())
}

let loginTypes = {
  LT_GAIJIN = "gaijin"
  LT_GOOGLE = "google"
  LT_APPLE = "apple"
  LT_FIREBASE = "firebase"
  LT_VKID = "vkid"
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

let authState = hardPersistWatched("login.authState", {
  loginType = loginTypes.LT_GAIJIN
  loginName = ""
  loginPas = ""
  twoStepAuthCode = ""
  check2StepAuthCode = false
  secStepType = secondStepTypes.SST_UNKNOWN
})

let isGoogleBuild = getBuildMarket() == "googleplay"
let isOnlyGuestLogin = get_settings_blk()?.onlyGuestLogin ?? false
local availableLoginTypes = { [loginTypes.LT_GAIJIN] = true }
if (is_ios) {
  availableLoginTypes[loginTypes.LT_APPLE] <- true
  availableLoginTypes[loginTypes.LT_FACEBOOK] <- true
  availableLoginTypes[loginTypes.LT_GUEST] <- true
}
else if (is_nswitch) {
  availableLoginTypes = { [loginTypes.LT_NSWITCH] = true }
}
else if (is_android) {
  if (isOnlyGuestLogin)
    availableLoginTypes = { [loginTypes.LT_FIREBASE] = true }
  else if (isExternalOperator()) {
     availableLoginTypes[loginTypes.LT_FIREBASE] <- true
     availableLoginTypes[loginTypes.LT_VKID] <- true
  }
  else
    availableLoginTypes.__update({
      [loginTypes.LT_GOOGLE] = isGoogleBuild,
      [loginTypes.LT_FIREBASE] = true,
      [loginTypes.LT_FACEBOOK] = isGoogleBuild,
      [loginTypes.LT_HUAWEI] = isHMSAvailable(),
    })
}

let isOnlineSettingsAvailable = Computed(@() (loginState.get() & LOGIN_STATE.ONLINE_SETTINGS_AVAILABLE) != 0)

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
  needLogoutAfterSession
  authState
  isConsentAllowLogin
  goodleConsent
  isGoogleConsentShowed
  isReadyForShowPreviewIdfa
  isPreviewIDFAShowed
  isTcfConsentAllowLogin

  CONSENT_OPTIONS_SAVE_ID = "consentManageOptions"
  TCF_CONSENT_ACCEPTED_SAVE_ID = "tcfConsentAccepted"

  isLoginStarted = Computed(@() (loginState.get() & LOGIN_STATE.LOGIN_STARTED) != 0)
  isAuthorized = Computed(@() (loginState.get() & LOGIN_STATE.AUTHORIZED) != 0)
  isOnlineSettingsAvailable
  isSettingsAvailable = Computed(@() isAppLoaded.get() && (isOnlineSettingsAvailable.get() || !isLoginRequired.get()))
  isMatchingConnected = Computed(@() (loginState.get() & LOGIN_STATE.MATCHING_CONNECTED) != 0)
  isProfileReceived = Computed(@() (loginState.get() & LOGIN_STATE.PROFILE_RECEIVED) != 0)
  isProfileConfigsReceived = Computed(@() (loginState.get() & LOGIN_STATE.CONFIGS_RECEIVED) != 0)
  isContactsLoggedIn = Computed(@() (loginState.get() & LOGIN_STATE.CONTACTS_LOGGED_IN) != 0)
  isOpenedLegalWnd = Computed(@() legalListForApprove.get().findvalue(@(v) v) != null)
  isGameUpdatedOnLogin = Computed(@() (loginState.get() & LOGIN_STATE.GAME_UPDATED) != 0)

  isLoggedIn = Computed(@() (loginState.get() & LOGIN_STATE.LOGGED_IN) == LOGIN_STATE.LOGGED_IN)
  isAuthAndUpdated = Computed(@() (loginState.get() & LOGIN_STATE.AUTH_AND_UPDATED) == LOGIN_STATE.AUTH_AND_UPDATED)
  isReadyToFullLoad = Computed(@() (loginState.get() & LOGIN_STATE.READY_TO_FULL_LOAD) == LOGIN_STATE.READY_TO_FULL_LOAD)
  isReadyForTcfConsent = Computed(@() (loginState.get() & LOGIN_STATE.READY_FOR_TCF_CONSENT) == LOGIN_STATE.READY_FOR_TCF_CONSENT)
  isReadyForGoogleConsent = Computed(@() (loginState.get() & LOGIN_STATE.READY_FOR_GOOGLE_CONSENT) == LOGIN_STATE.READY_FOR_GOOGLE_CONSENT)
  isReadyForConsent = Computed(@() (loginState.get() & LOGIN_STATE.READY_FOR_OUR_CONSENT) == LOGIN_STATE.READY_FOR_OUR_CONSENT)

  getLoginStateDebugStr
})