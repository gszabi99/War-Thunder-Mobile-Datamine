from "%globalsDarg/darg_library.nut" import *
let { blkOptFromPath } = require("%sqstd/datablock.nut")

function collectArmorClassToSteelMuls(showStellEquivForArmorClassesList) {
  let res = {}
  let armorClassesBlk = blkOptFromPath("gameData/damage_model/armor_classes.blk")
  let steelArmorQuality = armorClassesBlk?.ship_structural_steel.armorQuality ?? 0
  if (steelArmorQuality == 0)
    return res
  foreach (armorClass in showStellEquivForArmorClassesList)
    res[armorClass] <- (armorClassesBlk?[armorClass].armorQuality ?? 0) / steelArmorQuality
  return res
}

return {
  collectArmorClassToSteelMuls
}
