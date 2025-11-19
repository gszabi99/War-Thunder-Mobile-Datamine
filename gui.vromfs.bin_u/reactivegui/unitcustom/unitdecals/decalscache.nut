from "%globalsDarg/darg_library.nut" import *
let logD = log_with_prefix("[DECALS] ")
let DataBlock = require("DataBlock")
let { eventbus_subscribe } = require("eventbus")
let { get_decals_blk } = require("blkGetters")
let { isLoggedIn } = require("%appGlobals/loginState.nut")


local decalsByCategories = null
let decalsBlkVersion = Watched(0)

function getDecalsByCategories() {
  if (decalsByCategories)
    return decalsByCategories

  let decalsBlk = DataBlock()
  get_decals_blk(decalsBlk)

  let byCategory = {}
  local total = 0
  decalsByCategories = []
  for (local i = 0; i < decalsBlk.blockCount(); i++) {
    let decalBlk = decalsBlk.getBlock(i)
    let { category = "" } = decalBlk
    if (category not in byCategory) {
      byCategory[category] <- []
      decalsByCategories.append({ category, decals = byCategory[category] })
    }
    byCategory[category].append(decalBlk.getBlockName())
    total++
  }
  logD($"Decals from blk loaded. categories: {decalsByCategories.len()}, total decals: {total}")
  return decalsByCategories
}

function invalidateCache() {
  decalsByCategories = null
  decalsBlkVersion.set(decalsBlkVersion.get() + 1)
}

isLoggedIn.subscribe(@(_) invalidateCache())
eventbus_subscribe("on_dl_content_skins_invalidate", @(_) invalidateCache())

return {
  getDecalsByCategories
  decalsBlkVersion
}
