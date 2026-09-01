from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox


let showRestorePurchasesDoneMsg = @()
  openFMsgBox({ text = loc("msg/restorePurchasesDone") })

return {
  showRestorePurchasesDoneMsg
}