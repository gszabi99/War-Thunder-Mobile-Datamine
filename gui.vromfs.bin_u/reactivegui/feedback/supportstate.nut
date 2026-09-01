from "%globalsDarg/darg_library.nut" import *
from "app" import get_cur_circuit_name
from "auth_wt" import getCountryCode
from "blkGetters" import get_network_block
from "eventbus" import eventbus_send
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/curCircuitOverride.nut" import getCurCircuitOverride
from "%appGlobals/loginState.nut" import isLoggedIn





const ZENDESK_API_UPLOADS_URL_CFG_KEY = "zendeskApiUploadsURL"
const DEFAULT_ZENDESK_API_UPLOADS_URL  = "https://gaijin.zendesk.com/api/v2/uploads.json?filename={0}"
const ZENDESK_API_REQUESTS_URL_CFG_KEY = "zendeskApiRequestsURL"
const DEFAULT_ZENDESK_API_REQUESTS_URL = "https://gaijin.zendesk.com/api/v2/requests"

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

let supportUrl = Computed(@() canUseZendeskSso.get()
  ? loc("url/support")
  : getCurCircuitOverride("supportURL", loc("url/support/nologin")))

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
