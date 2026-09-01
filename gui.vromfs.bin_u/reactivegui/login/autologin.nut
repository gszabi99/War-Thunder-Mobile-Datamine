from "%globalsDarg/darg_library.nut" import *
from "dagor.system" import dgs_get_settings
from "eventbus" import eventbus_send
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/platform.nut" import is_ios, is_android, is_nswitch
from "%appGlobals/loginState.nut" import LT_GAIJIN, LT_GOOGLE, LT_HUAWEI, LT_FACEBOOK, LT_APPLE, LT_FIREBASE, LT_VKID,
  LT_GUEST, LT_NSWITCH, availableLoginTypes
from "%appGlobals/clientState/localProfile.nut" import load_local_shared_settings, save_local_shared_settings


let saveProfile = @() eventbus_send("saveProfile", {})

const AUTOLOGIN_SAVE_ID = "autologin"
const AUTOLOGIN_TYPE_SAVE_ID = "autologinType"

let isAutologinUsed = hardPersistWatched("login.isAutologinUsed", false)

let availableBase = { [LT_GAIJIN] = false } 
if (is_ios) {
  availableBase[LT_APPLE] <- true
  availableBase[LT_FACEBOOK] <- true
  availableBase[LT_GUEST] <- true
} else if (is_nswitch) {
  availableBase[LT_NSWITCH] <- true
} else if (is_android)
  availableBase.__update({
    [LT_GOOGLE] = true,
    [LT_HUAWEI] = true,
    [LT_FIREBASE] = true,
    [LT_VKID] = true,
    [LT_FACEBOOK] = true,
  })
let available = availableBase.filter(@(_, lt) availableLoginTypes?[lt] ?? false)

let validateLoginType = @(lt) lt in available ? lt : available.keys().findvalue(@(_) true)
local defType = validateLoginType(is_ios ? LT_APPLE
  : is_android ? LT_GOOGLE
  : is_nswitch ? LT_NSWITCH
  : LT_GAIJIN)

let validateType = @(t) t in available ? t : defType
let getAutologinType = @() validateType(load_local_shared_settings(AUTOLOGIN_TYPE_SAVE_ID))
function setAutologinType(autologinType) {
  if (getAutologinType() == autologinType)
    return
  save_local_shared_settings(AUTOLOGIN_TYPE_SAVE_ID, autologinType)
  saveProfile()
}

let isAutoLoginOnFirstStart = is_nswitch
let isAutologinEnabled = @() (load_local_shared_settings(AUTOLOGIN_SAVE_ID) ?? isAutoLoginOnFirstStart)
  || (dgs_get_settings()?.yunetwork.forceAutoLogin ?? false)

function setAutologinEnabled(isEnabled) {
  if (isAutologinEnabled() == isEnabled)
    return
  save_local_shared_settings(AUTOLOGIN_SAVE_ID, isEnabled)
  saveProfile()
}

return {
  getAutologinType
  setAutologinType
  isAutologinEnabled
  setAutologinEnabled
  isAutologinUsed
}
