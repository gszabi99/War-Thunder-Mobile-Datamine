from "%globalScripts/logs.nut" import *
from "console" import register_command
from "math" import min, max
from "guiMission" import get_meta_mission_info_by_name
from "blkGetters" import get_unittags_blk, get_bots_blk
import "DataBlock" as DataBlock
from "%sqstd/datablock.nut" import blkOptFromPath, eachBlock, isDataBlock
from "%sqstd/functools.nut" import memoize
import "%appGlobals/getTagsUnitName.nut" as getTagsUnitName


let campaignToBotsPreset = {
  ships      = "allowedShips"
  ships_new  = "allowedShips"
  tanks      = "allowedTanks"
  tanks_new  = "allowedTanks"
  air        = "allowedAircrafts"
}

local allSupportsCache = null
function getAllSupports() {
  if (allSupportsCache == null) {
    allSupportsCache = {}
    let tagsBlk = get_unittags_blk()
    eachBlock(tagsBlk, function(blk) {
      let { supportPlane = "" } = blk?.Shop
      if (supportPlane in tagsBlk)
        allSupportsCache[blk.getBlockName()] <- supportPlane
    })
  }
  return allSupportsCache
}

function addSupportUnits(resTbl) {
  foreach(parent, support in getAllSupports()) {
    if (parent not in resTbl)
      continue
    if (support not in resTbl)
      resTbl[support] <- resTbl[parent]
    else if (type(resTbl[parent]) == "integer")
      resTbl[support] = min(resTbl[parent], resTbl[support])
  }
  return resTbl
}

local killStreakUnitsByRank = {} 
function getKillStreakUnitsByRank(preset = "") {
  if (preset in killStreakUnitsByRank)
    return killStreakUnitsByRank[preset]

  let res = []
  let gameplayBlk = DataBlock()
  gameplayBlk.tryLoad("config/gameplay.blk") 

  let unitsBlockId = gameplayBlk?[preset].units ?? "killStreaksUnits"
  let killStreaksUnits = gameplayBlk?[unitsBlockId]
  if (isDataBlock(killStreaksUnits)) {
    let tagsBlk = get_unittags_blk()
    eachBlock(killStreaksUnits, function(blk) {
      let { name = "", rankRange = null } = blk
      if (name not in tagsBlk || rankRange == null)
        return
      res.append({
        name
        tag = blk.getBlockName()
        rankFrom = rankRange.x
        rankTo = rankRange.y
      })
    })
  }

  killStreakUnitsByRank[preset] <- freeze(res)
  return killStreakUnitsByRank[preset]
}

function appendActionsUnits(resTbl, blk) {
  let { unit_class = "" } = blk?.actions.changeUnit
  if (unit_class != "")
    resTbl[unit_class] <- true
  let c = blk.blockCount()
  for (local i = 0; i < c; i++)
    appendActionsUnits(resTbl, blk.getBlock(i))
}

function appendOverrideUnits(resTbl, overrideUnit) {
  let ovrUnits = overrideUnit.split(";")
    .filter(@(v) v != "")
    .map(@(str) str.split(":")[0])
  foreach (u in ovrUnits)
    resTbl[getTagsUnitName(u)] <- true 
}

let getMissionUnitsAndAddons = memoize(function getMissionUnitsImpl(missionId) {
  let { mis_file = "" } = get_meta_mission_info_by_name(missionId)
  let misAddons = {}
  if (mis_file == "")
    return freeze({ misAddons, misUnits = {}, useKillStreaks = false })
  let misBlk = blkOptFromPath(mis_file)
  let resTbl = {}

  let unitsBlk = misBlk?.units
  if (unitsBlk)
    eachBlock(unitsBlk, function(blk) {
      if ((blk?.unit_class ?? "") != "")
        resTbl[blk.unit_class] <- true
    })

  let triggers = misBlk?.triggers
  if (triggers != null)
    appendActionsUnits(resTbl, triggers)

  appendOverrideUnits(resTbl, misBlk?.mission_settings.mission.overrideUnit ?? "")

  if ("dummy_plane" in resTbl)
    resTbl.$rawdelete("dummy_plane")

  let { level = "" } = misBlk?.mission_settings.mission
  if (level != "") {
    let levelStrip = level.split("/").top().split(".")[0]
    misAddons[$"pkg_level_{levelStrip}"] <- true
  }

  let tagsBlk = get_unittags_blk()
  return freeze({
    misAddons,
    misUnits = addSupportUnits(resTbl.filter(@(_, u) u in tagsBlk))
    useKillStreaks = misBlk?.mission_settings.mission.useKillStreaks ?? false
  })
})

