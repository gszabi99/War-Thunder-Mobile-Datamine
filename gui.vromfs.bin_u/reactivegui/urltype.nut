from "%globalsDarg/darg_library.nut" import *
from "string" import regexp
from "%rGui/language.nut" import getShortName


const URL_ANY_ENDING = @"(\/.*$|\/$|$)"

let mkUrlType = @(cfg, typeName) {
  typeName
  isOnlineShop = false
  urlRegexpList = null 
  supportedLangs = ["ru", "en", "fr", "de", "es", "pl", "ja", "cs", "pt", "ko", "tr", "zh"] 
  langParamName = "skin_lang"

  function isCorrespondsToUrl(url) {
    if (!this.urlRegexpList)
      return true
    foreach (r in this.urlRegexpList)
      if (r.match(url))
        return true
    return false
  }

  function applyCurLang(url) {
    let langKey = this.getCurLangKey()
    return langKey ? this.applyLangKey(url, langKey) : url
  }
  function getCurLangKey() {
    if (!this.supportedLangs)
      return null
    let curLang = getShortName()
    if (this.supportedLangs.contains(curLang))
      return curLang
    return null
  }
  applyLangKey = @(url, langKey)
    $"{url}{url.indexof("?") == null ? "?" : "&"}{this.langParamName}={langKey}"
}.__update(cfg)

let defaultUrlType = mkUrlType({}, "")

let urlTypes = [
  {
    typeName = "ONLINE_SHOP"
    isOnlineShop = true
    urlRegexpList = [
      regexp("".concat(@"^https?:\/\/store\.gaijin\.net", URL_ANY_ENDING)),
      regexp("".concat(@"^https?:\/\/online\.gaijinent\.com", URL_ANY_ENDING)),
      regexp("".concat(@"^https?:\/\/trade\.gaijin\.net", URL_ANY_ENDING)),
      regexp("".concat(@"^https?:\/\/inventory-test-01\.gaijin\.lan", URL_ANY_ENDING)),
    ]
  }
  {
    typeName = "GAIJIN_PASS"
    langParamName = "lang"
    urlRegexpList = [
      regexp("".concat(@"^https?:\/\/login\.gaijin\.net", URL_ANY_ENDING))
    ]
  }
  {
    typeName = "WARTHUNDER_RU"
    urlRegexpList = [
      regexp("".concat(@"^https?:\/\/warthunder\.ru", URL_ANY_ENDING)),
    ]
  }
  {
    typeName = "GAIJIN_COMMUNITY"
    supportedLangs = ["ru", "en"]
    urlRegexpList = [
      regexp("".concat(@"^https?:\/\/community\.gaijin\.net", URL_ANY_ENDING)),
    ]
    applyLangKey = @(url, _) $"{url}{url.indexof("?") == null ? "?" : "&"}lng={loc("current_lang")}"
  }
  {
    typeName = "WARTHUNDER_COM"
    supportedLangs = ["ru", "en", "pl", "de", "cz", "fr", "es", "tr", "pt"] 
    urlRegexpList = [
      regexp("".concat(@"^https?:\/\/warthunder\.com", URL_ANY_ENDING)),
    ]
    applyLangKey = function(url, langKey) {
      const keyBeforeLang = ".com/"
      let idx = url.indexof(keyBeforeLang)
      if (idx == null)
        return "".concat(url, "/", langKey)

      let insertIdx = idx + keyBeforeLang.len()
      local afterLangIdx = url.indexof("/", insertIdx)
      if (afterLangIdx == null || !this.supportedLangs.contains(url.slice(insertIdx, afterLangIdx)))
        afterLangIdx = insertIdx
      else
        afterLangIdx++
      return "".concat(url.slice(0, insertIdx), langKey, "/", url.slice(afterLangIdx))
    }
  }
]
  .map(mkUrlType)

return {
  getUrlType = @(url) urlTypes.findvalue(@(t) t.isCorrespondsToUrl(url)) ?? defaultUrlType
}