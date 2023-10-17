from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { getCountryCode } = require("auth_wt")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

// Zendesk.com website, Zendesk API (used in in-game suport request form)
// and Zendesk SSO (used to login to support.gaijin.net website) are blocked in Russia by Roskomnadzor.
let canUseZendesk = Computed(@() isLoggedIn.value && getCountryCode() != "RU")

let supportUrl = Computed(@() loc(canUseZendesk.value ? "url/support" : "url/support/nologin"))

return {
  canUseZendesk
  openSuportWebsite = @() send("openUrl", { baseUrl = supportUrl.value })
}
