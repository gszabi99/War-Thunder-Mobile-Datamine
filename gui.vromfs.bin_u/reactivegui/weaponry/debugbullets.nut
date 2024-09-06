from "%globalsDarg/darg_library.nut" import *
let { Point2 } = require("dagor.math")
let { register_command, command } = require("console")
let { get_unittags_blk } = require("blkGetters")
let { object_to_json_string } = require("json")
let io = require("io")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { eachBlock } = require("%sqstd/datablock.nut")
let { calcUnitTypeFromTags } = require("%appGlobals/unitConst.nut")
let { loadUnitBulletsFull, loadUnitBulletsChoice, loadUnitBulletsAndSlots, loadUnitWeaponSlots
} = require("%rGui/weaponry/loadUnitBullets.nut")
let { getBulletBeltImageId } = require("%appGlobals/config/bulletsPresentation.nut")

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
register_command(function(unitName) {
    log($"Unit {unitName} weapon slots: ")
    debugTableData(loadUnitWeaponSlots(unitName), { recursionLevel = 5 })
  },
  "debug.get_unit_weapon_slots")
register_command(function(unitName, slotIndex) {
    log($"Unit {unitName} weapon slots: ")
    debugTableData(loadUnitWeaponSlots(unitName).findvalue(@(s) s.index == slotIndex),
      { recursionLevel = 5 })
  },
  "debug.get_unit_weapon_slot")

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

let prepareInstance = {
  [Point2] = @(v) { x = v.x, y = v.y },
}

function prepareDataForJson(data) {
  let dataType = type(data)
  if (dataType == "instance")
    return prepareInstance?[data.getclass()](data) ?? data
  if (dataType == "array" || dataType == "table") {
    local isChanged = false
    let prepare = prepareDataForJson
    local res = data.map(function(v) {
      let newV = prepare(v)
      isChanged = isChanged || newV != v
      return newV
    })
    return isChanged ? res : data
  }
  return data
}

local loadAllBulletsProgress = null
let onLoadAllBullets = []

function onFinishLoad() {
  let actions = clone onLoadAllBullets
  onLoadAllBullets.clear()
  if (loadAllBulletsProgress == null)
    return
  let { res } = loadAllBulletsProgress
  loadAllBulletsProgress = null
  foreach(action in actions)
    action(res)
}

function loadNextBullets() {
  if (loadAllBulletsProgress == null) {
    clearTimer(loadNextBullets)
    onFinishLoad()
    return
  }
  let time = get_time_msec()
  let { res, todo } = loadAllBulletsProgress
  while(todo.len() > 0) {
    let name = todo.pop()
    command($"console.progress_indicator loadAllBullets {res.len()}/{res.len() + todo.len()}")
    res[name] <- loadUnitBulletsAndSlots(name)
    if (get_time_msec() - time >= 10)
      return
  }
  command($"console.progress_indicator loadAllBullets")
  clearTimer(loadNextBullets)
  onFinishLoad()
}

function loadAllBulletsAndDo(action) {
  onLoadAllBullets.append(action)
  if (loadAllBulletsProgress != null)
    return
  loadAllBulletsProgress = { res = {}, todo = [] }
  eachBlock(get_unittags_blk(), @(blk) loadAllBulletsProgress.todo.append(blk.getBlockName()))
  setInterval(0.001, loadNextBullets)
}

register_command(
  @(filePath) loadAllBulletsAndDo(function(res) {
    let file = io.file(filePath, "wt+")
    file.writestring(object_to_json_string(prepareDataForJson(res), true))
    file.close()
  }),
  "debug.save_all_unit_bullets_to_file")

register_command(
  @(filePrefix) loadAllBulletsAndDo(function(res) {
    let resByType = {}
    let blk = get_unittags_blk()
    foreach(name, b in res) {
      let unitType = calcUnitTypeFromTags(blk?[name])
      if (unitType not in resByType)
        resByType[unitType] <- {}
      resByType[unitType][name] <- b
    }
    foreach(unitType, data in resByType) {
      let filePath = $"{filePrefix}{unitType}.json"
      let file = io.file(filePath, "wt+")
      file.writestring(object_to_json_string(prepareDataForJson(data), true))
      file.close()
      log($"Saved file {filePath}")
    }
  }),
  "debug.save_all_unit_bullets_to_files_by_type")

register_command(
  @() loadAllBulletsAndDo(function(res) {
    let resByCount = []
    let bigBeltsUnits = {}
    foreach(name, b in res) {
      let { slots = [] } = b
      if (slots.len() == 0)
        continue
      foreach(slot in slots)
        foreach(preset in slot.wPresets)
          foreach(weapon in preset.weapons)
            foreach(set in weapon.bulletSets) {
              if (!set.isBulletBelt)
                continue
              let count = set.bullets.len()
              if (count not in resByCount)
                resByCount.resize(count + 1, null)
              let icons = set.bullets.map(getBulletBeltImageId)
              let iconsStr = ";".join(icons)
              resByCount[count] = (resByCount[count] ?? {}).__update({ [iconsStr] = true }) //warning disable: -unwanted-modification
              if (count < 6)
                continue
              bigBeltsUnits[name] <- (bigBeltsUnits?[name] ?? {}).__update({ [iconsStr] = true }) //warning disable: -unwanted-modification
            }
    }

    let texts = ["Big belts units: "]
    foreach(name, list in bigBeltsUnits) {
      texts.append($"Unit {name}:")
      foreach(icons, _ in list)
        texts.append($"  {icons}")
    }

    texts.append("\nAll bullet icons for slots:")
    foreach(idx, list in resByCount) {
      if (list == null)
        continue
      texts.append($"Sets of {idx}:")
      foreach(s in list.keys().sort())
        texts.append(s)
    }
    let text = "\n".join(texts)
    log(text)
    console_print(text) //warning disable: -forbidden-function
  }),
  "debug.print_all_bullet_sets_icons_for_slots")

register_command(
  @() loadAllBulletsAndDo(function(res) {
    let resUnits = {}
    foreach(name, b in res) {
      let { slots = [] } = b
      if (slots.len() == 0)
        continue
      foreach(idx, slot in slots)
        if (idx != 0)
          foreach(preset in slot.wPresets) {
            let wList = {}
            foreach(weapon in preset.weapons)
              wList[weapon.weaponId] <- true
            if (wList.len() <= 1)
              continue
            if (name not in resUnits)
              resUnits[name] <- {}
            resUnits[name][idx] <- wList.keys()
          }
    }

    log(resUnits)
    console_print(resUnits) //warning disable: -forbidden-function
  }),
  "debug.find_double_weapon_secondary_slots")
