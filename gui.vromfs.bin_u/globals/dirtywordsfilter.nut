from "%globalScripts/logs.nut" import *
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let path = "%globalScripts/dirtyWords"
let dirtyWordsFilter = require($"{path}/dirtyWords.nut")
let { init, continueInitAfterLogin } = dirtyWordsFilter

init([
  require($"{path}/dirtyWordsEnglish.nut"),
  require($"{path}/dirtyWordsRussian.nut"),
  require($"{path}/dirtyWordsChinese.nut"),
  require($"{path}/dirtyWordsJapanese.nut"),
])

isLoggedIn.subscribe(@(v) v ? continueInitAfterLogin() : null)

return dirtyWordsFilter
