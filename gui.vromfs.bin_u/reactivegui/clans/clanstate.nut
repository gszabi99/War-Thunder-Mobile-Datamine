from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "console" import register_command
from "eventbus" import eventbus_send
from "json" import object_to_json_string
from "hash" import crc32
import "utf8" as utf8
from "string" import format
from "%sqstd/string.nut" import hexStringToInt
from "%sqstd/functools.nut" import memoize
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/time.nut" import TIME_DAY_IN_SECONDS
from "%appGlobals/clientState/initialState.nut" import projectId
from "%appGlobals/dirtyWordsFilter.nut" import isNamePassing, clearExcessiveWhitespace
from "%appGlobals/loginState.nut" import isOnlineSettingsAvailable
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%appGlobals/pServer/bqClient.nut" import sendErrorLocIdBqEvent
from "%appGlobals/pServer/campaign.nut" import bestCampLevel
from "%appGlobals/pServer/clanServConfigs.nut" import clanServerConfigs
from "%appGlobals/pServer/pServerApi.nut" import clan_lookup, clan_create, clan_update, send_join_request,
  clansInProgress, registerHandler, localizePServerError, get_clan_info, clanInfoInProgress, clan_leave, clan_remove,
  clan_change_grade, clan_kick_user, clanChangeMemberInProgress, callHandler, clansLookupInProgress, clan_transfer_ownership
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/permissions.nut" import allow_clans
from "%appGlobals/profileStates.nut" import myUserId
from "%appGlobals/timeoutExt.nut" import resetExtTimeout, clearExtTimer
from "%appGlobals/userstats/serverTime.nut" import getServerTime, isServerTimeValid
from "%appGlobals/clanConsts.nut" import GRADE_LEADER, GRADE_FOUNDER
from "%rGui/account/resetProfileDetector.nut" import subscribeResetProfile
from "%rGui/clans/clanCfg.nut" import LANGUAGE, MEMBERS, LOCATION, TYPE, AVAILABILITY
from "%rGui/clans/clanPermissions.nut" import CLAN_KICK_MEMBER, CLAN_CHANGE_GRADE, hasClanPermission
from "%rGui/clans/clanPublicInfo.nut" import updateClanPublicInfo
from "%rGui/clans/currentClanState.nut" import forceRefreshCurrentClan, resetCurrentClanInfo, currentClan, currentClanId,
  NO_CLAN_ID, shouldUpdateUserRequests
from "%rGui/clans/filterClanState.nut" import clanFilterComp, resetFilter


const CLAN_SEARCH_ID = "clan_lookup"
const CLAN_CREATE_ID = "clan_create"
const CLAN_UPDATE_ID = "clan_update"
const CLAN_SEND_JOIN_REQUEST = "clan_send_join_request"
const IS_CLAN_FIRST_TIME_OPENED = "is_clan_first_time_opened"

const MAX_CLAN_CACHE_SIZE = 10
const CLAN_CACHE_TTL = 60

const maxResult = 50
const defClanMinLvl = 5

let foundedClans = Watched([])
let searchClanName = Watched("")
let searchClanNameCleared = Computed(@() clearExcessiveWhitespace(searchClanName.get()))
let isClanSearchOpen = Watched(false)
let isClanFiltersOpen = Watched(false)
let isClanEditorOpen = Watched(false)
let isClanInfoOpen = Watched(false)
let curViewedClanId = Watched(null)
let onKickActions = []
let clanMinCampaignLevel = Computed(@() serverConfigs.get()?.gameProfile.clanMinCampaignLevel ?? defClanMinLvl)
let hasRequiredLvl = Computed(@() clanMinCampaignLevel.get() <= bestCampLevel.get())
let isClanBtnClicked = Watched(false)
let isFounderKickable = Watched(false)

function loadIsClanBtnClicked() {
  if (!isOnlineSettingsAvailable.get()) {
    isClanBtnClicked.set(false)
    return
  }
  isClanBtnClicked.set(get_local_custom_settings_blk()?[IS_CLAN_FIRST_TIME_OPENED] ?? false)
}

