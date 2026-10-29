from "%globalsDarg/darg_library.nut" import *
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/squadState.nut" import isSquadLeader, isInSquad, squadData, squadApplications, seenSquadApplications,
  squadLen, squadApplicationsInProgress, squadApplicationsRemote
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%rGui/clans/currentClanState.nut" import currentClanId, currentClan
from "%rGui/gameModes/gameModeState.nut" import maxSquadSizeByCampaign, maxSquadSize
from "%rGui/matching/matchingApi.nut" import matchingRequest, matchingRegisterHandler
from "%rGui/squad/squadManager.nut" import createSquad, acceptSquadMembership
from "%rGui/squad/squadSharedData.nut" import addToSquadData


const SQUAD_OPEN = "open"
const SQUAD_CLOSED = "closed"
const SQUAD_HIDDEN = "hidden"

let clanSquadsList = hardPersistWatched("clan.squadsList", [])
let isSquadListInProgress = mkWatched(persist, "clan.isSquadListInProgress", false)
let squadInProgress = mkWatched(persist, "clan.squadInProgress", false)
let isClanSquadLeader = Computed(@() isSquadLeader.get() && squadData.get()?.squadType != null)
let clanSquadFreeSlots = Computed(@()
  (maxSquadSizeByCampaign.get()?[squadData.get()?.campaign] ?? maxSquadSize.get())
    - squadLen.get()
    - squadApplicationsInProgress.get().reduce(@(res, v) v ? res + 1 : res, 0))
let isNeedAutoAcceptApplications = keepref(Computed(@() isSquadLeader.get() && squadData.get()?.squadType == SQUAD_OPEN
  && clanSquadFreeSlots.get() > 0))

currentClanId.subscribe(@(_) clanSquadsList.set([]))

function requestClanSquads() {
  let { users = [] } = currentClan.get()
  if (users.len() == 0 || isSquadListInProgress.get())
    return

  isSquadListInProgress.set(true)
  matchingRequest("msquad.get_squads",
    { players = users.map(@(u) u.userId) },
    { id = "onGetClanSquads", clanId = currentClanId.get() })
}

matchingRegisterHandler("onGetClanSquads", function(resp, context) {
  isSquadListInProgress.set(false)
  let { squads = [] } = resp
  if (context.clanId == currentClanId.get() && !isEqual(clanSquadsList.get(), squads))
    clanSquadsList.set(squads)
})

function createClanSquad(campaign, mRank, squadType) {
  if (squadInProgress.get())
    return
  squadInProgress.set(true)
  createSquad({ id = "onClanSquadCreate", campaign, mRank, squadType })
}

matchingRegisterHandler("onClanSquadCreate", function(result, context) {
  squadInProgress.set(false)
  if ("error" in result)
    return
  let { campaign, mRank, squadType } = context
  addToSquadData({ campaign, mRank, squadType })
})

function updateClanSquad(campaign, mRank, squadType) {
  if (isSquadLeader.get()) {
    addToSquadData({ campaign, mRank, squadType })
    return true
  }

  if (!isInSquad.get())
    createClanSquad(campaign, mRank, squadType)
  else
    openFMsgBox({
      text = loc("clan/squad/ask/leaveToCreate")
      buttons = [
        { id = "cancel", isCancel = true }
        { id = "leaveSquad", isDefault = true, eventId = "leaveSquad",
          context = { cb = { id = "createClanSquad", campaign, mRank, squadType } }
        }
      ]
    })
  return false
}

function updateClanSquadField(key, value) {
  if (isClanSquadLeader.get() && squadData.get()?[key] != value)
    addToSquadData({ [key] = value })
}

function handleAutoAccept() {
  if (!isNeedAutoAcceptApplications.get())
    return
  local places = clanSquadFreeSlots.get()
  foreach (userId in squadApplications.get())
    if (places <= 0)
      return
    else {
      acceptSquadMembership(userId)
      places--
    }
}

handleAutoAccept()
isNeedAutoAcceptApplications.subscribe(@(_) handleAutoAccept())
squadApplicationsRemote.subscribe(@(_) handleAutoAccept())


function updateSeenApplications() {
  let wasSeen = seenSquadApplications.get()
  let curSeen = squadApplicationsRemote.get().reduce(@(res, id) id in wasSeen ? res.$rawset(id, true) : res, {})
  if (curSeen.len() != wasSeen.len())
    seenSquadApplications.set(curSeen)
}
updateSeenApplications()
squadApplicationsRemote.subscribe(@(_) updateSeenApplications())

function markSquadApplicationSeen(id) {
  if (id not in seenSquadApplications.get() && squadApplications.get().contains(id))
    seenSquadApplications.mutate(@(v) v.$rawset(id, true))
}

function markAllSquadApplicationsSeen() {
  let curSeen = squadApplications.get().reduce(@(res, id) res.$rawset(id, true), {})
  if (!isEqual(curSeen, seenSquadApplications.get()))
    seenSquadApplications.set(curSeen)
}

matchingRegisterHandler("createClanSquad", function(result, context) {
  if ("error" not in result)
    createClanSquad(context.campaign, context.mRank, context.squadType)
})

return {
  requestClanSquads
  clanSquadsList
  updateClanSquad
  updateClanSquadField

  squadInProgress
  isClanSquadLeader
  clanSquadFreeSlots

  SQUAD_OPEN
  SQUAD_CLOSED
  SQUAD_HIDDEN

  markSquadApplicationSeen
  markAllSquadApplicationsSeen
}