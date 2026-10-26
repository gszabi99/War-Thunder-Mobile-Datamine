from "%globalScripts/autoSaveFlagConsts.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "auth_wt" import setLoginPass
from "%appGlobals/loginState.nut" import LOGIN_STATE, isMatchingOnline, LT_GAIJIN
from "%rGui/login/authState.nut" import authState
from "%rGui/login/autoLogin.nut" import setAutologinType, setAutologinEnabled


let { onlyActiveStageCb, export, finalizeStage
} = require("mkStageBase.nut")("matching", LOGIN_STATE.AUTHORIZED | LOGIN_STATE.CONTACTS_LOGGED_IN, LOGIN_STATE.MATCHING_CONNECTED)

let finalize = onlyActiveStageCb(finalizeStage)
isMatchingOnline.subscribe(@(v) v ? finalize() : null)

function finalizeIfReady() {
  if (isMatchingOnline.get())
    finalize()
}

function start() {
  let as = authState.get()
  let saveMask = as.loginType == LT_GAIJIN 
    ? AUTO_SAVE_FLG_LOGIN | AUTO_SAVE_FLG_PASS
    : AUTO_SAVE_FLG_DISABLE
  setLoginPass(as.loginName.tostring(), as.loginPas, saveMask) 
  setAutologinType(as.loginType)
  setAutologinEnabled(true)

  finalizeIfReady()
}

return export.__merge({
  start
  restart = finalizeIfReady
})