loadIsClanBtnClicked()
isOnlineSettingsAvailable.subscribe(@(_) loadIsClanBtnClicked())

function setClanBtnClicked(isClicked = true) {
  if (isClanBtnClicked.get() == isClicked)
    return

  isClanBtnClicked.set(isClicked)
  get_local_custom_settings_blk()[IS_CLAN_FIRST_TIME_OPENED] = isClicked
  eventbus_send("saveProfile", {})
}

let isClanCreateOpen = hardPersistWatched("isClanCreateOpen", false)
let clanInfoCache = hardPersistWatched("clanInfoCache", {})

let errorsToShow = ["USER_ALREADY_HAVE_CLAN", "FIELD_REQUIRED", "CLAN_IS_FULL", "CLAN_IS_DELETED",
  "CLAN_LEVEL_REQUIRED", "KICK_INACTIVE_DAYS_NOT_REACHED"].totable()
let allowedValidationFields = ["name", "description", "message"].totable()

function shouldShowErrorToPlayer(err) {
  let { message = null, data = null } = err
  if (message == "VALIDATOR_SERVER_REJECT_VALUE")
    return data == null || data?.extra.field in allowedValidationFields
  return message in errorsToShow
}

function getClanLookupFilters() {
  let filter = clanFilterComp.get()
  let textFields = {}

  if (searchClanNameCleared.get().len() > 0)
    textFields.name <- searchClanNameCleared.get()
  if (filter[LANGUAGE])
    textFields[LANGUAGE] <- filter[LANGUAGE]
  if (filter[LOCATION])
    textFields[LOCATION] <- filter[LOCATION]
  let res = { textFields, minMembers = filter[MEMBERS] }

  if (filter[AVAILABILITY])
    res.members <- filter[AVAILABILITY]
  if (filter[TYPE])
    res.privacy <- filter[TYPE]

  return res
}

function refreshClanInfo() {
  let clanId = curViewedClanId.get()
  if (clanId)
    get_clan_info(clanId, { id = "on_viewed_clan_info", clanId })
}

function handleClanError(res) {
  if (res?.error == null || res?.error == "")
    return false

  let { bqLocId, text } = localizePServerError(res.error)
  let shownText = res.error?.message != "CLAN_LEVEL_REQUIRED" ? text
    : loc("error/CLAN_LEVEL_REQUIRED", { level = clanMinCampaignLevel.get() })

  if (shouldShowErrorToPlayer(res.error)) {
    openFMsgBox({ text = shownText })
    sendErrorLocIdBqEvent(bqLocId)
    refreshClanInfo()
  } else
    logerr($"CLAN ERROR: errorId: {bqLocId}, data: {object_to_json_string(res?.error.data.extra)}")

  return true
}

let founderKickTime = Computed(function() {
  let inactiveDays = clanServerConfigs.get()?.founderKickAfterInactiveDays ?? 0
  let founder = currentClan.get()?.users.findvalue(@(u) u.gradeStr == GRADE_FOUNDER)
  if (inactiveDays <= 0 || founder == null)
    return null
  let { joinedTimestamp = 0, loginTimestamp = 0, gradeReceivedTimestamp = 0 } = founder
  let lastSeen = loginTimestamp != 0 ? loginTimestamp : joinedTimestamp
  return max(lastSeen, gradeReceivedTimestamp) + inactiveDays * TIME_DAY_IN_SECONDS
})

function updateFounderKickable() {
  let kickTime = founderKickTime.get()
  if (kickTime == null || !isServerTimeValid.get()) {
    isFounderKickable.set(false)
    clearExtTimer(updateFounderKickable)
    return
  }
  let timeLeft = kickTime - getServerTime()
  isFounderKickable.set(timeLeft <= 0)
  if (timeLeft > 0)
    resetExtTimeout(timeLeft, updateFounderKickable)
  else
    clearExtTimer(updateFounderKickable)
}
updateFounderKickable()
founderKickTime.subscribe(@(_) updateFounderKickable())
isServerTimeValid.subscribe(@(_) updateFounderKickable())

