from "%globalScripts/logs.nut" import *
from "auth_wt" import getCountryCode
from "language" import getLocalLanguage
let { eventbus_subscribe } = require("eventbus")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let path = "%globalScripts/dirtyWords"
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
