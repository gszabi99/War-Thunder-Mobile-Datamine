from "%globalsDarg/darg_library.nut" import *
let { parse_json } = require("json")
let { httpRequest, HTTP_SUCCESS } = require("dagor.http")
let { getPlayerToken } = require("auth_wt")

let hasLog = {}
function logByUrlOnce(url, text) {
  if (!url || url in hasLog)
    return
  hasLog[url] <- true
  log(text)
}

function requestData(url, params, onSuccess, onFailure = null) {
  httpRequest({
    method = "POST"
    url
    data = params
    callback = function(response) {
      if (response.status != HTTP_SUCCESS || !response?.body) {
        onFailure?({ errCode = response.status })
        return
      }

      try {
        let str = response.body.as_string()
        if (str.startswith("<html>")) { 
          logByUrlOnce(url, $"ShopState: Request result is html page instead of data {url}\n{str}")
          onFailure?({ errText = "Request result is html page instead of data" })
          return
        }
        let data = parse_json(str)
        if (data?.status == "OK")
          onSuccess(data)
        else
          onFailure?(data)
      }
      catch(e) {
        logByUrlOnce(url, $"ShopState: Request result error {url}")
        onFailure?({ errText = "Failed to get body" })
      }
    }
  })
}

let createGuidsRequestParams = @(guids) "&".join(
  guids.map(@(guid) $"guids[]={guid}")
    .append($"jwt={getPlayerToken() ?? ""}&special=1"))

return {
  requestData
  createGuidsRequestParams
}