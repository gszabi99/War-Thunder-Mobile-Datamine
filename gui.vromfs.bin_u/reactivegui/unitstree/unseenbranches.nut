from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { blk2SquirrelObjNoArrays, isDataBlock } = require("%sqstd/datablock.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { blockedResearchByBattleMods } = require("%appGlobals/pServer/battleMods.nut")
let { register_command } = require("console")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let UNSEEN_BRANCHES = "unseenBranches"

let unseenBranchesFromLS = Watched({})
let unseenBranches = Computed(function() {
  local res = {}
  foreach(campaign, branches in blockedResearchByBattleMods.get()) {
    res[campaign] <- {}
    foreach(country, _ in branches)
      if (unseenBranchesFromLS.get()?[campaign][country] != false)
        res[campaign][country] <- true
  }
  return res
})

let curCampaignUnseenBranches = Computed(@() unseenBranches.get()?[curCampaign.get()] ?? {})

function loadUnseenBranches() {
  if (!isLoggedIn.get())
    return
  let blk = get_local_custom_settings_blk()?[UNSEEN_BRANCHES]
  if (!isDataBlock(blk))
    return unseenBranchesFromLS.set({})
  unseenBranchesFromLS.set(blk2SquirrelObjNoArrays(blk))
}

isLoggedIn.subscribe(@(_) loadUnseenBranches())
loadUnseenBranches()

function markBranchSeen(campaign, country) {
  if (unseenBranches.get()?[campaign][country] != true)
    return
  get_local_custom_settings_blk().addBlock(UNSEEN_BRANCHES).addBlock(campaign)[country] = false
  eventbus_send("saveProfile", {})
  loadUnseenBranches()
}

register_command(function() {
  get_local_custom_settings_blk().removeBlock(UNSEEN_BRANCHES)
  eventbus_send("saveProfile", {})
  loadUnseenBranches()
}, "debug.mark_unit_branches_unseen")

return {
  curCampaignUnseenBranches
  markBranchSeen
}