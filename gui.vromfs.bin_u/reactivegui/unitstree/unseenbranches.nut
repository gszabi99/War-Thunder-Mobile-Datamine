from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "console" import register_command
from "eventbus" import eventbus_send
from "%sqstd/datablock.nut" import blk2SquirrelObjNoArrays, isDataBlock
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/battleMods.nut" import blockedResearchByBattleMods
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/rewardType.nut" import G_BATTLE_MOD
from "%rGui/shop/shopState.nut" import shopGoods


const UNSEEN_BRANCHES = "unseenBranches"

let unseenBranchesFromLS = Watched({})
let unseenBranches = Computed(function() {
  let res = {}
  foreach(campaign, branches in blockedResearchByBattleMods.get())
    foreach(country, battleMod in branches) {
      let battleModGoods = shopGoods.get()?.findvalue(@(goods)
        null != goods.rewards.findvalue(@(v) v.gType == G_BATTLE_MOD && v.id == battleMod))
      if (battleModGoods != null && (unseenBranchesFromLS.get()?[campaign][country] ?? true) != false)
        getSubTable(res, campaign)[country] <- true
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