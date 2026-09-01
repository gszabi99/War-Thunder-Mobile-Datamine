from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_unittags_blk
from "console" import register_command
from "%sqstd/datablock.nut" import eachBlock
from "%appGlobals/clientState/clientState.nut" import canBattleWithoutAddons
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/unit/hangarUnit.nut" import hangarUnitName
from "%rGui/unit/unitSettings.nut" import resetUnitSettings





register_command(@() hangarUnitName.get() == null ? null : resetUnitSettings(hangarUnitName.get()), "ui.reset_hangar_unit_settings")
register_command(function() {
    canBattleWithoutAddons.set(!canBattleWithoutAddons.get())
    console_print(canBattleWithoutAddons.get() ? "Allowed" : "Disable") 
  },
  "ui.allow_battle_no_addons")

register_command(function() {
  let { allUnits = {} } = serverConfigs.get()
  let tagsBlk = get_unittags_blk()
  let list = []
  eachBlock(tagsBlk, function(blk) {
    let name = blk.getBlockName()
    if ("mRank" not in blk && name not in allUnits && $"{name}_nc" not in allUnits)
      list.append(name)
  })
  list.sort()
  log("unit errors: ", list.len())
  const step = 10
  for (local i = 0; i < list.len(); i += step)
    log(list.slice(i, i + 10))
}, "debug.get_units_without_mrank")