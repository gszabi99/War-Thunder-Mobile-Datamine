from "%appGlobals/curCircuitOverride.nut" import getCurCircuitOverride
from "%rGui/language.nut" import legalApiLngId, gjNetLngId

let TERMS_OF_SERVICE_URL = getCurCircuitOverride("termsOfServiceURL", "https://legal.gaijin.net/{lang}/termsofservice") 
  .subst({ lang = legalApiLngId })
let PRIVACY_POLICY_URL = getCurCircuitOverride("privacyPolicyURL", "https://legal.gaijin.net/{lang}/privacypolicy") 
  .subst({ lang = legalApiLngId })

let FORGOT_PASSWORD_URL = getCurCircuitOverride("recoveryPasswordURL", "https://login.gaijin.net/{lang}/sso/forgotPassword") 
  .subst({ lang = gjNetLngId })
let REGISTER_URL = getCurCircuitOverride("signUpURL", "https://login.gaijin.net/{lang}/profile/register") 
  .subst({ lang = gjNetLngId })

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
  TERMS_OF_SERVICE_URL
  PRIVACY_POLICY_URL
  FORGOT_PASSWORD_URL
  REGISTER_URL
}