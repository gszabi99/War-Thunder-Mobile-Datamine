from "%globalsDarg/darg_library.nut" import *
let { subscribe, send } = require("eventbus")
let http = require("dagor.http")
let { get_time_msec } = require("dagor.time")
let { setTimeout, clearTimer } = require("dagor.workcycle")
let json = require("json")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { get_cur_circuit_name } = require("app")
let { platformId } = require("%sqstd/platform.nut")
let { mkVersionFromString, versionToInt } = require("%sqstd/version.nut")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")
let { isLoggedIn, isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { get_blk_value_by_path, set_blk_value_by_path } = require("%sqStdLibs/helpers/datablockUtils.nut")
let { sharedStats } = require("%appGlobals/pServer/campaign.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")


const PATCHNOTE_IDS = "PatchnoteIds"
const PATCHNOTE_RECEIVED = "PatchnoteReceived"
const SEEN_SAVE_ID = "changelog/lastSeenId"
const MSEC_BETWEEN_REQUESTS = 600000
const MAX_VERSIONS_AMOUNT = 5
const MIN_SESSIONS_TO_FORCE_SHOW = 5
const SHOULD_SHOW_PATCHNOTES_AUTOMATICALLY = false

let shortLang = loc("current_lang")
let patchPlatform = platformId == "android" ? "android" : "ios"
let cfgId = get_cur_circuit_name().indexof("production") != null || get_cur_circuit_name().indexof("stable") != null
  ? "wtm_production" : "wtm_test"
let GET_ALL_URL = $"https://newsfeed.gap.gaijin.net/api/patchnotes/{cfgId}/{shortLang}/?platform={patchPlatform}"
let getPatchUrl = @(id)
  $"https://newsfeed.gap.gaijin.net/api/patchnotes/{cfgId}/{shortLang}/{id}/?platform={patchPlatform}"

let receivedPatchnotes = mkHardWatched("changelog.receivedPatchnotes", {})
let versions = mkHardWatched("changelog.versions", [])
let isChangeLogOpened = mkWatched(persist, "isOpened", false)
let isVersionsReceived = Computed(@() versions.value.len() > 0)
let receivedPatchnotesLang = persist("receivedPatchnotesLang", @() { value = null })
let playerSelectedPatchnoteId = Watched(null)
let lastSeenId = Watched(-1)
local requestMadeTime = 0

if (receivedPatchnotesLang.value != shortLang) {
  receivedPatchnotes({})
  versions([])
}

let unseenPatchnoteId = Computed(function() {
  if (lastSeenId.value == -1)
    return null
  //here we want to find first unseen Major version or last unseed hotfix version.
  let lastId = lastSeenId.value
  foreach (version in versions.value)
    if (lastId < version.id && version.versionType == "major")
      return version.id

  local res = null
  foreach (version in versions.value)
    if (version.id > lastId)
      res = version.id
    else
      break
  return res
})

let curPatchnoteId = Computed(function() {
  let id = playerSelectedPatchnoteId.value
  if (id != null && versions.value.findvalue(@(v) v.id == id) != null)
    return id
  return unseenPatchnoteId.value ?? versions.value?[0].id
})
let curPatchnoteContent = Computed(@() receivedPatchnotes.value?[curPatchnoteId.value])
let curPatchnoteIdx = Computed(@() versions.value.findindex(@(v) v.id == curPatchnoteId.value) ?? -1)
let haveUnseenVersions = Computed(@() unseenPatchnoteId.value != null)
let needShowChangeLog = Computed(@() SHOULD_SHOW_PATCHNOTES_AUTOMATICALLY
  && isMainMenuAttached.value // warning disable: -const-in-bool-expr
  && haveUnseenVersions.value
  && (sharedStats.value?.sessionsCountPersist ?? 0) >= MIN_SESSIONS_TO_FORCE_SHOW
  && !hasModalWindows.value
  && curPatchnoteContent.value != null)

isChangeLogOpened.subscribe(@(_) haveUnseenVersions.value ? playerSelectedPatchnoteId(null) : null)

let function loadLastSeenVersion() {
  let sBlk = get_local_custom_settings_blk()
  lastSeenId(get_blk_value_by_path(sBlk, SEEN_SAVE_ID) ?? 0)
}
isOnlineSettingsAvailable.subscribe(@(v) v ? loadLastSeenVersion() : null)
if (isOnlineSettingsAvailable.value)
  loadLastSeenVersion()

let function markVersionSeenById(id) {
  if (id <= lastSeenId.value)
    return
  lastSeenId(id)
  let sBlk = get_local_custom_settings_blk()
  set_blk_value_by_path(sBlk, SEEN_SAVE_ID, id)
  send("saveProfile", {})
}

let markCurPatchVersionSeen = @() markVersionSeenById(curPatchnoteId.value)
let markAllVersionsSeen = @()
  markVersionSeenById(versions.value.reduce(@(res, v) max(res, v.id), -1))

let function clLog(event, params = {}) {
  local txt = $"[CHANGELOG] {event}: "
  foreach (k, v in params)
    if (type(v) == "string")
      txt = $"{txt} {k} = {v}"
  log(txt)
}

let function mkVersion(v) {
  local tVersion = v?.version ?? ""
  let vList = tVersion.split(".").len()
  local versionType = v?.type
  if (vList != 4) {
    clLog("changelog_versions_receive_errors",
      { reason = "Incorrect version", version = tVersion })
    if (vList == 3) {
      tVersion = $"{tVersion}.0"
      if (versionType == null)
        versionType = "major"
    }
    else
      throw null
  }
  let version = mkVersionFromString(tVersion)
  let title = v?.title ?? tVersion
  local shortTitle = v?.titleshort ?? "undefined"
  if (shortTitle == "undefined" || shortTitle.len() > 50)
    shortTitle = null
  let { id, date = "" } = v
  return { version, title, tVersion, versionType, shortTitle, iVersion = versionToInt(version), id, date }
}

let function filterVersions(vers) {
  let res = []
  local foundMajor = false
  foreach (idx, version in vers)
    if (idx >= MAX_VERSIONS_AMOUNT && foundMajor)
      break
    else if (version.versionType == "major") {
      res.append(version)
      foundMajor = true
    }
    else if (idx < MAX_VERSIONS_AMOUNT && !foundMajor)
      res.append(version)
  return res
}

subscribe(PATCHNOTE_IDS, function processPatchnotesList(response) {
  let { status = -1, http_code = -1, context = "" } = response
  if (context != shortLang)
    return //wrong lang changelog list, ignore

  if (status != http.SUCCESS || http_code < 200 || 300 <= http_code) {
    clLog("changelog_versions_receive_errors", {
      reason = "Error in version response"
      stage = "get_versions"
      http_code = response?.http_code
      status = status })
    return
  }

  local result = []
  try {
    result = response?.body ? json.parse(response.body.as_string())?.result ?? [] : []
  }
  catch(e) {}

  if (result == null) {
    clLog("changelog_versions_parse_errors",
      { reason = "Incorrect json in version response", stage = "get_versions" })
    versions([])
    return
  }
  clLog("changelog_success_versions", { reason = "Versions received successfully" })
  versions(filterVersions(result.map(mkVersion)))
  receivedPatchnotesLang.value = shortLang
})

let function requestAllPatchnotes() {
  let currTimeMsec = get_time_msec()
  if (requestMadeTime > 0
      && (currTimeMsec - requestMadeTime < MSEC_BETWEEN_REQUESTS))
    return

  let request = {
    method = "GET"
    url = GET_ALL_URL
    context = shortLang
  }

  request.respEventId <- PATCHNOTE_IDS
  http.request(request)
  requestMadeTime = currTimeMsec
}

isMainMenuAttached.subscribe(@(v) v ? requestAllPatchnotes() : null)

let ERROR_PAGE = {
  title = loc("matching/SERVER_ERROR_BAD_REQUEST")
  content = { v = loc("matching/SERVER_ERROR_INTERNAL") }
}

subscribe(PATCHNOTE_RECEIVED, function onPatchnoteReceived(response) {
  let { status = -1, http_code = -1, context = null } = response
  let { id = "", lang = null } = context
  if (lang != shortLang)
    return //ingnore requests result for wrong lang

  if (status != http.SUCCESS || http_code < 200 || 300 <= http_code || id == null) {
    clLog("changelog_receive_errors", {
      reason = "Error in patchnotes response"
      stage = "get_patchnote"
      http_code
      status
      patchId = id
    })
    return
  }
  let result = json.parse((response?.body ?? "").as_string())?.result
  if (result == null)
    clLog("changelog_parse_errors",
      { reason = $"Incorrect json in patchnotes response (id = {id})", stage = "get_patchnote" })
  else
    clLog("changelog_success_patchnote", { reason = $"Patchnotes received successfully (id = {id})" })
  receivedPatchnotes.mutate(@(v) v[id] <- result ?? ERROR_PAGE)
})

let function requestPatchnote(id) {
  if (id == null || id in receivedPatchnotes.value)
    return

  let request = {
    method = "GET"
    url = getPatchUrl(id)
    context = { id, lang = shortLang }
  }
  request.respEventId <- PATCHNOTE_RECEIVED
  http.request(request)
}

let function changePatchNote(delta = 1) {
  if (versions.value.len() == 0)
    return
  let nextIdx = clamp(curPatchnoteIdx.value - delta, 0, versions.value.len() - 1)
  let patchnote = versions.value[nextIdx]
  markCurPatchVersionSeen()
  playerSelectedPatchnoteId(patchnote.id)
}

let openChangeLog = @() isChangeLogOpened(true)
let openChangeLogIfNeed = @() needShowChangeLog.value ? openChangeLog() : null
needShowChangeLog.subscribe(@(v) v ? setTimeout(0.1, openChangeLogIfNeed) : clearTimer(openChangeLogIfNeed))

let requestCurPatchnote = @() requestPatchnote(curPatchnoteId.value)
isVersionsReceived.subscribe(function(value) {
  if (value && (haveUnseenVersions.value || isChangeLogOpened.value))
    requestCurPatchnote()
})
isChangeLogOpened.subscribe(@(v) v ? requestCurPatchnote() : null)
curPatchnoteId.subscribe(@(v) isChangeLogOpened.value ? requestPatchnote(v) : null)
if (isLoggedIn.value && isVersionsReceived.value && (isChangeLogOpened.value || haveUnseenVersions.value))
  requestPatchnote(curPatchnoteId.value)

register_command(function() {
  lastSeenId(0)
  let sBlk = get_local_custom_settings_blk()
  set_blk_value_by_path(sBlk, SEEN_SAVE_ID, 0)
  send("forceSaveProfile", {})
}, "ui.resetChangeLogSeen")

return {
  isChangeLogOpened
  versions
  playerSelectedPatchnoteId
  curPatchnoteId
  curPatchnoteIdx
  curPatchnoteContent
  isVersionsReceived

  openChangeLog
  closeChangeLog = @() isChangeLogOpened(false)
  markVersionSeenById
  markCurPatchVersionSeen
  markAllVersionsSeen
  nextPatchNote = @() changePatchNote(1)
  prevPatchNote = @() changePatchNote(-1)
}
