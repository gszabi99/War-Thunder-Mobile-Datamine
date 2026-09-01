from "%globalScripts/logs.nut" import *
from "auth_wt" import getCountryCode
from "eventbus" import eventbus_subscribe
from "language" import getLocalLanguage
from "%appGlobals/loginState.nut" import isLoggedIn


const path = "%globalScripts/dirtyWords"
let dirtyWordsFilter = require($"{path}/dirtyWords.nut")
let { init, continueInitAfterLogin } = dirtyWordsFilter

let initialize = @() init(getCountryCode(), getLocalLanguage(), [
  require($"{path}/dirtyWordsEnglish.nut"),
  require($"{path}/dirtyWordsRussian.nut"),
  require($"{path}/dirtyWordsChinese.nut"),
  require($"{path}/dirtyWordsJapanese.nut"),
])

initialize()

eventbus_subscribe("on_language_changed", @(_) initialize())

isLoggedIn.subscribe(@(v) v ? continueInitAfterLogin(getCountryCode()) : null)

return dirtyWordsFilter
