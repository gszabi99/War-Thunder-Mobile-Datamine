from "dagor.localize" import loc, doesLocTextExist
from "%appGlobals/curCircuitOverride.nut" import getCurCircuitOverride

let LANG_LOC_ID = "current_lang"
if (!__static_analysis__)
  assert(doesLocTextExist(LANG_LOC_ID), $"No \"{LANG_LOC_ID}\" key in localization")
let legalLang = loc(LANG_LOC_ID, "en")

let TERMS_OF_SERVICE_URL = getCurCircuitOverride("termsOfServiceURL", "https://legal.gaijin.net/{lang}/termsofservice").subst({ lang = legalLang }) 
let PRIVACY_POLICY_URL = getCurCircuitOverride("privacyPolicyURL", "https://legal.gaijin.net/{lang}/privacypolicy").subst({ lang = legalLang }) 
let FORGOT_PASSWORD_URL = getCurCircuitOverride("recoveryPasswordURL", "https://login.gaijin.net/{lang}/sso/forgotPassword").subst({ lang = legalLang }) 
let REGISTER_URL = getCurCircuitOverride("signUpURL", "https://login.gaijin.net/{lang}/profile/register").subst({ lang = legalLang }) 

let legalSorted = [
  {
    id = "termsofservice"
    url = TERMS_OF_SERVICE_URL
    locId = "termsOfService"
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
  legalLang
  TERMS_OF_SERVICE_URL
  PRIVACY_POLICY_URL
  FORGOT_PASSWORD_URL
  REGISTER_URL
}