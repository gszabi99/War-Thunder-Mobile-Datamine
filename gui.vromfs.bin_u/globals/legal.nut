let { loc } = require("dagor.localize")

let curLang = loc("current_lang")
let TERMS_OF_SERVICE_URL = $"https://legal.gaijin.net/{curLang}/termsofservice"
let GAME_RULES_URL = $"https://legal.gaijin.net/{curLang}/gamerules"
let PRIVACY_POLICY_URL = $"https://legal.gaijin.net/{curLang}/privacypolicy"
let FORGOT_PASSWORD_URL = $"https://login.gaijin.net/{curLang}/sso/forgotPassword"
let REGISTER_URL = $"https://login.gaijin.net/{curLang}/profile/register"

let legalSorted = [
  {
    id = "termsofservice"
    url = TERMS_OF_SERVICE_URL
    locId = "termsOfService"
  }
  {
    id = "gamerules"
    url = GAME_RULES_URL
    locId = "gameRules"
  }
  {
    id = "privacypolicy"
    url = PRIVACY_POLICY_URL
    locId = "instrumentalCase/privacyPolicy"
  }
]

let legalToApprove = {}
foreach(l in legalSorted)
  legalToApprove[l.id] <- l

return {
  legalSorted
  legalToApprove
  TERMS_OF_SERVICE_URL
  PRIVACY_POLICY_URL
  FORGOT_PASSWORD_URL
  REGISTER_URL
}