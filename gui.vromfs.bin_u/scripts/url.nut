//-file:plus-string
//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let { split_by_chars } = require("string")
let { shell_launch, get_authenticated_url_sso } = require("url")
let { clearBorderSymbols } = require("%sqstd/string.nut")
let base64 = require("base64")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let eventbus = require("eventbus")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { is_android } = require("%sqstd/platform.nut")

const URL_TAGS_DELIMITER = " "
const URL_TAG_AUTO_LOCALIZE = "auto_local"
const URL_TAG_AUTO_LOGIN = "auto_login"
const URL_TAG_SSO_SERVICE = "sso_service="
const URL_TAG_NO_ENCODING = "no_encoding"

const AUTH_ERROR_LOG_COLLECTION = "log"

let qrRedirectSupportedLangs = ["ru", "en", "fr", "de", "es", "pl", "cs", "pt", "ko", "tr"]
const QR_REDIRECT_URL = "https://login.gaijin.net/{0}/qr/{1}"

let function getUrlWithQrRedirect(url) {
  local lang = ::g_language.getShortName()
  if (!isInArray(lang, qrRedirectSupportedLangs))
    lang = "en"
  return QR_REDIRECT_URL.subst(lang, base64.encodeString(url))
}

let canAutoLogin = @() isAuthorized.value

let function getAuthenticatedUrlConfig(baseUrl, isAlreadyAuthenticated = false) {
  if (baseUrl == null || baseUrl == "") {
    log("Error: tried to open an empty url")
    return null
  }

  local url = clearBorderSymbols(baseUrl, [URL_TAGS_DELIMITER])
  let urlTags = split_by_chars(baseUrl, URL_TAGS_DELIMITER)
  if (!urlTags.len()) {
    log("Error: tried to open an empty url")
    return null
  }
  let urlWithoutTags = urlTags.remove(urlTags.len() - 1)
  url = urlWithoutTags

  let urlType = ::g_url_type.getByUrl(url)
  if (isInArray(URL_TAG_AUTO_LOCALIZE, urlTags))
    url = urlType.applyCurLang(url)

  let shouldLogin = isInArray(URL_TAG_AUTO_LOGIN, urlTags)
  if (!isAlreadyAuthenticated && shouldLogin && canAutoLogin()) {
    let shouldEncode = !isInArray(URL_TAG_NO_ENCODING, urlTags)
    local autoLoginUrl = url
    if (shouldEncode)
      autoLoginUrl = base64.encodeString(autoLoginUrl)

    let ssoServiceTag = urlTags.filter(@(v) v.indexof(URL_TAG_SSO_SERVICE) == 0);
    let ssoService = ssoServiceTag.len() != 0 ? ssoServiceTag.pop().slice(URL_TAG_SSO_SERVICE.len()) : ""
    let authData = get_authenticated_url_sso(autoLoginUrl, ssoService)

    if (authData.yuplayResult == YU2_OK)
      url = authData.url + (shouldEncode ? "&ret_enc=1" : "") //This parameter is needed for coded complex links.
    else
      ::send_error_log("Authorize url: failed to get authenticated url with error " + authData.yuplayResult,
      false, AUTH_ERROR_LOG_COLLECTION)
  }

  return {
    url = url
    urlWithoutTags = urlWithoutTags
    urlTags = urlTags
    urlType = urlType
  }
}

let function open(baseUrl, isAlreadyAuthenticated = false, onCloseUrl = "") {
  let urlConfig = getAuthenticatedUrlConfig(baseUrl, isAlreadyAuthenticated)
  if (urlConfig == null)
    return

  let url = urlConfig.url
  let urlType = urlConfig.urlType

  log("Open url with urlType = " + urlType.typeName + ": " + url)
  log("Base Url = " + baseUrl)

  //shell_launch can be long sync function so call it delayed to avoid broke current call.
  ::get_gui_scene().performDelayed(getroottable(), function() {
    // External browser
    local success = false
    if (is_android)
      success = require("android.webview").show(url, true, onCloseUrl)
    if (!success)
      shell_launch(url)

    ::broadcastEvent("BrowserOpened", { url = url, external = true })
  })
}

local function validateLink(link) {
  if (link == null)
    return null

  if (!::u.isString(link)) {
    log("CHECK LINK result: " + toString(link))
    assert(false, "CHECK LINK: Link recieved not as text")
    return null
  }

  link = clearBorderSymbols(link, [URL_TAGS_DELIMITER])
  local linkStartIdx = ::g_string.lastIndexOf(link, URL_TAGS_DELIMITER)
  if (linkStartIdx < 0)
    linkStartIdx = 0

  if (link.indexof("://", linkStartIdx) != null)
    return link

  if (link.indexof("www.", linkStartIdx) != null)
    return link

  let localizedLink = loc(link, "")
  if (localizedLink != "")
    return localizedLink

  log("CHECK LINK: Not found any localization string for link: " + link)
  return null
}

let function openUrl(baseUrl, isAlreadyAuthenticated = false, biqQueryKey = "", onCloseUrl = "") {
  let bigQueryInfoObject = { url = baseUrl }
  if (! ::u.isEmpty(biqQueryKey))
    bigQueryInfoObject["from"] <- biqQueryKey

  sendUiBqEvent("player_opens_external_browser", bigQueryInfoObject)

  open(baseUrl, isAlreadyAuthenticated, onCloseUrl)
}

eventbus.subscribe("openUrl", kwarg(openUrl))
::open_url <- openUrl //use in native code

return {
  openUrl
  validateLink
  getAuthenticatedUrlConfig
  getUrlWithQrRedirect
}
