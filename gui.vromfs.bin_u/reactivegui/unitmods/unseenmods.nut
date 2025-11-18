from "%globalsDarg/darg_library.nut" import *
require("%rGui/onlyAfterLogin.nut")
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { deferOnce } = require("dagor.workcycle")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDataBlock, blk2SquirrelObjNoArrays } = require("%sqstd/datablock.nut")
let { isSettingsAvailable, isLoggedIn } = require("%appGlobals/loginState.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { campConfigs, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { subscribeResetProfile } = require("%rGui/account/resetProfileDetector.nut")


let SEEN_MODS = "seenMods"
let SEEN_MODS_VERSIONS = "seenModsVersions"
let seenVersions = {
  tanks_new = 2
}
let seenMods = mkWatched(persist, "SEEN_MODS", {})
let savedSeenVersions = mkWatched(persist, "savedSeenVersions", {})


function loadSeenMods() {
  if (!isSettingsAvailable.get())
    return seenMods.set({})
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
      if (modName not in seenMods.get()?[unitName]
          && reqLevel > 0
          && reqLevel <= unit.level
          && modName not in unit.mods)
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

  seenMods.mutate(function(v) {
    let unitSeen = getSubTable(v, unitName)
    foreach (id in ids)
      unitSeen[id] <- true
  })
  let blk = get_local_custom_settings_blk()
    .addBlock(SEEN_MODS)
    .addBlock(unitName)
  foreach (id in ids)
    blk[id] = true
  eventbus_send("saveProfile", {})
}

function markCurCampaignModsSeenAndClear() {
  let seenUpdate = {}
  let { allUnits = {}, unitModPresets = {} } = campConfigs.get()
  let sBlk = get_local_custom_settings_blk().addBlock(SEEN_MODS)
  foreach (unitName, unitCfg in allUnits) {
    let changes = getSubTable(seenUpdate, unitName)
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

    if (isDataBlock(sBlk?[unitName]))
      sBlk.removeBlock(unitName)

    if (changes.len() == 0)
      continue

    let blk = sBlk.addBlock(unitName)
    foreach(m, _ in changes)
      blk[m] = true
  }

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
