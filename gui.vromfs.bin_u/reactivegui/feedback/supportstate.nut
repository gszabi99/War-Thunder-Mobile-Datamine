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
  let countryCode = getCountryCode()
  let hasDirectAccessToZendeskServices = countryCode != "" && countryCode != "RU"
  local hasZendeskApiUrls = hasDirectAccessToZendeskServices
  if (hasDirectAccessToZendeskServices) {
    zendeskApiUploadsUrl.set(DEFAULT_ZENDESK_API_UPLOADS_URL)
    zendeskApiRequestsUrl.set(DEFAULT_ZENDESK_API_REQUESTS_URL)
  }
  else {
    let circuitBlk = get_network_block()?[get_cur_circuit_name()]
    let cfgUploadsUrl = circuitBlk?[ZENDESK_API_UPLOADS_URL_CFG_KEY] ?? ""
    let cfgRequestsUrl = circuitBlk?[ZENDESK_API_REQUESTS_URL_CFG_KEY] ?? ""
    hasZendeskApiUrls = cfgUploadsUrl != "" && cfgRequestsUrl != ""
    zendeskApiUploadsUrl.set(hasZendeskApiUrls  ? cfgUploadsUrl  : DEFAULT_ZENDESK_API_UPLOADS_URL)
    zendeskApiRequestsUrl.set(hasZendeskApiUrls ? cfgRequestsUrl : DEFAULT_ZENDESK_API_REQUESTS_URL)
  }
  canUseZendeskApi.set(isLoggedInVal && hasZendeskApiUrls)
  canUseZendeskSso.set(isLoggedInVal && hasDirectAccessToZendeskServices)
}
isLoggedIn.subscribe(updateUrls)
updateUrls(isLoggedIn.get())

let supportUrl = Computed(@() loc(canUseZendeskSso.value ? "url/support" : "url/support/nologin"))

let langCfg = {
  English = { locale = "en-US", lang = "english" }
  Russian = { locale = "ru",    lang = "russian" }
}

let categoryCfg = [
  { id = "gameplay",  zenId = "\u0438\u0433\u0440\u043e\u0432\u043e\u0439_\u043f\u0440\u043e\u0446\u0435\u0441\u0441_\u043c\u043e\u0431" }
  { id = "financial", zenId = "\u0444\u0438\u043d\u0430\u043d\u0441\u043e\u0432\u044b\u0435_\u0432\u043e\u043f\u0440\u043e\u0441\u044b_\u043c\u043e\u0431" }
  { id = "personal",  zenId = "\u043f\u0435\u0440\u0441\u043e\u043d\u0430\u043b\u044c\u043d\u044b\u0435_\u0434\u0430\u043d\u043d\u044b\u0435_\u043c\u043e\u0431" }
]

return {
  zendeskApiUploadsUrl
  zendeskApiRequestsUrl
  canUseZendeskApi
  openSuportWebsite = @() eventbus_send("openUrl", { baseUrl = supportUrl.value })
  langCfg
  categoryCfg
}
