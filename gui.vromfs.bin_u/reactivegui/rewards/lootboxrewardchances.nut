from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { get_my_lootbox_chances, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let chances = Watched({})
servProfile.subscribe(@(_) chances.get().len() != 0 ? chances.set({}) : null)
serverConfigs.subscribe(@(_) chances.get().len() != 0 ? chances.set({}) : null)

registerHandler("onGetMyLootboxChances",
  function(res, context) {
    let { lootboxId } = context
    let data = clone res
    if ("error" not in res)
      data.$rawdelete("isCustom")
    chances.mutate(@(v) v[lootboxId] <- data)
  })

function refreshChances(lootboxId) {
  chances.mutate(@(v) v[lootboxId] <- null)
  get_my_lootbox_chances(lootboxId, { id = "onGetMyLootboxChances", lootboxId })
}

function mkLootboxChancesComp(lootboxId) {
  if (lootboxId not in chances.get())
    refreshChances(lootboxId)

  let res = Computed(function() {
    let lc = chances.get()?[lootboxId]
    return "error" in lc ? null : lc
  })
  res.subscribe(function(_) {
    if (lootboxId not in chances.get())
      defer(@() refreshChances(lootboxId))
  })
  return res
}

let mkIsLootboxChancesInProgress = @(lootboxId)
  Computed(@() lootboxId in chances.get() && chances.get()[lootboxId] == null)

return {
  mkLootboxChancesComp
  mkIsLootboxChancesInProgress
}