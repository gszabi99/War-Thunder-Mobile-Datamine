from "%scripts/dagui_natives.nut" import send_error_log
from "%scripts/dagui_library.nut" import *

let { g_url_type } = require("urlType.nut")
let { register_command } = require("console")
let { getShortName } = require("%scripts/language.nut")
let { eventbus_subscribe } = require("eventbus")
let { split_by_chars } = require("string")
let { shell_launch } = require("url")
let { get_authenticated_url_sso } = require("auth_wt")
let { object_to_json_string, parse_json } = require("json")
let { defer } = require("dagor.workcycle")
let logUrl = log_with_prefix("[URL] ")
let { clearBorderSymbols, lastIndexOf } = require("%sqstd/string.nut")
let base64 = require("base64")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { is_android, is_ios, is_nswitch } = require("%sqstd/platform.nut")

const URL_TAGS_DELIMITER = " "
const URL_TAG_AUTO_LOCALIZE = "auto_local"
const URL_TAG_AUTO_LOGIN = "auto_login"
const URL_TAG_SSO_SERVICE = "sso_service="
const URL_TAG_NO_ENCODING = "no_encoding"

const AUTH_ERROR_LOG_COLLECTION = "log"

let qrRedirectSupportedLangs = ["ru", "en", "fr", "de", "es", "pl", "cs", "pt", "ko", "tr"]
const QR_REDIRECT_URL = "https://login.gaijin.net/{0}/qr/{1}"

let isDebugSsoLogin = mkWatched(persist, "isDebugSsoLogin", false)

function getUrlWithQrRedirect(url) {
  local lang = getShortName()
  if (!isInArray(lang, qrRedirectSupportedLangs))
    lang = "en"
  return QR_REDIRECT_URL.subst(lang, base64.encodeString(url))
}

let openUrlExternalImpl = @(url)
  shell_launch(!isDebugSsoLogin.get() ? url
    : url.replace("login.gaijin.net", "login-sso-test.gaijin.net"))

function openUrlImpl(url, onCloseUrl) {
  local success = false
  if (is_android)
    success = require("android.webview").show(url, true, onCloseUrl)
  if (is_ios)
    success = require("ios.webview").show(url)
  if (is_nswitch) {
    require("nswitch.network").openUrl(url)
    success = true
  }
  if (!success)
    openUrlExternalImpl(url)
}

eventbus_subscribe("onAuthenticatedUrlResult", function(msg) {
  let { status, contextStr = "", url = null } = msg
  let { onCloseUrl = "", useExternalBrowser = true, notAuthUrl = "", shouldEncode = false
  } = contextStr != "" ? parse_json(contextStr) : null
  local urlToOpen = url
  local logPrefix = "request open authenticated"
  if (status == YU2_OK) {
    if (shouldEncode)
      urlToOpen = $"{url}&ret_enc=1" 
  }
  else {
    urlToOpen = notAuthUrl
    logPrefix = "request open after fail authenticate"
    send_error_log($"Authorize url: failed to get authenticated url with error {status}",
      false, AUTH_ERROR_LOG_COLLECTION)
    if (urlToOpen == "")
      return
  }

  defer(function() { 
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

function openAuthenticatedUrl(url, urlTags, onCloseUrl, useExternalBrowser) {
  let shouldEncode = !isInArray(URL_TAG_NO_ENCODING, urlTags)
  local autoLoginUrl = url
  if (shouldEncode)
    autoLoginUrl = base64.encodeString(autoLoginUrl)

  let ssoServiceTag = urlTags.filter(@(v) v.indexof(URL_TAG_SSO_SERVICE) == 0);
  let ssoService = ssoServiceTag.len() != 0 ? ssoServiceTag.pop().slice(URL_TAG_SSO_SERVICE.len()) : ""
  get_authenticated_url_sso(autoLoginUrl, "", ssoService, "onAuthenticatedUrlResult",
    object_to_json_string({ onCloseUrl, useExternalBrowser, notAuthUrl = url, shouldEncode }))
}

function open(baseUrl, isAlreadyAuthenticated = false, onCloseUrl = "", useExternalBrowser=true) {
  if (baseUrl == null || baseUrl == "") {
    logUrl("Error: tried to open an empty url")
    return null
  }

  if (useExternalBrowser && is_nswitch)
    useExternalBrowser = false

  local url = clearBorderSymbols(baseUrl, [URL_TAGS_DELIMITER])
  let urlTags = split_by_chars(baseUrl, URL_TAGS_DELIMITER)
  if (!urlTags.len()) {
    logUrl("Error: tried to open an empty url")
    return null
  }
  let urlWithoutTags = urlTags.remove(urlTags.len() - 1)
  url = urlWithoutTags

  let urlType = g_url_type.getByUrl(url)
  if (isInArray(URL_TAG_AUTO_LOCALIZE, urlTags))
    url = urlType.applyCurLang(url)

  let shouldLogin = isInArray(URL_TAG_AUTO_LOGIN, urlTags)
  if (!isAlreadyAuthenticated && shouldLogin && isAuthorized.get()) {
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

function validateLink(link) {
  if (link == null)
    return null

  if (type(link) != "string") {
    log("CHECK LINK result: ", link)
    assert(false, "CHECK LINK: Link received not as text")
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

  log("CHECK LINK: Not found any localization string for link:", link)
  return null
}

function openUrl(baseUrl, isAlreadyAuthenticated = false, biqQueryKey = "", onCloseUrl = "", useExternalBrowser = true) {
  let bigQueryInfoObject = { url = baseUrl }
  if ((biqQueryKey ?? "") != "")
    bigQueryInfoObject["from"] <- biqQueryKey

  sendUiBqEvent("player_opens_external_browser", bigQueryInfoObject)

  open(baseUrl, isAlreadyAuthenticated, onCloseUrl, useExternalBrowser)
}

eventbus_subscribe("openUrl", kwarg(openUrl))

register_command(function() {
  isDebugSsoLogin.set(!isDebugSsoLogin.get())
  dlog("isDebug mode ? ", isDebugSsoLogin.get()) 
}, "url.login-sso-test")

return {
  openUrl
  validateLink
  getUrlWithQrRedirect
}
