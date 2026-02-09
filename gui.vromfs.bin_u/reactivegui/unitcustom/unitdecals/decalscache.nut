from "%globalsDarg/darg_library.nut" import *
let logD = log_with_prefix("[DECALS] ")
let DataBlock = require("DataBlock")
let { eventbus_subscribe } = require("eventbus")
let { get_decals_blk } = require("blkGetters")
let { isLoggedIn } = require("%appGlobals/loginState.nut")


local decalsByCategories = null
local decalsImgById = {}
let decalsBlkVersion = Watched(0)

function getDecalsByCategories() {
  if (decalsByCategories)
    return decalsByCategories

  let decalsBlk = DataBlock()
  get_decals_blk(decalsBlk)

  local total = 0
  decalsByCategories = {}
  for (local i = 0; i < decalsBlk.blockCount(); i++) {
    let decalBlk = decalsBlk.getBlock(i)
    let decalId = decalBlk.getBlockName()
    let { category = "", lod1 = decalId } = decalBlk
    if (category not in decalsByCategories) {
      decalsByCategories[category] <- []
    }
    decalsByCategories[category].append(decalId)
    decalsImgById[decalId] <- lod1
    total++
  }

  logD($"Decals from blk loaded. categories: {decalsByCategories.len()}, total decals: {total}")
  return decalsByCategories
}

function getDecalImg(id) {
  let img = decalsImgById?[id]
  if (img != null)
    return img

  getDecalsByCategories()
  return decalsImgById?[id] ?? id
}

function invalidateCache() {
  decalsByCategories = null
  decalsImgById = {}
  decalsBlkVersion.set(decalsBlkVersion.get() + 1)
}

isLoggedIn.subscribe(@(_) invalidateCache())
eventbus_subscribe("on_dl_content_skins_invalidate", @(_) invalidateCache())

return {
  getDecalsByCategories
  decalsBlkVersion
  getDecalImg
}
