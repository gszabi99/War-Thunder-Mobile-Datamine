println("require('wtmRGui/main.nut')")
require("%rGui/main.nut")
let { isLoginRequired } = require("%appGlobals/loginState.nut")
isLoginRequired(false) //load scripts after login