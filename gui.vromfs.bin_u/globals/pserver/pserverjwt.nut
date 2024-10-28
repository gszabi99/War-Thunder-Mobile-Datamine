
from "%globalScripts/logs.nut" import *
let { object_to_json_string } = require("json")
let io = require("io")
let { decode } = require("jwt")
let profilePublicKey = require("%appGlobals/profilePublicKey.nut")

function decodeJwtAndHandleErrors(data) {
  let jwt = type(data) == "string" ? data : data?.jwt ?? ""
  let jwtDecoded = decode(jwt, profilePublicKey)

  let { payload = null } = jwtDecoded
  let jwtError = jwtDecoded?.error
  if (payload != null && jwtError == null)
    return { jwt, payload }

  debugTableData(data)
  logerr($"Error '{jwtError}' during jwt profile decoding. See log for more details.")
  return { error = jwtError }
}

function saveJwtResultToJson(jwt, payload, fileName) {
  local file = io.file($"{fileName}.json", "wt+")
  file.writestring(object_to_json_string(payload, true))
  file.close()
  log($"Saved json payload to {fileName}")
  fileName = $"{fileName}.jwt"
  file = io.file(fileName, "wt+")
  file.writestring(jwt)
  file.close()
  console_print($"Saved jwt to {fileName}")
}

return {
  decodeJwtAndHandleErrors
  saveJwtResultToJson
}