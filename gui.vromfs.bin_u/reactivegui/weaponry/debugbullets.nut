from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { get_unittags_blk } = require("blkGetters")
let { json_to_string } = require("json")
let io = require("io")
let { eachBlock } = require("%sqstd/datablock.nut")
let { calcUnitTypeFromTags } = require("%appGlobals/unitConst.nut")
let { loadUnitBulletsFull, loadUnitBulletsChoice } = require("%rGui/weaponry/loadUnitBullets.nut")

register_command(@(unitName) log($"Unit {unitName} full all bullets: ", loadUnitBulletsFull(unitName)),
  "debug.get_unit_bullets_full_all")
register_command(@(unitName) log($"Unit {unitName} full common bullets: ", loadUnitBulletsFull(unitName)?.commonWeapons),
  "debug.get_unit_bullets_full_common")
register_command(@(unitName) log($"Unit {unitName} full common bullets: ", loadUnitBulletsFull(unitName)?.commonWeapons.primary),
  "debug.get_unit_bullets_full_common_primary")
register_command(@(unitName) log($"Unit {unitName} choice all bullets: ", loadUnitBulletsChoice(unitName)),
  "debug.get_unit_bullets_choice_all")
register_command(@(unitName) log($"Unit {unitName} choice common bullets: ", loadUnitBulletsChoice(unitName)?.commonWeapons),
  "debug.get_unit_bullets_choice_common")
register_command(@(unitName) log($"Unit {unitName} choice common bullets: ", loadUnitBulletsChoice(unitName)?.commonWeapons.primary),
  "debug.get_unit_bullets_choice_common_primary")
register_command(@(unitName) log($"Unit {unitName} choice common primary bulletsSets: ", loadUnitBulletsChoice(unitName)?.commonWeapons.primary.bulletSets),
  "debug.get_unit_bullets_choice_common_primary_bulletSets")

function printAllBulletNames() {
  let res = {}
  let tagsBlk = get_unittags_blk()
  eachBlock(tagsBlk, function(blk) {
    let name = blk.getBlockName()
    foreach(trigger in loadUnitBulletsFull(name))
      foreach(wType in trigger)
        foreach(set in wType.bulletSets)
          foreach(bName in set.bulletNames)
            res[bName] <- true
  })
  log("total = ", res.len())
  log(res.keys().sort())
}
register_command(printAllBulletNames, "debug.print_all_bullet_names")


function countBulletsStats(loadBullets) {
  let tagsBlk = get_unittags_blk()
  let bullets = {}
  let beltBullets = {}
  eachBlock(tagsBlk, function(blk) {
    let name = blk.getBlockName()
    let full = loadBullets(name)
    let unitBullets = {}
    let unitBeltBullets = {}
    foreach (preset in full)
      foreach (trigger in preset)
        foreach (set in trigger.bulletSets)
          foreach (bul in set.bullets)
             if (set.isBulletBelt)
               unitBeltBullets[bul] <- true
             else
               unitBullets[bul] <- true
    foreach (key, _ in unitBullets)
      bullets[key] <- (bullets?[key] ?? 0) + 1
    foreach (key, _ in unitBeltBullets)
      beltBullets[key] <- (beltBullets?[key] ?? 0) + 1
  })
  log("Unit count which uses bullets: ", { bullets, beltBullets })
}

register_command(
  @() countBulletsStats(loadUnitBulletsFull)
  "debug.get_unit_bullets_stats_all")
register_command(
  @() countBulletsStats(loadUnitBulletsChoice)
  "debug.get_unit_bullets_stats_choice")

register_command(
  function(filePath) {
    let res = {}
    eachBlock(get_unittags_blk(), function(blk) {
      let name = blk.getBlockName()
      res[name] <- loadUnitBulletsFull(name)
    })
    let file = io.file(filePath, "wt+")
    file.writestring(json_to_string(res, true))
    file.close()
  },
  "debug.save_all_unit_bullets_to_file")

register_command(
  function(filePrefix) {
    let res = {}
    eachBlock(get_unittags_blk(), function(blk) {
      let unitType = calcUnitTypeFromTags(blk)
      if (unitType not in res)
        res[unitType] <- {}
      let name = blk.getBlockName()
      res[unitType][name] <- loadUnitBulletsFull(name)
    })
    foreach(unitType, data in res) {
      let filePath = $"{filePrefix}{unitType}.json"
      let file = io.file(filePath, "wt+")
      file.writestring(json_to_string(data, true))
      file.close()
      log($"Saved file {filePath}")
    }
  },
  "debug.save_all_unit_bullets_to_files_by_type")