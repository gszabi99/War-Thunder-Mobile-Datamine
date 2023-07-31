from "%globalsDarg/darg_library.nut" import *
let { get_current_mission_name } = require("mission")
let { register_command } = require("console")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { firstBattleTutor, tutorialMissions } = require("%rGui/tutorial/tutorialMissions.nut")
let { needForceShow } = require("movementControlsTests.nut")

let haveApplied = mkWatched(persist, "haveApplied", false)
let needShowForDebug = mkWatched(persist, "needShowForDebug", false)
let isChooseMovementControlsOpened = mkWatched(persist, "isChooseMovementControlsOpened", false)

let needChooseMoveControlsTypeInBattle = Computed(@() !haveApplied.value
  && isInBattle.value
  && (needShowForDebug.value
    || (needForceShow.value
      && curCampaign.value == "tanks"
      && get_current_mission_name() == (tutorialMissions?[firstBattleTutor.value] ?? ""))
  ))

let needRealValueByDefault = Computed(@() !needChooseMoveControlsTypeInBattle.value)

let function onControlsApply(controlType) {
  if (needChooseMoveControlsTypeInBattle.value) {
    sendUiBqEvent("choose_tank_control_in_tutorial", { id = controlType })
    haveApplied(true)
    needShowForDebug(false)
    return
  }
  isChooseMovementControlsOpened(false)
}

register_command(function() {
  if (!isInBattle.value)
    console_print("This command works only in the battle") // warning disable: -forbidden-function
  haveApplied(false)
  needShowForDebug(true)
}, "ui.chooseMovementControlsInBattle")

return {
  needChooseMoveControlsTypeInBattle
  needRealValueByDefault
  onControlsApply
  isChooseMovementControlsOpened
  openChooseMovementControls = @() isChooseMovementControlsOpened(true)
}