let memberGrade = @[pure, nodiscard](clan, userid) (clan?.users ?? []).findvalue(@(u) u.userId == userid.tointeger())?.gradeStr

function [pure, nodiscard] canKickMember(gradesCfg, myGrade, clan, targetUserId, canKickFounder) {
  let targetGrade = memberGrade(clan, targetUserId)
  return (canKickFounder || targetGrade != GRADE_FOUNDER)
    && hasClanPermission(CLAN_KICK_MEMBER, gradesCfg, myGrade, targetGrade)
}
let canChangeMemberGrade = @[pure, nodiscard](gradesCfg, myGrade, clan, targetUserId) hasClanPermission(CLAN_CHANGE_GRADE,
  gradesCfg, myGrade, memberGrade(clan, targetUserId))

function [pure, nodiscard] assignableGrades(gradesCfg, myGrade, clan, targetUserId) {
  if (!canChangeMemberGrade(gradesCfg, myGrade, clan, targetUserId))
    return []
  let myOrder = gradesCfg?[myGrade].order ?? -1
  let res = []
  foreach (name, cfg in gradesCfg) {
    let order = cfg?.order ?? -1
    if ((order >= 0 && order < myOrder && !cfg?.unique)
        || (myGrade == GRADE_LEADER && name == GRADE_LEADER))
      res.append({ name = name, order = order })
  }
  res.sort(@(a, b) b.order <=> a.order)
  return res.map(@(g) g.name)
}

function canManageMember(gradesCfg, myGrade, clan, targetUserId) {
  if (clan?.clanId == null || clan.clanId != currentClanId.get() || targetUserId == myUserId.get()
      || memberGrade(clan, targetUserId) == null)
    return false

  return canKickMember(gradesCfg, myGrade, clan, targetUserId, isFounderKickable.get())
    || canChangeMemberGrade(gradesCfg, myGrade, clan, targetUserId)
}

function deleteOldestClanCacheEntry(v, protectedId = null) {
  local oldestId = null
  local oldestTime = 0

  foreach (id, entry in v) {
    if (protectedId != null && id == protectedId)
      continue

    let expireTime = entry.expireTime
    if (oldestId == null || expireTime < oldestTime) {
      oldestId = id
      oldestTime = expireTime
    }
  }

  if (oldestId == null)
    return false

  v.$rawdelete(oldestId)
  return true
}

function putClanInfoToCache(clanId, data) {
  if (clanId == null || data == null || !isServerTimeValid.get())
    return false

  updateClanPublicInfo(data)
  let now = getServerTime()

  clanInfoCache.mutate(function(v) {
    v[clanId] <- { data, expireTime = now + CLAN_CACHE_TTL }

    if (v.len() > MAX_CLAN_CACHE_SIZE)
      deleteOldestClanCacheEntry(v, clanId)
  })

  return true
}

let viewedClan = Computed(@() clanInfoCache.get()?[curViewedClanId.get()].data)

let clanCreateEconomy = Computed(@() clanServerConfigs.get()?.economy.clanCreate)

let openClanSearch = @() isClanSearchOpen.set(true)
let closeClanSearch = @() isClanSearchOpen.set(false)

let openClanCreate = @() isClanCreateOpen.set(true)
let closeClanCreate = @() isClanCreateOpen.set(false)

let openClanEditor = @() isClanEditorOpen.set(true)
let closeClanEditor = @() isClanEditorOpen.set(false)

let openClanFilters = @() isClanFiltersOpen.set(true)

function openClanInfo(clan) {
  let clanId = clan?._id
  if (clanId == null || !allow_clans.get())
    return

  curViewedClanId.set(clanId)
  isClanInfoOpen.set(true)

  let entry = clanInfoCache.get()?[clanId]
  let needFetch = entry == null || !isServerTimeValid.get() || entry.expireTime <= getServerTime()
  if (needFetch && clanId not in clanInfoInProgress.get())
    get_clan_info(clanId, { id = "on_viewed_clan_info", clanId })
}

function closeClanInfo() {
  isClanInfoOpen.set(false)
  curViewedClanId.set(null)
}

