from "%globalsDarg/darg_library.nut" import *
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { leaveSquad, isInSquad } = require("%rGui/squad/squadManager.nut")

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