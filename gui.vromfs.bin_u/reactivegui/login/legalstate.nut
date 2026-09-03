from "%globalsDarg/darg_library.nut" import *
import "DataBlock" as DataBlock
from "blkGetters" import get_local_custom_settings_blk
from "console" import register_command
from "dagor.http" import httpRequest, HTTP_SUCCESS
from "dagor.workcycle" import resetTimeout
from "eventbus" import eventbus_subscribe, eventbus_send
from "json" import parse_json
from "auth_wt" import getPlayerTokenGlobal
from "%sqstd/datablock.nut" import isDataBlock, eachBlock
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/curCircuitOverride.nut" import getCurCircuitOverride
from "%rGui/language.nut" import legalApiLngId
from "%rGui/legal.nut" import legalToApprove
from "%appGlobals/loginState.nut" import legalListForApprove, isAuthorized, isOnlineSettingsAvailable
from "%appGlobals/pServer/bqClient.nut" import sendErrorBqEvent
let saveProfile = @() eventbus_send("saveProfile", {})
let logL = log_with_prefix("[LEGAL] ")



const PROJECT = "wtm"
const VERSIONS_SAVE_ID = "legalVersions"
const RESP_GET_REQUIRED_VERSIONS = "legal.respGetReqVers"
const RESP_GET_ACCEPTED_VERSIONS = "legal.respGetAccVers"
const RESP_ACCEPT_ACTION = "legal.respAcceptVer"
const UNKNOWN_REQ_VER = "unknown"
const ACCEPT_CALLBACKS_WAIT_TIME_SEC = 3.0

let GET_REQ_VERSIONS_URL = getCurCircuitOverride("legalApiV2GetReqVersURL", "https://legal.gaijin.net/api/v2/documents?lang={lang}") 
let GET_ACCEPTED_VER_URL = getCurCircuitOverride("legalApiV2GetAccVerURL", "https://legal.gaijin.net/api/v2/accept/{id}?project={project}") 
let GET_DOC_LANGS_URL = getCurCircuitOverride("legalApiV2GetLangsURL", "https://legal.gaijin.net/api/v2/document/{id}") 
let ACCEPT_ACTION_URL = getCurCircuitOverride("legalApiV2AcceptURL", "https://legal.gaijin.net/api/v2/accept")

let isAcceptedVerActual = @(acceptedVers, requiredVer) acceptedVers.contains(requiredVer)
  || (requiredVer == UNKNOWN_REQ_VER && acceptedVers.len() != 0)

let requiredVersionsByLangOnline = hardPersistWatched("requiredVersionsByLangOnline", {})
let requiredVersions = Computed(@() requiredVersionsByLangOnline.get()?[legalApiLngId] != null
  ? legalToApprove.map(@(_, id) requiredVersionsByLangOnline.get()?[legalApiLngId][id] ?? UNKNOWN_REQ_VER)
  : null)
let acceptedVersionListsOnline = hardPersistWatched("acceptedVersionListsOnline", {})
let acceptedVersionListsTemporary = hardPersistWatched("acceptedVersionListsTemporary", {})
let acceptedVersionListsBackup = Watched(null)
let acceptedVersionLists = Computed(@()
  acceptedVersionListsOnline.get().len() != legalToApprove.len() || acceptedVersionListsBackup.get() == null
    ? null
    : acceptedVersionListsOnline.get().map(function(v, id) {
        let res = clone (v.len() != 0 ? v : (acceptedVersionListsBackup.get()?[id] ?? []))
        return res.extend(acceptedVersionListsTemporary.get()?[id] ?? [])
      }))
let needApprove = Computed(@() requiredVersions.get() == null || acceptedVersionLists.get() == null 
  ? {}
  : legalToApprove.map(@(_, id) !isAcceptedVerActual(acceptedVersionLists.get()[id], requiredVersions.get()[id])))
let isAcceptLegalsInProgress = Watched(false)
let needSyncBackup = Computed(@() isOnlineSettingsAvailable.get()
  && acceptedVersionListsBackup.get() != null
  && acceptedVersionListsOnline.get().len() == legalToApprove.len()
  && acceptedVersionListsOnline.get().findvalue(@(vers) vers.len() == 0) == null
  && !isEqual(acceptedVersionListsBackup.get(), acceptedVersionListsOnline.get()))
let isLoginAllowed = Computed(@() legalToApprove.findvalue(@(_, id) (acceptedVersionLists.get()?[id].len() ?? 0) == 0) == null)

if (!isEqual(needApprove.get(), legalListForApprove.get()))
  legalListForApprove.set(needApprove.get())
needApprove.subscribe(@(v) legalListForApprove.set(v))