registerHandler("on_viewed_clan_info", function(res, context) {
  let { clanId } = context
  if (res?.error != null) {
    if (curViewedClanId.get() != clanId)
      return

    handleClanError(res)
    if (viewedClan.get() == null)
      closeClanInfo()
    return
  }

  putClanInfoToCache(clanId, res.__merge({ clanId }))
})

function getClanNameError(text, minChars) {
  if (utf8(text).charCount() < minChars)
    return loc("clans/validation/name/tooShort")
  if (text.startswith("#"))
    return loc("clans/validation/name/startsWithHash")
  if (!isNamePassing(text))
    return loc("clans/validation/name/invalid")
  return null
}

function isHexStringValid(str) {
  if (str.len() > 16)
    return false
  let strUpper = str.toupper()
  for (local i = 0; i < strUpper.len(); i++) {
    let char = strUpper[i]
    if (!(char >= '0' && char <= '9') && !(char >= 'A' && char <= 'F'))
      return false
  }
  return true
}

let getClanDisplayName = memoize(@(name) isNamePassing(name) ? name : $"Clan_{crc32(name)}")
let getClanHexId = memoize(@(id) format("#%X", id))
let getClanIdFromHex = memoize(hexStringToInt)

function lookupClans() {
  if (!allow_clans.get())
    return
  let name = searchClanNameCleared.get()
  if (name.len() > 1 && name.startswith("#")) {
    let hexClanId = name.slice(1)
    if (isHexStringValid(hexClanId)
        && !(getClanIdFromHex(hexClanId) in clanInfoInProgress.get())) {
      let clanId = getClanIdFromHex(hexClanId)
      get_clan_info(clanId, { id = "open_clan_from_search", clanId })
    }
    return
  }
  let filters = getClanLookupFilters()
  let filterStr = object_to_json_string(filters)
  if (filterStr in clansLookupInProgress.get())
    return

  foundedClans.set([])
  clan_lookup(
    filters,
    -1,
    maxResult,
    { id = CLAN_SEARCH_ID, filterStr}
  )
}

let clanNotExistErrors = ["UNKNOWN_USERID", "DECLINE_TO_CREATE_NEW_PROFILE"].totable()

registerHandler("open_clan_from_search", function(res, context) {
  let { clanId } = context
  let currentSearch = searchClanNameCleared.get()
  if (!currentSearch.startswith("#") || getClanIdFromHex(currentSearch.slice(1)) != clanId)
    return
  if (res?.error.message in clanNotExistErrors) {
    foundedClans.set([])
    return
  }
  if (handleClanError(res))
    return
  searchClanName.set("")
  putClanInfoToCache(clanId, { ...res, clanId })
  openClanInfo({ _id = clanId })
})

registerHandler(CLAN_SEARCH_ID, function(res, ctx) {
  if (handleClanError(res))
    return
  if (ctx.filterStr == object_to_json_string(getClanLookupFilters()))
    foundedClans.set(res?.results ?? [])
})

function createClan(privacyType, data, onSuccess) {
  if (!allow_clans.get() || clansInProgress.get())
    return
  clan_create(projectId, { privacyType, textFields = data.map(@(v) $"{v}") }, { id = CLAN_CREATE_ID, onSuccess })
}

registerHandler(CLAN_CREATE_ID, function(res, ctx) {
  forceRefreshCurrentClan()
  if (handleClanError(res))
    return

  closeClanCreate()
  closeClanSearch()
  if (ctx?.onSuccess != null)
    callHandler(ctx.onSuccess, ctx)
})

function updateClan(clanId, data, privacyType) {
  if (!allow_clans.get() || clansInProgress.get())
    return
  clan_update(clanId, { fields = data.map(@(v) v.tostring()) },
    privacyType == null ? null : { privacyType }, { id = CLAN_UPDATE_ID })
}

registerHandler(CLAN_UPDATE_ID, function(res) {
  if (handleClanError(res))
    return

  closeClanEditor()
  forceRefreshCurrentClan()
})

