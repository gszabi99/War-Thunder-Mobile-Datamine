from "%globalsDarg/darg_library.nut" import *
import "regexp2" as regexp2
from "%sqstd/string.nut" import lastIndexOf
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

let TOS_LOC_ID = getCurCircuitOverride("termsOfServiceLocId", "termsOfService")

let reDocId = regexp2(@"^[a-zA-Z0-9\-_]+$")
function extractDocIdFromUrl(url, defaultId) {
  let res = url.slice(lastIndexOf(url, "/") + 1)
  let isValid = reDocId.match(res)
  if (!isValid)
    logerr($"Legal: Can't extract doc ID from URL: \"{url}\"")
  return isValid ? res : defaultId
}

let legalSorted = [
  {
    type = "tos"
    id = extractDocIdFromUrl(TERMS_OF_SERVICE_URL, "termsofservice")
    url = TERMS_OF_SERVICE_URL
    locId = TOS_LOC_ID
    acceptWndLocId = TOS_LOC_ID
    subscriptionLocId = "subscription/renewalAgreement"
  }
  {
    type = "pp"
    id = extractDocIdFromUrl(PRIVACY_POLICY_URL, "privacypolicy")
    url = PRIVACY_POLICY_URL
    locId = "privacyPolicy"
    acceptWndLocId = "instrumentalCase/privacyPolicy"
    subscriptionLocId = "subscription/EULA"
    consentTcfIntroLocId = "consent_tcf/intro/desc/p4/privacyPolicyLink"
    consentTcfManageLocId = "consent_tcf/manage/desc/p4/privacyPolicyLink"
  }
]

let legalToApprove = {}
let legalByType = {}
foreach(l in legalSorted) {
  legalToApprove[l.id] <- l
  legalByType[l.type] <- l
}

return {
  legalSorted
  legalToApprove
  legalByType
  FORGOT_PASSWORD_URL
  REGISTER_URL
}