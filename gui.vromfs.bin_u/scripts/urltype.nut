from "%scripts/dagui_library.nut" import *

let { regexp } = require("string")
let { getShortName } = require("%scripts/language.nut")
let enums = require("%sqStdLibs/helpers/enums.nut")
const URL_ANY_ENDING = @"(\/.*$|\/$|$)"

enum URL_CHECK_ORDER {
  BY_URL_REGEXP
  UNKNOWN
}

let g_url_type = {
  types = []

  template = {
    typeName = "" 
    sortOrder = URL_CHECK_ORDER.BY_URL_REGEXP
    isOnlineShop = false
    urlRegexpList = null 
    supportedLangs = ["ru", "en", "fr", "de", "es", "pl", "ja", "cs", "pt", "ko", "tr", "zh"] 
    langParamName = "skin_lang"

    isCorrespondsToUrl = function(url) {
      if (!this.urlRegexpList)
        return true
      foreach (r in this.urlRegexpList)
        if (r.match(url))
          return true
      return false
    }

    applyCurLang = function(url) {
      let langKey = this.getCurLangKey()
      return langKey ? this.applyLangKey(url, langKey) : url
    }
    getCurLangKey = function() {
      if (!this.supportedLangs)
        return null
      let curLang = getShortName()
      if (isInArray(curLang, this.supportedLangs))
        return curLang
      return null
    }
    applyLangKey = @(url, langKey)
      $"{url}{url.indexof("?") == null ? "?" : "&"}{this.langParamName}={langKey}"
  }

  function getByUrl(url) {
    foreach (urlType in this.types)
      if (urlType.isCorrespondsToUrl(url))
        return urlType
    return this.UNKNOWN
  }
}

enums.addTypes(g_url_type, {
  UNKNOWN = {
    sortOrder = URL_CHECK_ORDER.UNKNOWN
  }

  ONLINE_SHOP = {
    isOnlineShop = true
    urlRegexpList = [
      regexp("".concat(@"^https?:\/\/store\.gaijin\.net", URL_ANY_ENDING)),
      regexp("".concat(@"^https?:\/\/online\.gaijinent\.com", URL_ANY_ENDING)),
      regexp("".concat(@"^https?:\/\/trade\.gaijin\.net", URL_ANY_ENDING)),
      regexp("".concat(@"^https?:\/\/inventory-test-01\.gaijin\.lan", URL_ANY_ENDING)),
    ]
  }

  GAIJIN_PASS = {
    langParamName = "lang"
    urlRegexpList = [
      regexp("".concat(@"^https?:\/\/login\.gaijin\.net", URL_ANY_ENDING))
    ]
  }

  WARTHUNDER_RU = {
    urlRegexpList = [
      regexp("".concat(@"^https?:\/\/warthunder\.ru", URL_ANY_ENDING)),
    ]
  }

  WARTHUNDER_COM = {
    supportedLangs = ["ru", "en", "pl", "de", "cz", "fr", "es", "tr", "pt"] 
    urlRegexpList = [
      regexp("".concat(@"^https?:\/\/warthunder\.com", URL_ANY_ENDING)),
    ]
    applyLangKey = function(url, langKey) {
      let keyBeforeLang = ".com/"
      let idx = url.indexof(keyBeforeLang)
      if (idx == null)
        return "".concat(url, "/", langKey)

      let insertIdx = "".concat(idx, keyBeforeLang.len())
      local afterLangIdx = url.indexof("/", insertIdx)
      if (afterLangIdx == null || !isInArray(url.slice(insertIdx, afterLangIdx), this.supportedLangs))
        afterLangIdx = insertIdx
      else
        afterLangIdx++
      return "".concat(url.slice(0, insertIdx), langKey, "/", url.slice(afterLangIdx))
    }
  }
}, null, "typeName")

g_url_type.types.sort(function(a, b) {
  if (a.sortOrder != b.sortOrder)
    return a.sortOrder > b.sortOrder ? 1 : -1
  return 0
})

return {
  g_url_type
}