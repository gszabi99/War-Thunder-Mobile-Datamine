
from "%scripts/dagui_library.nut" import *
let { is_ios, is_android } = require("%sqstd/platform.nut")
let { LT_GAIJIN, LT_GOOGLE, LT_FACEBOOK, LT_APPLE, LT_FIREBASE, LT_GUEST, availableLoginTypes
} = require("%appGlobals/loginState.nut")
let { saveProfile } = require("%scripts/clientState/saveProfile.nut")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")

const AUTOLOGIN_SAVE_ID = "autologin"
const AUTOLOGIN_TYPE_SAVE_ID = "autologinType"

let isAutologinUsed = mkHardWatched("login.isAutologinUsed", false)

let availableBase = { [LT_GAIJIN] = false } //loginType = isAutoLoginDefault
if (is_ios) {
  availableBase[LT_APPLE] <- true
  availableBase[LT_FACEBOOK] <- true
  availableBase[LT_GUEST] <- true
} else if (is_android)
  availableBase.__update({
    [LT_GOOGLE] = true,
    [LT_FIREBASE] = true,
    [LT_FACEBOOK] = true,
  })
let available = availableBase.filter(@(_, lt) availableLoginTypes?[lt] ?? false)

let validateLoginType = @(lt) lt in available ? lt : available.findvalue(@(_) true)
local defType = validateLoginType(is_ios ? LT_APPLE
  : is_android ? LT_GOOGLE
  : LT_GAIJIN)

let validateType = @(t) t in available ? t : defType
let getAutologinType = @() validateType(::load_local_shared_settings(AUTOLOGIN_TYPE_SAVE_ID))
let function setAutologinType(autologinType) {
  if (getAutologinType() == autologinType)
    return
  ::save_local_shared_settings(AUTOLOGIN_TYPE_SAVE_ID, autologinType)
  saveProfile()
}

let isAutologinEnabled = @() ::load_local_shared_settings(AUTOLOGIN_SAVE_ID) ?? false
let function setAutologinEnabled(isEnabled) {
  if (isAutologinEnabled() == isEnabled)
    return
  ::save_local_shared_settings(AUTOLOGIN_SAVE_ID, isEnabled)
  saveProfile()
}

return {
  getAutologinType
  setAutologinType
  isAutologinEnabled
  setAutologinEnabled
  isAutologinUsed
}
