from "%globalsDarg/darg_library.nut" import *
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/squadState.nut" import isSquadLeader, isInSquad, squadData, squadApplications, seenSquadApplications
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%rGui/clans/currentClanState.nut" import currentClanId, currentClan
from "%rGui/matching/matchingApi.nut" import matchingRequest, matchingRegisterHandler
from "%rGui/squad/squadManager.nut" import createSquad, acceptSquadMembership
from "%rGui/squad/squadSharedData.nut" import addToSquadData


const SQUAD_OPEN = "open"
const SQUAD_CLOSED = "closed"

let clanSquadsList = hardPersistWatched("clan.squadsList", [])
let isSquadListInProgress = mkWatched(persist, "clan.isSquadListInProgress", false)
let squadInProgress = mkWatched(persist, "clan.squadInProgress", false)
let isClanSquadLeader = Computed(@() isSquadLeader.get() && squadData.get()?.squadType != null)
let isNeedAutoAcceptApplications = keepref(Computed(@() isSquadLeader.get() && squadData.get()?.squadType == SQUAD_OPEN))

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
  foreach (userId in squadApplications.get())
    acceptSquadMembership(userId)
}

handleAutoAccept()
isNeedAutoAcceptApplications.subscribe(@(_) handleAutoAccept())
squadApplications.subscribe(@(_) handleAutoAccept())


function updateSeenApplications() {
  let wasSeen = seenSquadApplications.get()
  let curSeen = squadApplications.get().reduce(@(res, id) id in wasSeen ? res.$rawset(id, true) : res, {})
  if (curSeen.len() != wasSeen.len())
    seenSquadApplications.set(curSeen)
}
updateSeenApplications()
squadApplications.subscribe(@(_) updateSeenApplications())

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

  SQUAD_OPEN
  SQUAD_CLOSED

  markSquadApplicationSeen
  markAllSquadApplicationsSeen
}