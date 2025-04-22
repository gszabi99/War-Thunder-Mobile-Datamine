from "%scripts/dagui_library.nut" import *

let logN = require("%sqstd/log.nut")().with_prefix("[NSWITCH_LOGIN]")
let nswitchAccount = require("nswitch.account")
let { subscribe_onehit, send } = require("eventbus")

function login_send_callback(params) {
  send("nswitch.account.login",params)
}

function login_nso_cb(result) {
  local nsa_error = null
  let {status} = result
  if (status == nswitchAccount.OK)
    nsa_error = null
  else if (status == nswitchAccount.COMMUNICATION_ERROR)
    nsa_error = "nswitch/login/nso_communication_error"
  else if ([nswitchAccount.NSO_SUBSRIPTION_FAILED, nswitchAccount.TOKEN_CACHE_UNAVAILABLE].contains(status))
    
    logN("nswitch: active user have no nso permissions")
  else if (status == nswitchAccount.TIMEOUT)
    nsa_error = "nswitch/login/nso_timeout_error"
  else
    nsa_error = "nswitch/login/nso_common_error"

  logN("login nsa status result is {0}".subst(nsa_error?nsa_error:"no_error"))
  if (nsa_error) {
    login_send_callback({errorStr = nsa_error})
    return
  }

  logN($"AppMakingConnectionId {nswitchAccount.getAppMakingConnectionId()}")

  
  let token = nswitchAccount.getNsaToken()
  let player_id = nswitchAccount.getNickname()

  login_send_callback({player_id, token })
}

function login_nswitch() {
  let user_id = nswitchAccount.getUserId()
  logN($"login NSO for user {user_id}")

  
  
  

  
  local nsa_error = nswitchAccount.loadNsaToken()
  local login_nintnendo_state = null

  if (nsa_error == nswitchAccount.NSA_UNAVAILABLE) {
    login_nintnendo_state = null;
    let result = nswitchAccount.loginToNsaWithShowingError();
    logN($"loginToNsaWithShowingError return {result}")
    if (result == nswitchAccount.OK) {
      nsa_error = nswitchAccount.OK
    }
  } else if (nsa_error == nswitchAccount.COMMUNICATION_ERROR
            || nsa_error == nswitchAccount.TERM_AGREEMENT_REQUIRED) {
    login_nintnendo_state = "nswitch/login/nso_communication_error"
  } else if (nsa_error != nswitchAccount.OK) {
    login_nintnendo_state = "nswitch/login/nso_common_error"
  }

  if (nsa_error != nswitchAccount.OK) {
    login_send_callback({ errorStr = login_nintnendo_state })
    return
  }

  logN("login_nintnendo_state:{0}".subst(login_nintnendo_state?login_nintnendo_state:"no_error"))
  if (nsa_error == nswitchAccount.OK) {

    subscribe_onehit("nswitch.account.onNsoStatus", function(result) {
      local status = result.status
      logN($"Received answer for remote authorize status: {status}")
      if (status == nswitchAccount.OK) {
        login_nso_cb({ status })
      } else { 
        logN($"login_nswitch_online - network issue: {status}")
        login_send_callback({errorStr = "nswitch/login/network_error"})
      }
    })

    logN("Waiting for console process user authorize with nintendo servers")
    nswitchAccount.requestNsoStatusAsync(50000)
  } else {
    logN($"login_nswitch_online check nsa:{nsa_error}")
    login_send_callback({errorStr = "nswitch/login/nso_communication_error"})
  }
}

return {
  login_nswitch
}


