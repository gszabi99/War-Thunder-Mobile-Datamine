from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { blk2SquirrelObjNoArrays, isDataBlock } = require("%sqstd/datablock.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { blockedResearchByBattleMods } = require("%appGlobals/pServer/battleMods.nut")
let { register_command } = require("console")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { G_BATTLE_MOD } = require("%appGlobals/rewardType.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")


let UNSEEN_BRANCHES = "unseenBranches"

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