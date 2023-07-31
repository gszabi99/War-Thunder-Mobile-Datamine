let TERMS_OF_SERVICE_URL = "https://legal.gaijin.net/termsofservice"
let PRIVACY_POLICY_URL = "https://legal.gaijin.net/privacypolicy"

let legalSorted = [
  {
    id = "privacypolicy"
    url = PRIVACY_POLICY_URL
    locId = "privacyPolicy"
  }
  {
    id = "termsofservice"
    url = TERMS_OF_SERVICE_URL
    locId = "termsOfService"
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
}