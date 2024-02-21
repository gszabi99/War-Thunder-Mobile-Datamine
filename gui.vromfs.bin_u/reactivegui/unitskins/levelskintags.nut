from "%globalsDarg/darg_library.nut" import *
let { get_current_mission_info_cached } = require("blkGetters")
let { blkFromPath, isDataBlock } = require("%sqstd/datablock.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")


let levelTags = Watched({})
let curLevel = Watched(null)
let curLevelTags = Computed(@() levelTags.get()?[curLevel.get()])

function updateTags() {
  if (!isInBattle.get()) {
    curLevel(null)
    return
  }
  let level = get_current_mission_info_cached()?.level
  curLevel(level)
  if (level == null || level in levelTags.get())
    return
  levelTags.mutate(function(v) {
    let levelBlk = blkFromPath($"{level.slice(0, -3)}blk")
    let sBlk = levelBlk?.technicsSkins
    v[level] <- !isDataBlock(sBlk) ? null
      : (sBlk % "groundSkin").reduce(@(res, tag) res.$rawset(tag, true), {})
  })
}

updateTags()
isInBattle.subscribe(@(_) updateTags())

return {
  curLevelTags
}