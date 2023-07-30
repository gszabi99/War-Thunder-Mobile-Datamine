from "%globalsDarg/darg_library.nut" import *
let { set_gui_fps_limit_mode_active } = require("graphicsOptions")
let { isLoggedIn, isLoginRequired } = require("%appGlobals/loginState.nut")

let fpsLimits = Watched({})
let needFpsLimit = keepref(Computed(@() fpsLimits.value.len() > 0))

let addFpsLimit = @(id) fpsLimits.mutate(@(v) v[id] <- true)
let function removeFpsLimit(id) {
  if (id in fpsLimits.value)
    fpsLimits.mutate(@(v) delete v[id])
}

let needLoginFpsLimit = keepref(Computed(@() isLoginRequired.value && !isLoggedIn.value))
let updateLoginLimit = @(need) need ? addFpsLimit("login") : removeFpsLimit("login")
updateLoginLimit(needLoginFpsLimit.value)
needLoginFpsLimit.subscribe(updateLoginLimit)

set_gui_fps_limit_mode_active(needFpsLimit.value)
needFpsLimit.subscribe(@(v) set_gui_fps_limit_mode_active(v))

return {
  addFpsLimit
  removeFpsLimit
}