from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { getCountryCode } = require("auth_wt")
let { get_cur_circuit_name } = require("app")
let { get_network_block } = require("blkGetters")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")




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

let supportUrl = Computed(@() loc(canUseZendeskSso.get() ? "url/support" : "url/support/nologin"))

let langCfg = {
  English = { locale = "en-US", lang = "english" }
  Russian = { locale = "ru",    lang = "russian" }
}

let categoryList = [
  "events_wtm"
  "violation_complaint_wtm"
  "game_suggestions_wtm"
  "bug_report_wtm"
  "account_block_wtm"
  "loss_account_wtm"
  "financial_issues_wtm"
  "gameplay_wtm"
  "technical_problems_wtm"
]

let getCategoryLocName = @(id) loc($"support/form/category/{id}")

let fieldCategory = hardPersistWatched("fieldCategory", "")

return {
  zendeskApiUploadsUrl
  zendeskApiRequestsUrl
  canUseZendeskApi
  openSuportWebsite = @() eventbus_send("openUrl", { baseUrl = supportUrl.get() })
  langCfg
  categoryList
  getCategoryLocName
  fieldCategory
}
