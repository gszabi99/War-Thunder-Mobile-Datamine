from "%globalScripts/logs.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let path = "%globalScripts/dirtyWords"
let dirtyWordsFilter = require($"{path}/dirtyWords.nut")
let { init, continueInitAfterLogin } = dirtyWordsFilter

let initialize = @() init([
  require($"{path}/dirtyWordsEnglish.nut"),
  require($"{path}/dirtyWordsRussian.nut"),
  require($"{path}/dirtyWordsChinese.nut"),
  require($"{path}/dirtyWordsJapanese.nut"),
])

initialize()

eventbus_subscribe("on_language_changed", @(_) initialize())

isLoggedIn.subscribe(@(v) v ? continueInitAfterLogin() : null)

return dirtyWordsFilter
