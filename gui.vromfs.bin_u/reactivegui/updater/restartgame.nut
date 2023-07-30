from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { is_pc, is_android } = require("%sqstd/platform.nut")
let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")

let exitGame = @() send("exitGame", {})
let restartImpl = is_android ? require("android.platform").restartApp
  : is_pc ? @() send("restartGame", {})
  : exitGame
let canAutoRestart = restartImpl != exitGame //warning disable: -func-in-expression

let function restart() {
  if (isInLoadingScreen.value) {
    log("[RESTART] Ignore restart while in the loading")
    return
  }
  log("[RESTART] Restart game")
  send("prepareToRestartGame", {})
  restartImpl()
}

let showRestartMessage = @(text) openMsgBox({
  text
  buttons = [
    { id = "later", isCancel = true }
    { id = "restart", cb = restart, isPrimary = true, isDefault = true }
  ]
})

let autoRestartOrShowMessage = @(text) canAutoRestart ? restart()
  : showRestartMessage(text)

return {
  showRestartMessage
  autoRestartOrShowMessage
}