from "%globalScripts/yuplay2Consts.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "auth_wt" import get_authenticated_url_sso
import "base64" as base64
from "console" import register_command
from "dagor.workcycle" import defer
from "eventbus" import eventbus_subscribe
from "json" import object_to_json_string, parse_json
from "string" import split_by_chars
from "url" import shell_launch
from "%sqstd/platform.nut" import is_android, is_ios, is_nswitch
from "%sqstd/string.nut" import clearBorderSymbols, lastIndexOf
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/loginState.nut" import isAuthorized
from "%appGlobals/pServer/bqClient.nut" import sendUiBqEvent
from "%rGui/language.nut" import gjNetLngId
from "urlType.nut" import getUrlType
from "types" import String


let logUrl = log_with_prefix("[URL] ")

const URL_TAGS_DELIMITER = " "
const URL_TAG_AUTO_LOCALIZE = "auto_local"
const URL_TAG_AUTO_LOGIN = "auto_login"
const URL_TAG_SSO_SERVICE = "sso_service="
const URL_TAG_NO_ENCODING = "no_encoding"

const AUTH_ERROR_LOG_COLLECTION = "log"

const QR_REDIRECT_URL = "https://login.gaijin.net/{lang}/qr/{encUrl}" 

let isDebugSsoLogin = mkWatched(persist, "isDebugSsoLogin", false)

let getUrlWithQrRedirect = @(url) QR_REDIRECT_URL.subst({ lang = gjNetLngId, encUrl = base64.encodeString(url) })

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

local authUrlProgress = null
let authUrlQueue = []

function openAuthenticatedUrl(notAuthUrl, urlTags, onCloseUrl, useExternalBrowser) {
  let cfg = { notAuthUrl, urlTags, onCloseUrl, useExternalBrowser }
  if (authUrlProgress != null) {
    if (!isEqual(authUrlProgress, cfg) && null == authUrlQueue.findvalue(@(v) isEqual(v, cfg)))
      authUrlQueue.append(cfg)
    return
  }

  let shouldEncode = !urlTags.contains(URL_TAG_NO_ENCODING)
  local autoLoginUrl = notAuthUrl
  if (shouldEncode)
    autoLoginUrl = base64.encodeString(autoLoginUrl)

  let ssoServiceTag = urlTags.filter(@(v) v.indexof(URL_TAG_SSO_SERVICE) == 0);
  let ssoService = ssoServiceTag.len() != 0 ? ssoServiceTag.pop().slice(URL_TAG_SSO_SERVICE.len()) : ""
  authUrlProgress = cfg
  get_authenticated_url_sso(autoLoginUrl, "", ssoService, "onAuthenticatedUrlResult",
    object_to_json_string({ onCloseUrl, useExternalBrowser, notAuthUrl, shouldEncode }))
}

function startNextAuth() {
  if (authUrlQueue.len() == 0)
    return
  let { notAuthUrl, urlTags, onCloseUrl, useExternalBrowser } = authUrlQueue.remove(0)
  openAuthenticatedUrl(notAuthUrl, urlTags, onCloseUrl, useExternalBrowser)
}

eventbus_subscribe("onAuthenticatedUrlResult", function(msg) {
  authUrlProgress = null
  startNextAuth()

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
    logerr($"[{AUTH_ERROR_LOG_COLLECTION}] Authorize url: failed to get authenticated url with error {status}")
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

function open(baseUrl, isAlreadyAuthenticated = false, onCloseUrl = "", useExternalBrowser=true) {
  if (baseUrl == null || baseUrl == "") {
    logUrl("Error: tried to open an empty url")
    return null
  }

  if (useExternalBrowser && is_nswitch)
    useExternalBrowser = false

  local url = clearBorderSymbols(baseUrl, [URL_TAGS_DELIMITER])
  let urlTags = split_by_chars(url, URL_TAGS_DELIMITER)
  if (!urlTags.len()) {
    logUrl("Error: tried to open an empty url")
    return null
  }
  let urlWithoutTags = urlTags.remove(urlTags.len() - 1)
  url = urlWithoutTags

  let urlType = getUrlType(url)
  if (urlTags.contains(URL_TAG_AUTO_LOCALIZE))
    url = urlType.applyCurLang(url)

  let shouldLogin = urlTags.contains(URL_TAG_AUTO_LOGIN)
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

  if (!(link instanceof String)) {
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
