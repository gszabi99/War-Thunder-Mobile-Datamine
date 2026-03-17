from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "%appGlobals/pServer/pServerApi.nut" import toggle_ab_test, reset_ab_tests, registerHandler
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs


let abTestsCfg = Computed(@() serverConfigs.get()?.abTestsCfg ?? {})

let registeredAbTests = {}
function registerAbTestCommandOnce(abTestId) {
  if (abTestId in registeredAbTests)
    return
  registeredAbTests[abTestId] <- true
  register_command(@() toggle_ab_test(abTestId, { id = "onDebugAbTest", name = abTestId }), $"debug.toggleAbTest.{abTestId}")
}

function registerAllAbTests(cfg) {
  foreach (id, _ in cfg)
    registerAbTestCommandOnce(id)
}

registerHandler("onDebugAbTest", function(res, context) {
  let { custom_info = {} } = res
  if (res?.error || custom_info.len() == 0)
    return
  let abTestStateMsg = "\n".join(custom_info.keys().map(@(k) $"{k}: {custom_info[k]}"))
  console_print($"Ab test {context.name}\n{abTestStateMsg}") 
})

registerAllAbTests(abTestsCfg.get())

abTestsCfg.subscribe(@(v) registerAllAbTests(v))

register_command(@() reset_ab_tests(), "debug.reset_ab_tests")