function loadAcceptedVersionsBackup() {
  let blk = get_local_custom_settings_blk()
  let versionsBlk = blk?[VERSIONS_SAVE_ID]
  let res = {}
  if (isDataBlock(versionsBlk))
    eachBlock(versionsBlk, @(v, k) res[k] <- v % "o")
  acceptedVersionListsBackup.set(res)
}

function saveAcceptedVersionsBackup() {
  if (acceptedVersionListsBackup.get() == null)
    return
  let blk = get_local_custom_settings_blk()
  let versionsBlk = DataBlock()
  foreach (k, arr in acceptedVersionListsBackup.get()) {
    let arrBlk = DataBlock()
    foreach (ver in arr)
      arrBlk["o"] <- ver
    versionsBlk[k] <- arrBlk
  }
  blk[VERSIONS_SAVE_ID] = versionsBlk
  saveProfile()
}

function resetAcceptedVersionsBackup() {
  acceptedVersionListsBackup.set(null)
  acceptedVersionListsTemporary.set({})
}
if (isOnlineSettingsAvailable.get())
  loadAcceptedVersionsBackup()
isOnlineSettingsAvailable.subscribe(@(v) v ? loadAcceptedVersionsBackup() : resetAcceptedVersionsBackup())

function syncAcceptedVersionsBackup() {
  if (!needSyncBackup.get())
    return
  logL("Sync accepted versions backup")
  acceptedVersionListsBackup.set(acceptedVersionListsOnline.get().map(@(vers) clone vers))
  saveAcceptedVersionsBackup()
}
needSyncBackup.subscribe(@(v) v ? resetTimeout(ACCEPT_CALLBACKS_WAIT_TIME_SEC, syncAcceptedVersionsBackup) : null)



let mkAuthRequestHeaders = @() { Authorization = $"Bearer {getPlayerTokenGlobal()}" }

let mkJsonHttpRequestCb = @(onSuccess, onFailure) function(response) {
  let { status = -1, http_code = -1, body = null, context = null } = response
  let bodyStr = body?.as_string() ?? ""
  if (status != HTTP_SUCCESS || bodyStr == "") {
    let errId = $"Network connection error {status}"
    logL(errId, response.__merge(bodyStr == "" ? {} : { body = bodyStr }))
    onFailure({ context, errId, needSendBQ = false })
    return
  }
  if (http_code < 200 || 300 <= http_code) {
    let errId = $"Response is HTTP error {http_code}"
    logL(errId, response.__merge({ body = bodyStr }))
    onFailure({ context, errId, needSendBQ = true })
    return
  }
  if (bodyStr.startswith("<")) {
    let errId = "Response is HTML instead of JSON"
    logL(errId, response.__merge({ body = bodyStr }))
    onFailure({ context, errId, needSendBQ = true })
    return
  }
  local answer = null
  try {
    answer = parse_json(bodyStr)
  }
  catch(e) {
    let errId = $"Response JSON parsing failed: {e}"
    logL(errId, response.__merge({ body = bodyStr }))
    onFailure({ context, errId, needSendBQ = true })
    return
  }
  if (answer?.status != "OK") {
    let errId = $"Response JSON status bad: {answer?.status}"
    logL(errId, answer)
    onFailure({ context, errId, needSendBQ = true })
    return
  }
  onSuccess({ context, answer })
}



eventbus_subscribe(RESP_GET_REQUIRED_VERSIONS, mkJsonHttpRequestCb(
  function(data) {
    let { answer, context } = data
    let lang = context
    let reqVers = answer?.result.filter(@(_, k) k in legalToApprove) ?? {}
    if (requiredVersionsByLangOnline.get()?[lang] == null || reqVers.len() != 0)
      requiredVersionsByLangOnline.mutate(@(v) v[lang] <- reqVers)
  },
  function(errInfo) {
    let { errId, needSendBQ, context } = errInfo
    let lang = context
    if (needSendBQ)
      sendErrorBqEvent($"Legal: GetReqVers {lang} {errId}")
    if (requiredVersionsByLangOnline.get()?[lang] == null)
      requiredVersionsByLangOnline.mutate(@(v) v[lang] <- {})
  }))
function requestRequiredVersionsOncePerLang() {
  if ((requiredVersionsByLangOnline.get()?[legalApiLngId].len() ?? 0) != 0)
    return
  httpRequest({
    method = "GET"
    url = GET_REQ_VERSIONS_URL.subst({ lang = legalApiLngId })
    respEventId = RESP_GET_REQUIRED_VERSIONS
    context = legalApiLngId
  })
}
if (isAuthorized.get())
  requestRequiredVersionsOncePerLang()
isAuthorized.subscribe(@(v) v ? requestRequiredVersionsOncePerLang() : null)



