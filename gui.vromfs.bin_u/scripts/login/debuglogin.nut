//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let logL = log_with_prefix("[LoginState] ")
let { register_command } = require("console")
let { FRP_INITIAL } = require("frp")
let { LOGIN_STATE, loginState, getLoginStateDebugStr } = require("%appGlobals/loginState.nut")

let debugState = @(shouldShowNotSetBits = false) console_print(
  shouldShowNotSetBits ? $"not set loginState = {getLoginStateDebugStr(LOGIN_STATE.LOGGED_IN & ~loginState.value)}"
    : $"loginState = {getLoginStateDebugStr()}")

register_command(@() debugState(false),  "login.debugCurState")
register_command(@() debugState(true), "login.debugNotSetState")

let function logChanges(state, prev) {
  if (state == LOGIN_STATE.NOT_LOGGED_IN) {
    logL("changed state to NOT_LOGGED_IN")
    return
  }

  let notChanged = state & prev
  let added = state & ~notChanged
  let removed = prev & ~notChanged
  local msg = removed == 0 ? $"add state {getLoginStateDebugStr(added)}"
    : added == 0 ? $"remove state {getLoginStateDebugStr(removed)}"
    : $"changed state to {getLoginStateDebugStr(state)}"
  if ((state & LOGIN_STATE.LOGGED_IN) == LOGIN_STATE.LOGGED_IN)
    msg = $"{msg} (LOGGED_IN)"
  logL(msg)
}

keepref(Computed(function(prev) {
  //use computed here only for side effect that it calculate before any subscribers on loginState will be called
  let state = loginState.value
  if (prev != FRP_INITIAL)
    logChanges(state, prev)
  return state
}))