from "%scripts/dagui_library.nut" import *

let { LOGIN_STATE, LOGIN_UPDATER_EVENT_ID } = require("%appGlobals/loginState.nut")
let { setAutologinType, setAutologinEnabled } = require("%scripts/login/autoLogin.nut")
let { authState } = require("%scripts/login/authState.nut")
let { send_counter } = require("statsd")
let { subscribe } = require("eventbus")
let { start_updater_addons, stop_updater, UPDATER_EVENT_ERROR, UPDATER_EVENT_FINISH
} = require("contentUpdater")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")

let { onlyActiveStageCb, export, finalizeStage, interruptStage
} = require("mkStageBase.nut")("updateGame", LOGIN_STATE.AUTHORIZED, LOGIN_STATE.GAME_UPDATED)

let finish = onlyActiveStageCb(function() {
  let as = authState.value
  ::set_login_pass(as.loginName.tostring(), as.loginPas, AUTO_SAVE_FLG_LOGIN | AUTO_SAVE_FLG_PASS)
  setAutologinType(as.loginType)
  setAutologinEnabled(true)
  finalizeStage()
})

subscribe(LOGIN_UPDATER_EVENT_ID,
  onlyActiveStageCb(function(evt) {
    let { eventType } = evt
    if (eventType == UPDATER_EVENT_ERROR) {
      interruptStage(evt)
      openFMsgBox({
        uid = "login_updater_error"
        text = loc($"updater/error/{evt?.error}")
        isPersist = true
      })
    }
    else if (eventType == UPDATER_EVENT_FINISH)
      finish()
  }))

let function start() {
  if (start_updater_addons(LOGIN_UPDATER_EVENT_ID))
    send_counter("sq.updater.started", 1)
  else
    finish()
}

let function interrupt() {
  stop_updater()
  send_counter("sq.updater.signedout", 1)
}

return export.__merge({
  start
  interrupt
})