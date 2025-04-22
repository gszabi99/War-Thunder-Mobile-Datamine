from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { subscribeResetProfile } = require("%rGui/account/resetProfileDetector.nut")
let { TUTORIAL_BATTLE_PASS_ID, TUTORIAL_ARSENAL_ID, TUTORIAL_SLOT_ATTRIBUTES_ID,
  TUTORIAL_UNITS_RESEARCH_ID, TUTORIAL_TREE_EVENT } = require("tutorialConst.nut")


const SAVE_ID = "tutorials"
let completedTutorials = Watched({})

function markTutorialCompleted(id) {
  if (completedTutorials.get()?[id])
    return
  completedTutorials.mutate(@(v) v.$rawset(id, true))
  let blk = get_local_custom_settings_blk()
  blk.addBlock(SAVE_ID)[id] = true
  eventbus_send("saveProfile", {})
}

function loadCompletedTutorials() {
  if (!isOnlineSettingsAvailable.get()) {
    if (completedTutorials.get().len() != 0)
      completedTutorials.set({})
    return
  }
  let blk = get_local_custom_settings_blk()?[SAVE_ID]
  let list = {}
  if (isDataBlock(blk))
    eachParam(blk, function(isCompleted, id) {
      if (isCompleted)
       list[id] <- true
    })
  completedTutorials.set(list)
}

loadCompletedTutorials()
isOnlineSettingsAvailable.subscribe(@(_) loadCompletedTutorials())

let mkIsTutorialCompleted = @(id) Computed(@() completedTutorials.get()?[id] ?? false)
let isFinishedBattlePass = mkIsTutorialCompleted(TUTORIAL_BATTLE_PASS_ID)
let isFinishedSlotAttributes = mkIsTutorialCompleted(TUTORIAL_SLOT_ATTRIBUTES_ID)
let isFinishedArsenal = mkIsTutorialCompleted(TUTORIAL_ARSENAL_ID)
let isFinishedUnitsResearch = mkIsTutorialCompleted(TUTORIAL_UNITS_RESEARCH_ID)
let isFinishedEvent = mkIsTutorialCompleted(TUTORIAL_TREE_EVENT)

function resetAllTutorials() {
  if (completedTutorials.get().len() == 0)
    return

  completedTutorials.set({})
  get_local_custom_settings_blk().removeBlock(SAVE_ID)
  eventbus_send("saveProfile", {})
}

subscribeResetProfile(resetAllTutorials)
register_command(resetAllTutorials, "debug.reset_all_tutorials")
register_command(@() console_print(completedTutorials.get()), "debug.show_completed_tutorials") 

return {
  completedTutorials
  markTutorialCompleted
  mkIsTutorialCompleted

  isFinishedBattlePass
  isFinishedSlotAttributes
  isFinishedArsenal
  isFinishedUnitsResearch
  isFinishedEvent
}