eventbus_subscribe(RESP_GET_ACCEPTED_VERSIONS, mkJsonHttpRequestCb(
  function(data) {
    let { answer, context } = data
    let id = context
    let accVers = answer?.result[PROJECT][id] ?? []
    acceptedVersionListsOnline.mutate(@(v) v[id] <- accVers)
  },
  function(errInfo) {
    let { errId, needSendBQ, context } = errInfo
    let id = context
    if (needSendBQ)
      sendErrorBqEvent($"Legal: GetAccVers {id} {errId}")
    acceptedVersionListsOnline.mutate(@(v) v[id] <- [])
  }))
function requestAcceptedVersions() {
  if (!isAuthorized.get())
    return
  foreach (id, _ in legalToApprove)
    httpRequest({
      method = "GET"
      url = GET_ACCEPTED_VER_URL.subst({ id, project = PROJECT })
      headers = mkAuthRequestHeaders()
      respEventId = RESP_GET_ACCEPTED_VERSIONS
      context = id
    })
}

function reinitAcceptedVersions() {
  acceptedVersionListsOnline.set({})
  if (isAuthorized.get())
    requestAcceptedVersions()
}
reinitAcceptedVersions()
isAuthorized.subscribe(@(_) reinitAcceptedVersions())



function acceptTemporarily(id, version) {
  logL($"Temporarily accepting for current session: {id} {version}")
  acceptedVersionListsTemporary.mutate(@(v) v[id] <- [ version ])
}

eventbus_subscribe(RESP_ACCEPT_ACTION, mkJsonHttpRequestCb(
  function(data) {
    let { token, version } = data.answer.result
    let id = token
    logL($"Accepted online successfully: {id} {version}")
    acceptedVersionListsOnline.mutate(function(v) {
      if (id not in v)
        return
      if (!v[id].contains(version))
        v[id].append(version)
    })
  },
  function(errInfo) {
    let { errId, needSendBQ, context } = errInfo
    let { id, version } = context
    if (needSendBQ)
      sendErrorBqEvent($"Legal: AcceptVer {id} {version} {errId}")
    acceptTemporarily(id, version)
  }))

function acceptLegalOnline(id, version) {
  if (!isAuthorized.get())
    return
  logL($"User requested to accept legal online: {id} {version}")
  httpRequest({
    method = "POST"
    url = ACCEPT_ACTION_URL
    headers = mkAuthRequestHeaders()
    json = {
      code = id
      project = PROJECT
      version
    }
    respEventId = RESP_ACCEPT_ACTION
    context = { id, version }
  })
}

function acceptAllLegals() {
  if (!isAuthorized.get() || !isOnlineSettingsAvailable.get() || acceptedVersionLists.get() == null)
    return
  isAcceptLegalsInProgress.set(true)
  foreach (id, need in needApprove.get()) {
    if (!need)
      continue
    let version = requiredVersions.get()?[id] ?? UNKNOWN_REQ_VER
    if (version != UNKNOWN_REQ_VER)
      acceptLegalOnline(id, version)
    else
      acceptTemporarily(id, version)
  }
}

needApprove.subscribe(@(v) (v.findvalue(@(n) n) != null) ? null : isAcceptLegalsInProgress.set(false))



let debugRequestCb = mkJsonHttpRequestCb(
  @(data) console_print($"Response ({data.context})", data.answer), 
  @(errInfo) console_print($"ERROR: ({errInfo.context}) - {errInfo.errId}")) 

register_command(
  function() {
    httpRequest({
      method = "GET"
      url = GET_REQ_VERSIONS_URL.subst({ lang = legalApiLngId })
      callback = debugRequestCb
      context = legalApiLngId
    })
  }
  "debug.legalApiV2.printReqVersionsForCurLang")

register_command(
  function() {
    foreach (id, _ in legalToApprove)
      httpRequest({
        method = "GET"
        url = GET_DOC_LANGS_URL.subst({ id })
        callback = debugRequestCb
        context = id
      })
  }
  "debug.legalApiV2.printReqVersionsForAllLangs")

register_command(
  function() {
    if (!isAuthorized.get())
      return console_print("Not authorized") 
    foreach (id, _ in legalToApprove)
      httpRequest({
        method = "GET"
        url = GET_ACCEPTED_VER_URL.subst({ id, project = PROJECT })
        headers = mkAuthRequestHeaders()
        callback = debugRequestCb
        context = id
      })
  }
  "debug.legalApiV2.printUserAcceptedVersions")

register_command(
  function() {
    if (!isOnlineSettingsAvailable.get())
      return console_print("Error: Online settings not available") 
    let blk = get_local_custom_settings_blk()
    if (VERSIONS_SAVE_ID not in blk)
      return console_print("Already empty") 
    blk.removeBlock(VERSIONS_SAVE_ID)
    saveProfile()
    console_print("Success. Do restart now.") 
  }
  "debug.legalBackupReset")

return {
  isLoginAllowed
  acceptAllLegals
  isAcceptLegalsInProgress
}
