from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { deferOnce } = require("dagor.workcycle")
let { blk2SquirrelObjNoArrays, isDataBlock } = require("%sqstd/datablock.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let SEEN_SKINS = "seenSkins"
let SEEN_SKINS_VERSIONS = "seenSkinsVersions"
let seenVersions = {
  tanks_new = 1
}

let seenSkins = mkWatched(persist, "seenSkins", {})
let savedSeenVersions = mkWatched(persist, "savedSeenVersions", {})
let mySkins = Computed(@() servProfile.get()?.skins ?? {})


let mySkinsToMark = Computed(function() {
  let res = {}
  let allMySkins = mySkins.get()
  if (allMySkins.len() == 0)
    return res
  foreach(name, unit in campMyUnits.get()) {
    let { skins = null } = unit
    let resSkins = allMySkins?[name].filter(@(_, s) s in skins && !skins[s] && s != "upgraded")
    if (resSkins != null && resSkins.len() != 0)
      res[name] <- resSkins
  }
  return res
})

let unseenSkins = Computed(function() {
  let seen = seenSkins.get()
  return mySkinsToMark.get()
    .map(@(list, unitName) list.filter(@(_, skinName) skinName not in seen?[unitName]))
    .filter(@(v) v.len() != 0)
})

function loadSeenSkins() {
  if (!isLoggedIn.get())
    return
  let sBlk = get_local_custom_settings_blk()
  let seenBlk = sBlk?[SEEN_SKINS]
  seenSkins.set(isDataBlock(seenBlk) ? blk2SquirrelObjNoArrays(seenBlk) : {})
  let versionsBlk = sBlk?[SEEN_SKINS_VERSIONS]
  savedSeenVersions.set(isDataBlock(versionsBlk) ? blk2SquirrelObjNoArrays(versionsBlk) : {})
}

isLoggedIn.subscribe(@(_) loadSeenSkins())
if (seenSkins.get().len() == 0 && savedSeenVersions.get().len() == 0)
  loadSeenSkins()

function markSkinsSeen(unitName, skinsList) {
  let unitUnseen = unseenSkins.get()?[unitName]
  let skins = skinsList.filter(@(s) s in unitUnseen)
  if (skins.len() == 0)
    return

  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk.addBlock(SEEN_SKINS).addBlock(unitName)
  foreach(s in skins)
    blk[s] = true
  eventbus_send("saveProfile", {})

  seenSkins.mutate(function(v) {
    v[unitName] <- (v?[unitName] ?? {}).__merge(skins.reduce(@(res, s) res.$rawset(s, true), {}))
  })
}

let markAllUnitSkinsSeen = @(unitName) unitName not in unseenSkins.get() ? null
  : markSkinsSeen(unitName, unseenSkins.get()[unitName].keys())

let markSkinSeen = @(unitName, skin) markSkinsSeen(unitName, [skin])

function markCurCampaignSkinsSeen() {
  let seenUpdate = {}
  let sBlk = get_local_custom_settings_blk().addBlock(SEEN_SKINS)
  foreach (unitName, list in unseenSkins.get()) {
    let blk = sBlk.addBlock(unitName)
    seenUpdate[unitName] <- clone seenSkins.get()?[unitName] ?? {}
    foreach(s, _ in list) {
      blk[s] = true
      seenUpdate[unitName][s] <- true
    }
  }

  if (seenUpdate.len() == 0)
    return false

  eventbus_send("saveProfile", {})
  seenSkins.set(seenSkins.get().__merge(seenUpdate))
  return true
}

let isCurCampaignChangedVersion = keepref(Computed(@() isLoggedIn.get()
  && curCampaign.get() in seenVersions
  && (savedSeenVersions.get()?[curCampaign.get()] ?? 0) != seenVersions[curCampaign.get()]))

function onCurCampaignChangedVersion() {
  if (!isCurCampaignChangedVersion.get())
    return

  let version = seenVersions[curCampaign.get()]
  let vBlk = get_local_custom_settings_blk().addBlock(SEEN_SKINS_VERSIONS)
  vBlk[curCampaign.get()] = version

  if (!markCurCampaignSkinsSeen())
    eventbus_send("saveProfile", {})

  savedSeenVersions.mutate(@(v) v.$rawset(curCampaign.get(), version))
}

isCurCampaignChangedVersion.subscribe(@(v) v ? deferOnce(onCurCampaignChangedVersion) : null)
if (isCurCampaignChangedVersion.get())
  deferOnce(onCurCampaignChangedVersion)

register_command(function() {
  get_local_custom_settings_blk().removeBlock(SEEN_SKINS)
  eventbus_send("saveProfile", {})
  loadSeenSkins()
}, "debug.reset_seen_skins")

register_command(markCurCampaignSkinsSeen, "debug.mark_all_current_campaign_skins_seen")

return {
  unseenSkins
  markAllUnitSkinsSeen
  markSkinSeen
}