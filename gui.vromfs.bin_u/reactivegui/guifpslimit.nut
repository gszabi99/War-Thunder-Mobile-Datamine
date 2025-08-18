from "%globalsDarg/darg_library.nut" import *
let { set_gui_fps_limit_mode_active } = require("graphicsOptions")
let { isLoggedIn, isLoginRequired } = require("%appGlobals/loginState.nut")

let fpsLimits = Watched({})
let needFpsLimit = keepref(Computed(@() fpsLimits.get().len() > 0))

let addFpsLimit = @(id) fpsLimits.mutate(@(v) v[id] <- true)
function removeFpsLimit(id) {
  if (id in fpsLimits.get())
    fpsLimits.mutate(@(v) v.$rawdelete(id))
}

let needLoginFpsLimit = keepref(Computed(@() isLoginRequired.get() && !isLoggedIn.get()))
let updateLoginLimit = @(need) need ? addFpsLimit("login") : removeFpsLimit("login")
updateLoginLimit(needLoginFpsLimit.get())
needLoginFpsLimit.subscribe(updateLoginLimit)

set_gui_fps_limit_mode_active(needFpsLimit.get())
needFpsLimit.subscribe(@(v) set_gui_fps_limit_mode_active(v))

return {
  addFpsLimit
  removeFpsLimit
}