from "%globalsDarg/darg_library.nut" import *
require("%rGui/onlyAfterLogin.nut")
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { deferOnce } = require("dagor.workcycle")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDataBlock, blk2SquirrelObjNoArrays, eachBlock, eachParam  } = require("%sqstd/datablock.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { isSettingsAvailable, isLoggedIn } = require("%appGlobals/loginState.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { campConfigs, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { subscribeResetProfile } = require("%rGui/account/resetProfileDetector.nut")


let SEEN_MODS = "seenMods"
let SEEN_MODS_VERSION_KEY = "seenModsVersion"
let ACTUAL_VERSION = 3
let SEEN_MODS_VERSIONS = "seenModsVersions"
let seenVersions = {
  tanks_new = 2
}
let seenMods = mkWatched(persist, "SEEN_MODS", {})
let savedSeenVersions = mkWatched(persist, "savedSeenVersions", {})

function applyCompatibility() {
  let sBlk = get_local_custom_settings_blk()
  if ((sBlk?[SEEN_MODS_VERSION_KEY] ?? 0) == ACTUAL_VERSION)
    return

  sBlk[SEEN_MODS_VERSION_KEY] = ACTUAL_VERSION
  let toRemove = {}
  let toAdd = {}
  let blk = sBlk.addBlock(SEEN_MODS)
  eachBlock(blk, function(b) {
    let name = b.getBlockName()
    if (getTagsUnitName(name) == name)
      return
    toRemove[name] <- true
    let add = {}
    eachParam(b, @(v, k) add.$rawset(k, v))
    toAdd[getTagsUnitName(name)] <- add
  })
  foreach (u, _ in toRemove)
    blk.removeBlock(u)
  foreach (u, add in toAdd) {
    let b = blk.addBlock(u)
    foreach (k, v in add)
      b[k] <- v
  }
}

function loadSeenMods() {
  if (!isSettingsAvailable.get())
    return seenMods.set({})

  applyCompatibility()

  let sBlk = get_local_custom_settings_blk()
  let versionsBlk = sBlk?[SEEN_MODS_VERSIONS]
  savedSeenVersions.set(isDataBlock(versionsBlk) ? blk2SquirrelObjNoArrays(versionsBlk) : {})

  let htBlk = sBlk?[SEEN_MODS]
  seenMods.set(isDataBlock(htBlk) ? blk2SquirrelObjNoArrays(htBlk) : {})
}

if (seenMods.get().len() == 0 && savedSeenVersions.get().len() == 0)
  loadSeenMods()
isSettingsAvailable.subscribe(@(_) loadSeenMods())

let unseenCampUnitMods = Computed(function() {
  let { allUnits = {}, unitModPresets = {} } = campConfigs.get()
  let res = {}
  foreach (unitName, unit in campMyUnits.get()) {
    let preset = unitModPresets?[allUnits?[unitName].modPreset]
    if (preset == null)
      continue
    foreach (modName, mod in preset) {
      let { reqLevel = 0 } = mod
      if (reqLevel > 0
          && reqLevel <= unit.level
          && modName not in unit.mods
          && modName not in seenMods.get()?[getTagsUnitName(unitName)])
        getSubTable(res, unitName)[modName] <- true
    }
  }
  return res
})

function markUnitModsSeen(unitName, idsExt) {
  let unseen = unseenCampUnitMods.get()?[unitName]
  let ids = idsExt.filter(@(modName) modName in unseen)
  if (ids.len() == 0)
    return

  let tagName = getTagsUnitName(unitName)
  seenMods.mutate(function(v) {
    let unitSeen = getSubTable(v, tagName)
    foreach (id in ids)
      unitSeen[id] <- true
  })
  let blk = get_local_custom_settings_blk()
    .addBlock(SEEN_MODS)
    .addBlock(tagName)
  foreach (id in ids)
    blk[id] = true
  eventbus_send("saveProfile", {})
}

function markCurCampaignModsSeenAndClear() {
  let seenUpdate = {}
  let { allUnits = {}, unitModPresets = {} } = campConfigs.get()
  let sBlk = get_local_custom_settings_blk().addBlock(SEEN_MODS)
  foreach (unitName, unitCfg in allUnits) {
    let tagName = getTagsUnitName(unitName)
    let changes = getSubTable(seenUpdate, tagName)
    let unit = campMyUnits.get()?[unitName]
    let preset = unitModPresets?[unitCfg.modPreset]
    if (unit != null && preset != null)
      foreach (modName, mod in preset) {
        let { reqLevel = 0 } = mod
        if (reqLevel > 0
            && reqLevel <= unit.level
            && modName not in unit.mods)
          changes[modName] <- true
      }

    if (isDataBlock(sBlk?[tagName]))
      sBlk.removeBlock(tagName)

    if (changes.len() == 0)
      continue

    let blk = sBlk.addBlock(tagName)
    foreach(m, _ in changes)
      blk[m] = true
  }

  if (seenUpdate.len() == 0)
    return

  eventbus_send("saveProfile", {})
  seenMods.set(seenMods.get().__merge(seenUpdate).filter(@(u) u.len() > 0))
}

let isCurCampaignChangedVersion = keepref(Computed(@() isLoggedIn.get()
  && curCampaign.get() in seenVersions
  && (savedSeenVersions.get()?[curCampaign.get()] ?? 0) != seenVersions[curCampaign.get()]))

function onCurCampaignChangedVersion() {
  if (!isCurCampaignChangedVersion.get())
    return

  let version = seenVersions[curCampaign.get()]
  let vBlk = get_local_custom_settings_blk().addBlock(SEEN_MODS_VERSIONS)
  vBlk[curCampaign.get()] = version

  markCurCampaignModsSeenAndClear()
  savedSeenVersions.mutate(@(v) v.$rawset(curCampaign.get(), version))
}

isCurCampaignChangedVersion.subscribe(@(v) v ? deferOnce(onCurCampaignChangedVersion) : null)
if (isCurCampaignChangedVersion.get())
  deferOnce(onCurCampaignChangedVersion)

function resetAllSeen() {
  seenMods.set({})
  get_local_custom_settings_blk().removeBlock(SEEN_MODS)
  eventbus_send("saveProfile", {})
}

subscribeResetProfile(resetAllSeen)

register_command(resetAllSeen, "debug.reset_seen_mods")
register_command(markCurCampaignModsSeenAndClear, "debug.mark_all_current_campaign_mods_seen")

return {
  unseenCampUnitMods
  markUnitModsSeen
}
