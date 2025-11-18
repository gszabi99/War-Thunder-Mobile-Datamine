from "%scripts/dagui_library.nut" import *

let { setLoginPass } = require("auth_wt")
let { LOGIN_STATE, LOGIN_UPDATER_EVENT_ID } = require("%appGlobals/loginState.nut")
let { setAutologinType, setAutologinEnabled } = require("%scripts/login/autoLogin.nut")
let { authState } = require("%scripts/login/authState.nut")
let { send_counter } = require("statsd")
let { eventbus_subscribe } = require("eventbus")
let { start_updater_addons, stop_updater, UPDATER_EVENT_ERROR, UPDATER_EVENT_FINISH,
  UPDATER_RESULT_SUCCESS, UPDATER_RESULT_TERMINATED
} = require("contentUpdater")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")

let { onlyActiveStageCb, export, finalizeStage, interruptStage
} = require("mkStageBase.nut")("updateGame", LOGIN_STATE.AUTHORIZED | LOGIN_STATE.CONTACTS_LOGGED_IN, LOGIN_STATE.GAME_UPDATED)

let finish = onlyActiveStageCb(function() {
  send_counter("sq.updater.done", 1)

  let as = authState.get()
  setLoginPass(as.loginName.tostring(), as.loginPas, AUTO_SAVE_FLG_LOGIN | AUTO_SAVE_FLG_PASS)
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
        text = loc($"updater/error/{evt?.error}")
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