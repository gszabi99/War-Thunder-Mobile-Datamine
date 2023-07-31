//-file:plus-string
//checked for explicitness
#no-root-fallback
#explicit-this
from "%scripts/dagui_library.nut" import *
let { subscribe } = require("eventbus")
let { split_by_chars } = require("string")
let { shell_launch } = require("url")
let { get_authenticated_url_sso } = require("auth_wt")
let { to_string, parse } = require("json")
let { defer } = require("dagor.workcycle")
let logUrl = log_with_prefix("[URL] ")
let { clearBorderSymbols, lastIndexOf } = require("%sqstd/string.nut")
let base64 = require("base64")
let { isAuthorized } = require("%appGlobals/loginState.nut")
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

let openUrlExternalImpl = shell_launch
let function openUrlImpl(url, onCloseUrl) {
  local success = false
  if (is_android)
    success = require("android.webview").show(url, true, onCloseUrl)
  if (!success)
    openUrlExternalImpl(url)
}

subscribe("onAuthenticatedUrlResult", function(msg) {
  let { status, contextStr = "", url = null } = msg
  let { onCloseUrl = "", useExternalBrowser = false, notAuthUrl = "", shouldEncode = false
  } = contextStr != "" ? parse(contextStr) : null
  local urlToOpen = url
  local logPrefix = "request open authenticated"
  if (status == YU2_OK) {
    if (shouldEncode)
      urlToOpen = $"{url}&ret_enc=1" //This parameter is needed for coded complex links.
  }
  else {
    urlToOpen = notAuthUrl
    logPrefix = "request open after fail authenticate"
    ::send_error_log("Authorize url: failed to get authenticated url with error " + status,
      false, AUTH_ERROR_LOG_COLLECTION)
    if (urlToOpen == "")
      return
  }

  defer(function() { //open url action is still sync, and can be too long. So lauch it on the next frame
    if (useExternalBrowser) {
      logUrl($"{logPrefix} in external browser {urlToOpen} (base url = {notAuthUrl})")
      openUrlExternalImpl(urlToOpen)
    }
    else {
      logUrl($"{logPrefix} {urlToOpen} (base url = {notAuthUrl})")
      openUrlImpl(urlToOpen, onCloseUrl)
    }
  })
})

let function openAuthenticatedUrl(url, urlTags, onCloseUrl, useExternalBrowser) {
  let shouldEncode = !isInArray(URL_TAG_NO_ENCODING, urlTags)
  local autoLoginUrl = url
  if (shouldEncode)
    autoLoginUrl = base64.encodeString(autoLoginUrl)

  let ssoServiceTag = urlTags.filter(@(v) v.indexof(URL_TAG_SSO_SERVICE) == 0);
  let ssoService = ssoServiceTag.len() != 0 ? ssoServiceTag.pop().slice(URL_TAG_SSO_SERVICE.len()) : ""
  get_authenticated_url_sso(autoLoginUrl, "", ssoService, "onAuthenticatedUrlResult",
    to_string({ onCloseUrl, useExternalBrowser, notAuthUrl = url, shouldEncode }))
}

let function open(baseUrl, isAlreadyAuthenticated = false, onCloseUrl = "", useExternalBrowser=false) {
  if (baseUrl == null || baseUrl == "") {
    logUrl("Error: tried to open an empty url")
    return null
  }

  local url = clearBorderSymbols(baseUrl, [URL_TAGS_DELIMITER])
  let urlTags = split_by_chars(baseUrl, URL_TAGS_DELIMITER)
  if (!urlTags.len()) {
    logUrl("Error: tried to open an empty url")
    return null
  }
  let urlWithoutTags = urlTags.remove(urlTags.len() - 1)
  url = urlWithoutTags

  let urlType = ::g_url_type.getByUrl(url)
  if (isInArray(URL_TAG_AUTO_LOCALIZE, urlTags))
    url = urlType.applyCurLang(url)

  let shouldLogin = isInArray(URL_TAG_AUTO_LOGIN, urlTags)
  if (!isAlreadyAuthenticated && shouldLogin && isAuthorized.value) {
    logUrl($"request to authenticate url {url} (base url = {baseUrl})")
    openAuthenticatedUrl(url, urlTags, onCloseUrl, useExternalBrowser)
  }
  else if (useExternalBrowser) {
    logUrl($"request open in external browser {url} (base url = {baseUrl})")
    openUrlExternalImpl(url)
  }
  else {
    logUrl($"request open {url} (base url = {baseUrl})")
    openUrlImpl(url, onCloseUrl)
  }
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
  local linkStartIdx = lastIndexOf(link, URL_TAGS_DELIMITER)
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

let function openUrl(baseUrl, isAlreadyAuthenticated = false, biqQueryKey = "", onCloseUrl = "", useExternalBrowser = false) {
  let bigQueryInfoObject = { url = baseUrl }
  if (! ::u.isEmpty(biqQueryKey))
    bigQueryInfoObject["from"] <- biqQueryKey

  sendUiBqEvent("player_opens_external_browser", bigQueryInfoObject)

  open(baseUrl, isAlreadyAuthenticated, onCloseUrl, useExternalBrowser)
}

subscribe("openUrl", kwarg(openUrl))
::open_url <- openUrl //use in native code

return {
  openUrl
  validateLink
  getUrlWithQrRedirect
}