function getKillStreakUnits(preset, mRankFrom, mRankTo) {
  let all = getKillStreakUnitsByRank(preset)
  let res = {}
  foreach (c in all)
    if (c.rankFrom <= mRankTo && c.rankTo >= mRankFrom)
      res[c.name] <- true
  return res
}

function getHighestRankRange(mode, mRankFrom, mRankTo) {
  let { mmRanges = [] } = mode?.matchmaking
  local from = mRankTo
  local to = mRankTo
  foreach (r in mmRanges) {
    if (r.len() < 2)
      continue
    if (mRankFrom >= r[0] && mRankFrom <= r[1])
      from = min(from, r[1])
    if (mRankTo >= r[0] && mRankTo <= r[1])
      to = max(to, r[1])
  }
  return { from, to }
}

function getMGameModeMissionUnitsAndAddons(mode, mRankFrom, mRankTo) {
  let resUnits = {}
  let resAddons = {}
  let { mission_decl = {}, soonMissionRanks = {} } = mode
  appendOverrideUnits(resUnits, mission_decl?.overrideUnit ?? "")

  local useKillStreaksMision = false
  foreach (mission, mCfg in mission_decl?.missions_list ?? {}) {
    let { minMRank = null, maxMRank = null } = mCfg?.enableIf
    if (mRankTo < (minMRank ?? mRankTo) || mRankFrom > (maxMRank ?? mRankFrom))
      continue
    let { misAddons, misUnits, useKillStreaks } = getMissionUnitsAndAddons(mission)
    useKillStreaksMision = useKillStreaksMision || useKillStreaks
    resUnits.__update(misUnits)
    resAddons.__update(misAddons)
  }

  foreach (mission, mRank in soonMissionRanks) {
    if (mRankTo < mRank)
      continue
    let { misAddons, misUnits, useKillStreaks } = getMissionUnitsAndAddons(mission)
    useKillStreaksMision = useKillStreaksMision || useKillStreaks
    resUnits.__update(misUnits)
    resAddons.__update(misAddons)
  }

  if (mission_decl?.useKillStreaks ?? useKillStreaksMision) {
    let { from, to } = getHighestRankRange(mode, mRankFrom, mRankTo)
    resUnits.__update(getKillStreakUnits(mission_decl?.nameKillStreaks ?? "", from, to))
  }

  let tagsBlk = get_unittags_blk()
  return {
    misUnits = addSupportUnits(resUnits.filter(@(_, u) u in tagsBlk))
    misAddons = resAddons
  }
}

function getAllBotsUnits(botsTbl) {
  let res = {}
  foreach (preset in botsTbl)
    foreach (unitsList in preset)
      foreach (u in unitsList)
        if ("name" in u)
          res[u.name] <- true
  return addSupportUnits(res)
}

function getCommonBots(campaign, rankMin, rankMax) {
  let botsPreset = get_bots_blk()?[campaignToBotsPreset?[campaign]]
  if (!isDataBlock(botsPreset))
    return {}

  let res = {}
  let found = {}
  for (local r = rankMin; r <= rankMax; r++)
    found[r] <- false
  let tagsBlk = get_unittags_blk()

  foreach (cfg in botsPreset % "rankRange") {
    let { x = null, y = null } = cfg?.range
    if (x == null || y == null || x > rankMax || y < rankMin)
      continue
    foreach (r, _ in found)
      if (x <= r && y >= r)
        found[r] = true
    eachBlock(cfg, function(blk) {
      if (blk?.name in tagsBlk)
        res[blk.name] <- true
    })
  }

  if (null == found.findindex(@(v) !v))
    return addSupportUnits(res)

  eachBlock(botsPreset, function(blk) {
    if (blk.getBlockName() == "rankRange")
      return
    if (blk?.name in tagsBlk)
      res[blk.name] <- true
  })
  return addSupportUnits(res)
}

function getBotUnits(mode, campaign, mRankMin, mRankMax) {
  let { customBots = null } = mode?.mission_decl.customRules
  if (customBots != null)
    return getAllBotsUnits(customBots)
  return getCommonBots(campaign, mRankMin, mRankMax)
}

register_command(@(id) log($"Mission {id}: ", getMissionUnitsAndAddons(id)), "debug.getMissionUnitsAndAddons")

return {
  getMissionUnitsAndAddons
  getMGameModeMissionUnitsAndAddons
  getBotUnits
  getCommonBots
  addSupportUnits
}