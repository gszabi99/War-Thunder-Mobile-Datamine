from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/squad/squadManager.nut" import leaveSquad, isInSquad


let notAvailableForSquadMsg = @(action, msg = null)
  !isInSquad.get() ? action()
    : openMsgBox({
        text = msg ?? loc("squad/gamemode_not_available_for_squad")
        buttons = [
          { text = loc("squadAction/leave"),
            function cb() {
              leaveSquad()
              action()
            }
          }
          { id = "cancel", styleId = "PRIMARY", isCancel = true }
        ]
      })

return notAvailableForSquadMsg