function sendJoinRequest(clanId, message = "", onSuccess = null) {
  if (!allow_clans.get() || clansInProgress.get() || currentClanId.get() != NO_CLAN_ID)
    return

  send_join_request(clanId, projectId, message, { id = CLAN_SEND_JOIN_REQUEST, clanId, onSuccess })
}

registerHandler(CLAN_SEND_JOIN_REQUEST, function(res, ctx) {
  forceRefreshCurrentClan()
  if (handleClanError(res))
    return
  if (ctx?.onSuccess != null)
    callHandler(ctx.onSuccess, ctx)
  shouldUpdateUserRequests.set(true)
})

function leaveClan(clanId) {
  if (!allow_clans.get() || clansInProgress.get())
    return

  clan_leave(clanId, { id = "clan_leave" })
}

registerHandler("clan_leave", function(res) {
  if (handleClanError(res))
    return

  resetCurrentClanInfo()
  forceRefreshCurrentClan()
})

function removeClan(clanId) {
  if (!allow_clans.get() || clansInProgress.get())
    return

  clan_remove(clanId, { id = "clan_remove" })
}

registerHandler("clan_remove", function(res) {
  if (handleClanError(res))
    return
  closeClanEditor()
  resetCurrentClanInfo()
  forceRefreshCurrentClan()
})

function changeMemberGrade(targetUserId, gradeName) {
  if (targetUserId in clanChangeMemberInProgress.get())
    return
  if (gradeName != GRADE_LEADER)
    clan_change_grade(currentClanId.get(), targetUserId, gradeName, { id = "on_clan_change_grade" })
  else
    clan_transfer_ownership(currentClanId.get(), targetUserId, { id = "on_clan_change_grade" })
}

registerHandler("on_clan_change_grade", handleClanError)

function kickMember(userId) {
  if (userId in clanChangeMemberInProgress.get())
    return
  let clanId = currentClanId.get()
  clan_kick_user(clanId, userId, { id = "on_clan_kick_member", userId, clanId })
}

registerHandler("on_clan_kick_member", function(res, context) {
  if (handleClanError(res)) {
    forceRefreshCurrentClan()
    return
  }
  let { clanId, userId } = context
  if (clanId == currentClanId.get())
    foreach (action in onKickActions)
      action(userId)
})

function registerOnClanKickCb(cb) {
  if (onKickActions.indexof(cb) != null)
    logerr("Duplicate register clan kick action")
  else
    onKickActions.append(cb)
}

function closeClanFilters() {
  isClanFiltersOpen.set(false)
  lookupClans()
}

function resetFilters() {
  searchClanName.set("")
  foundedClans.set([])
  resetFilter()
}

isClanSearchOpen.subscribe(function(v) {
  resetFilters()
  if (v)
    lookupClans()
})
currentClanId.subscribe(function(id) {
  if (id != NO_CLAN_ID) {
    closeClanCreate()
    closeClanSearch()
    closeClanFilters()
  }
})


subscribeResetProfile(@() setClanBtnClicked(false))
register_command(@() setClanBtnClicked(false), "debug.reset_clan_btn_clicked")
register_command(@() console_print($"isClanBtnClicked = { isClanBtnClicked.get() }"), "debug.show_is_clan_btn_clicked") 


return {
  clanMinCampaignLevel
  hasRequiredLvl
  foundedClans
  isClanSearchOpen
  isClanBtnClicked
  setClanBtnClicked
  isClanFiltersOpen
  isClanEditorOpen
  openClanEditor
  closeClanEditor
  searchClanName
  searchClanNameCleared

  lookupClans

  openClanSearch
  closeClanSearch
  openClanFilters
  closeClanFilters

  clanCreateEconomy
  isClanCreateOpen
  openClanCreate
  closeClanCreate
  createClan
  updateClan
  handleClanError
  sendJoinRequest
  leaveClan
  removeClan
  getClanNameError
  getClanDisplayName
  getClanHexId

  viewedClan
  isClanInfoOpen
  openClanInfo
  closeClanInfo

  memberGrade
  assignableGrades
  isFounderKickable
  canKickMember
  canChangeMemberGrade
  canManageMember
  changeMemberGrade
  kickMember
  curViewedClanId

  registerOnClanKickCb
}
