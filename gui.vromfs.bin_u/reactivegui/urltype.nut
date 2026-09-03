from "%globalsDarg/darg_library.nut" import *
from "string" import regexp
from "%rGui/language.nut" import curLangInfo, getGameLocalizationInfo

const URL_ANY_ENDING = @"(\/.*$|\/$|$)"

let mkUrlType = @(cfg, typeName) {
  typeName
  curLangKeyId = ""
  urlRegexpList = []
  isCorrespondsToUrl = @(url) this.urlRegexpList.findindex(@(r) r.match(url)) != null
  applyCurLang = @(url) this.curLangKeyId != ""
    ? this.applyLangKey(url, curLangInfo[this.curLangKeyId])
    : url
  applyLangKey = @(url, _) url
}.__update(cfg)

let defaultUrlType = mkUrlType({}, "")

let collectSupportedLangs = @(langKeyId) getGameLocalizationInfo()
  .reduce(@(res, v) res.$rawset(v[langKeyId], true), {}).keys()

let supportedLangsWT = collectSupportedLangs("wtLngId")
let supportedLangsWTMob = collectSupportedLangs("wtmobLngId")

function applyLangKeyAsParam(url, lang, paramName) {
  let sep = url.indexof("?") == null ? "?" : "&"
  return $"{url}{sep}{paramName}={lang}"
}

function applyLangKeyAfterDomainName(url, lang, dotTldName, supportedLangs) {
  assert(supportedLangs.len() != 0, "Empty supportedLangs passed to applyLangKeyAfterDomainName")
  let keyBeforeLang = $"{dotTldName}/"
  let idx = url.indexof(keyBeforeLang)
  if (idx == null)
    return "".concat(url, "/", lang)

  let insertIdx = idx + keyBeforeLang.len()
  local afterLangIdx = url.indexof("/", insertIdx)
  if (afterLangIdx == null || !supportedLangs.contains(url.slice(insertIdx, afterLangIdx)))
    afterLangIdx = insertIdx
  else
    afterLangIdx++
  return "".concat(url.slice(0, insertIdx), lang, "/", url.slice(afterLangIdx))
}

let urlTypes = [
  {
    typeName = "ONLINE_SHOP"
    curLangKeyId = "gjNetLngId"
    urlRegexpList = [
      regexp("".concat(@"^https?:\/\/store\.gaijin\.net", URL_ANY_ENDING)),
      regexp("".concat(@"^https?:\/\/online\.gaijinent\.com", URL_ANY_ENDING)),
      regexp("".concat(@"^https?:\/\/inventory-test-01\.gaijin\.lan", URL_ANY_ENDING)),
    ]
    applyLangKey = @(url, langKey) applyLangKeyAsParam(url, langKey, "skin_lang")
  }
  {
    typeName = "GAIJIN_PASS"
    curLangKeyId = "gjNetLngId"
    urlRegexpList = [
      regexp("".concat(@"^https?:\/\/login\.gaijin\.net", URL_ANY_ENDING))
    ]
    applyLangKey = @(url, langKey) applyLangKeyAsParam(url, langKey, "lang")
  }
  {
    typeName = "GAIJIN_COMMUNITY"
    curLangKeyId = "cmntLngId"
    urlRegexpList = [
      regexp("".concat(@"^https?:\/\/community\.gaijin\.net", URL_ANY_ENDING)),
    ]
    applyLangKey = @(url, langKey) applyLangKeyAsParam(url, langKey, "lng")
  }
  {
    typeName = "WARTHUNDER_RU"
    curLangKeyId = "wtLngId"
    urlRegexpList = [
      regexp("".concat(@"^https?:\/\/warthunder\.ru", URL_ANY_ENDING)),
    ]
    applyLangKey = @(url, _) applyLangKeyAfterDomainName(url, "ru", ".ru", supportedLangsWT)
  }
  {
    typeName = "WARTHUNDER_COM"
    curLangKeyId = "wtLngId"
    urlRegexpList = [
      regexp("".concat(@"^https?:\/\/warthunder\.com", URL_ANY_ENDING)),
    ]
    applyLangKey = @(url, langKey) applyLangKeyAfterDomainName(url, langKey, ".com", supportedLangsWT)
  }
  {
    typeName = "WTMOBILE_COM"
    curLangKeyId = "wtmobLngId"
    urlRegexpList = [
      regexp("".concat(@"^https?:\/\/wtmobile\.com", URL_ANY_ENDING)),
    ]
    applyLangKey = @(url, langKey) applyLangKeyAfterDomainName(url, langKey, ".com", supportedLangsWTMob)
  }
]
  .map(mkUrlType)

return {
  getUrlType = @(url) urlTypes.findvalue(@(t) t.isCorrespondsToUrl(url)) ?? defaultUrlType
}