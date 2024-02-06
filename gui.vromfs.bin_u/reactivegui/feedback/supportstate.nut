from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { getCountryCode } = require("auth_wt")
let { get_cur_circuit_name } = require("app")
let { get_network_block } = require("blkGetters")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

// Zendesk.com website, Zendesk API (used in in-game support request form)
// and Zendesk SSO (used to login to support.gaijin.net website) are blocked in Russia by Roskomnadzor.

let ZENDESK_API_UPLOADS_URL_CFG_KEY = "zendeskApiUploadsURL"
let DEFAULT_ZENDESK_API_UPLOADS_URL  = "https://gaijin.zendesk.com/api/v2/uploads.json?filename={0}"
let ZENDESK_API_REQUESTS_URL_CFG_KEY = "zendeskApiRequestsURL"
let DEFAULT_ZENDESK_API_REQUESTS_URL = "https://gaijin.zendesk.com/api/v2/requests"

let zendeskApiUploadsUrl = Watched(DEFAULT_ZENDESK_API_UPLOADS_URL)
let zendeskApiRequestsUrl = Watched(DEFAULT_ZENDESK_API_REQUESTS_URL)
let canUseZendeskApi = Watched(false)
let canUseZendeskSso = Watched(false)

function updateUrls(isLoggedInVal) {
  let circuitBlk = get_network_block()?[get_cur_circuit_name()]
  let cfgUploadsUrl = circuitBlk?[ZENDESK_API_UPLOADS_URL_CFG_KEY] ?? ""
  let cfgRequestsUrl = circuitBlk?[ZENDESK_API_REQUESTS_URL_CFG_KEY] ?? ""
  let hasUrlsCfg = cfgUploadsUrl != "" && cfgRequestsUrl != ""
  zendeskApiUploadsUrl.set(hasUrlsCfg  ? cfgUploadsUrl  : DEFAULT_ZENDESK_API_UPLOADS_URL)
  zendeskApiRequestsUrl.set(hasUrlsCfg ? cfgRequestsUrl : DEFAULT_ZENDESK_API_REQUESTS_URL)

  let isRussia = getCountryCode() == "RU"
  canUseZendeskApi.set(isLoggedInVal && (hasUrlsCfg || !isRussia))
  canUseZendeskSso.set(isLoggedInVal && !isRussia)
}
isLoggedIn.subscribe(updateUrls)
updateUrls(isLoggedIn.get())

let supportUrl = Computed(@() loc(canUseZendeskSso.value ? "url/support" : "url/support/nologin"))

return {
  zendeskApiUploadsUrl
  zendeskApiRequestsUrl
  canUseZendeskApi
  openSuportWebsite = @() eventbus_send("openUrl", { baseUrl = supportUrl.value })
}
