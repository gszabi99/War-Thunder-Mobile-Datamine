from "%globalsDarg/darg_library.nut" import *
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")

let showRestorePurchasesDoneMsg = @()
  openFMsgBox({ text = loc("msg/restorePurchasesDone") })

return {
  showRestorePurchasesDoneMsg
}