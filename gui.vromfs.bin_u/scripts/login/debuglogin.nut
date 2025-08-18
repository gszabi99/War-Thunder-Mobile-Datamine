from "%scripts/dagui_library.nut" import *
let logL = log_with_prefix("[LoginState] ")
let { register_command } = require("console")
let { FRP_INITIAL, ComputedImmediate } = require("%sqstd/frp.nut")
let { LOGIN_STATE, loginState, getLoginStateDebugStr } = require("%appGlobals/loginState.nut")

let debugState = @(shouldShowNotSetBits = false) console_print(
  shouldShowNotSetBits ? $"not set loginState = {getLoginStateDebugStr(LOGIN_STATE.LOGGED_IN & ~loginState.get())}"
    : $"loginState = {getLoginStateDebugStr()}")

register_command(@() debugState(false),  "login.debugCurState")
register_command(@() debugState(true), "login.debugNotSetState")

function logChanges(state, prev) {
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

let logComputed = keepref(ComputedImmediate(function(prev) {
  
  let state = loginState.get()
  if (prev != FRP_INITIAL)
    logChanges(state, prev)
  return state
}))
logComputed.subscribe(@(_) null) 
