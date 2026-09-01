from "%globalScripts/yuplay2Consts.nut" import *
from "dagor.localize" import loc, doesLocTextExist
from "matching.errors" import SERVER_ERROR_MAINTENANCE, matching_error_string, is_matching_error
from "string" import format
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/curCircuitOverride.nut" import getCurCircuitOverride
from "%appGlobals/loginState.nut" import authState, SST_MAIL
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%appGlobals/pServer/bqClient.nut" import sendErrorLocIdBqEvent
from "types" import String


let lastSessionDebugInfo = hardPersistWatched("lastSessionDebugInfo", "")

let supportContact = getCurCircuitOverride("supportSite", "support.gaijin.net")

let customUrls = {
  [SERVER_ERROR_MAINTENANCE] =  getCurCircuitOverride("newsURL","https://www.wtmobile.com/news"),
  ["CANNOT_LOGIN_WITH_LINKED_ACCOUNT"] = "",
  [YU2_WRONG_2STEP_CODE] = getCurCircuitOverride("securitySettingsURL", loc($"url/profile/security")),
  [YU2_PROFILE_DELETED] = getCurCircuitOverride("feedbackSupportURL", loc($"url/feedback/support"))
}

function matchingErrData(error_text) {
  let bqLocId = $"matching/{error_text}"
  return {
    bqLocId
    text = loc("yn1/error/fmt",
      {
        text = loc("yn1/connect_error"),
        err_msg = doesLocTextExist(bqLocId) ? loc(bqLocId, { support = supportContact }) : error_text,
        err_code = ""
      })
  }
}

function defErrData(res) {
  let errCode = res == "0" ? "" : res
  let bqLocId = $"yn1/error/{errCode}"
  if (doesLocTextExist(bqLocId))
    return { bqLocId, text = loc(bqLocId, { support = supportContact }) }

  return {
    bqLocId
    text = loc("yn1/error/fmt", {
      text = loc("yn1/connect_error", "")
      err_msg = $"0x{errCode}"
      err_code = ""
    })
  }
}

function errorCodeToString(error_code) {
  if ([YU2_TIMEOUT, YU2_HOST_RESOLVE, YU2_SSL_ERROR, YU2_FAIL].contains(error_code))
    return "80130182"
  else if ([YU2_WRONG_LOGIN,YU2_WRONG_PARAMETER].contains(error_code))
    return "80130183"
  else if (error_code == YU2_FROZEN) 
    return "8111000E"
  else if (error_code == YU2_FROZEN_BRUTEFORCE)
    return "8111000F" 

  else if (error_code == YU2_SSL_CACERT)
    return "80130184" 

  else if (error_code == YU2_WRONG_2STEP_CODE) {
    let { secStepType } = authState.get()
    return secStepType == SST_MAIL ? "YU2_WRONG_2STEP_CODE_EMAIL" : "YU2_WRONG_2STEP_CODE"
  }

  return format("%X", error_code & 0xFFFFFFFF)
}

function getErrorData(error_code) {
  local errCode = error_code
  if (!(error_code instanceof String)) {
    errCode = errorCodeToString(error_code)
    if (is_matching_error(error_code))
      return matchingErrData(matching_error_string(error_code)).__update({ errCode })
  }
  return defErrData(errCode).__update({ errCode })
}

function getErrorMsgParams(errCodeBase) {
  local { text, errCode, bqLocId } = getErrorData(errCodeBase)
  return {
    uid = "errorMessageBox"
    viewType = "errorMsg"
    text
    bqLocId
    moreInfoLink = customUrls?[errCodeBase] ?? "".concat(getCurCircuitOverride("knowledgebaseURL",loc($"url/knowledgebase")), errCode)
    debugString = lastSessionDebugInfo.get()
  }
}

function errorMsgBox(errCode, buttons, ovr = {}) {
  let params = getErrorMsgParams(errCode)
  sendErrorLocIdBqEvent(params.bqLocId)
  openFMsgBox(params.__update(ovr, { buttons }))
}

return {
  errorMsgBox
  getErrorMsgParams
  lastSessionDebugInfo
}
