from "%globalScripts/autoSaveFlagConsts.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "auth_wt" import setLoginPass
from "contentUpdater" import start_updater_addons, stop_updater, UPDATER_EVENT_ERROR, UPDATER_EVENT_FINISH,
  UPDATER_RESULT_SUCCESS, UPDATER_RESULT_TERMINATED
from "eventbus" import eventbus_subscribe
from "statsd" import send_counter
from "%appGlobals/loginState.nut" import LOGIN_STATE, LOGIN_UPDATER_EVENT_ID, LT_GAIJIN
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%appGlobals/updater/updaterErrors.nut" import getErrorName
from "%rGui/login/authState.nut" import authState
from "%rGui/login/autoLogin.nut" import setAutologinType, setAutologinEnabled


let { onlyActiveStageCb, export, finalizeStage, interruptStage
} = require("mkStageBase.nut")("updateGame", LOGIN_STATE.AUTHORIZED | LOGIN_STATE.CONTACTS_LOGGED_IN, LOGIN_STATE.GAME_UPDATED)

let finish = onlyActiveStageCb(function() {
  send_counter("sq.updater.done", 1)

  let as = authState.get()
  let saveMask = as.loginType == LT_GAIJIN 
               ? AUTO_SAVE_FLG_LOGIN | AUTO_SAVE_FLG_PASS
               : AUTO_SAVE_FLG_DISABLE
  setLoginPass(as.loginName.tostring(), as.loginPas, saveMask)
  setAutologinType(as.loginType)
  setAutologinEnabled(true)
  finalizeStage()
})

local hasError = false
eventbus_subscribe(LOGIN_UPDATER_EVENT_ID,
  onlyActiveStageCb(function(evt) {
    let { eventType } = evt
    if (eventType == UPDATER_EVENT_ERROR) {
      interruptStage(evt)
      hasError = true
      openFMsgBox({
        uid = "login_updater_error"
        text = loc($"updater/error/{getErrorName(evt?.error ?? 0)}")
        isPersist = true
      })
    }
    else if (eventType == UPDATER_EVENT_FINISH) {
      let isSuccess = evt?.result == UPDATER_RESULT_SUCCESS
      if (isSuccess) {
        finish()
        return
      }

      interruptStage(evt)
      if (hasError)
        return

      let errId = evt?.result == UPDATER_RESULT_TERMINATED ? "terminated" : "initFailed"
      openFMsgBox({
        uid = "login_updater_error"
        text = loc($"updater/error/{errId}")
        isPersist = true
      })
    }
  }))

function start() {
  hasError = false
  if (start_updater_addons(LOGIN_UPDATER_EVENT_ID))
    send_counter("sq.updater.started", 1)
  else
    finish()
}

function interrupt() {
  stop_updater()
  send_counter("sq.updater.signedout", 1)
}

return export.__merge({
  start
  interrupt
})