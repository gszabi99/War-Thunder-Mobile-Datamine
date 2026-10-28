from "%globalsDarg/darg_library.nut" import *
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import prevIfEqual
from "%appGlobals/config/clanPresentation.nut" import mkClanBadge
from "%appGlobals/permissions.nut" import allow_clans
from "%rGui/contacts/contactPublicInfo.nut" import allPublicInfo, subscribePublicInfoUpdate


const MIN_CLEANUP_LEN = 100

let userClanIds = hardPersistWatched("clanPublicInfo.userClanIds", {})
let clansInfo = hardPersistWatched("clanPublicInfo.clansInfo", {})
let userClanWeakRefs = {}
local cleanupLen = MIN_CLEANUP_LEN

let mkClanInfo = @(textFields) { name = textFields?.name ?? "", badge = mkClanBadge(textFields) }

function updateClans(clanIdsUpd, textFieldsUpd) {
  let idsUpd = clanIdsUpd.filter(@(clanId, uid) userClanIds.get()?[uid] != clanId)
  let clansUpd = {}
  foreach (clanId, textFields in textFieldsUpd) {
    let prevInfo = clansInfo.get()?[clanId]
    let clanInfo = prevIfEqual(prevInfo, mkClanInfo(textFields))
    if (clanInfo != prevInfo)
      clansUpd[clanId] <- clanInfo
  }
  if (idsUpd.len() > 0)
    userClanIds.mutate(function(v) {
      foreach (uid, clanId in idsUpd)
        if (clanId == null)
          v.$rawdelete(uid)
        else
          v[uid] <- clanId
    })
  if (clansUpd.len() > 0)
    clansInfo.mutate(function(v) {
      foreach (clanId, clanInfo in clansUpd)
        v[clanId] <- clanInfo
    })
}

function onPublicInfoUpdate(upd) {
  let clanIdsUpd = {}
  let textFieldsUpd = {}
  foreach (uid, info in upd) {
    let clan = info?.clan
    if (clan == null)
      continue
    let clanId = clan?.clanId
    clanIdsUpd[uid] <- clanId
    let textFields = clan?.textFields
    if (clanId != null && textFields != null)
      textFieldsUpd[clanId] <- textFields
  }
  updateClans(clanIdsUpd, textFieldsUpd)
}

function updateClanPublicInfo(clan) {
  let { clanId, textFields = null, users = [] } = clan
  let clanIdsUpd = {}
  foreach (user in users)
    clanIdsUpd[user.userId.tostring()] <- clanId
  updateClans(clanIdsUpd, textFields == null ? {} : { [clanId] = textFields })
}

let removeUserClan = @(userId) updateClans({ [userId.tostring()] = null }, {})

if (userClanIds.get().len() == 0)
  onPublicInfoUpdate(allPublicInfo.get())
subscribePublicInfoUpdate(onPublicInfoUpdate)

let mkUserClan = @(uid) Computed(function() {
  if (!allow_clans.get())
    return null
  let clanId = userClanIds.get()?[uid]
  return clanId == null ? null : clansInfo.get()?[clanId]
})

function cleanupUserClans() {
  foreach (uid in userClanWeakRefs.keys())
    if (userClanWeakRefs[uid] == null)
      userClanWeakRefs.$rawdelete(uid)
  cleanupLen = max(MIN_CLEANUP_LEN, 2 * userClanWeakRefs.len())
}

function getUserClan(userId) {
  let uid = userId.tostring()
  local userClan = userClanWeakRefs?[uid]
  if (userClan == null) {
    if (userClanWeakRefs.len() >= cleanupLen)
      cleanupUserClans()
    userClan = mkUserClan(uid)
    userClanWeakRefs[uid] <- userClan.weakref()
  }
  return userClan
}

return {
  getUserClan
  updateClanPublicInfo
  removeUserClan
}
