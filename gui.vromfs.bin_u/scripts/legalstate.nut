from "%scripts/dagui_library.nut" import *
import "DataBlock" as DataBlock
from "blkGetters" import get_local_custom_settings_blk
from "console" import register_command
from "dagor.http" import httpRequest, HTTP_SUCCESS
from "dagor.workcycle" import resetTimeout
from "eventbus" import eventbus_subscribe
from "json" import parse_json
from "auth_wt" import getPlayerTokenGlobal
from "%sqstd/datablock.nut" import isDataBlock, eachBlock, eachParam
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/curCircuitOverride.nut" import getCurCircuitOverride
from "%appGlobals/legal.nut" import legalToApprove, legalLang
from "%appGlobals/loginState.nut" import legalListForApprove, isAuthorized, isOnlineSettingsAvailable
from "%appGlobals/pServer/bqClient.nut" import sendErrorBqEvent
from "%scripts/clientState/saveProfile.nut" import saveProfile
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


let knownVersionLists = {
  privacypolicy = [ "650da55c675d431225347c89", "650da56294f02343e1382479",
    "650da567dbe9521a831b164b", "650da56c27c8f17707396787", "650da5701e3ea03aff4fb6c7", "650da57694f02343e138247b",
    "650da57a5e023a69f72a4e53", "650da5813fe942444c2375d7", "650da5866637f65e1b2cda89", "650da58b94f02343e138247d",
    "650da5903fe942444c2375d9", "650da5947093fc6a4728db57", "650da599675d431225347c8b", "650da59e1e3ea03aff4fb6c9" ]
  termsofservice = [ "650da33d77ba8c0e3f2789b5", "650da342c3daf428a11170c9",
    "650da347d298aa75d6583989", "650da34bd298aa75d658398b", "650da35029697d4b9018a94b", "650da35532b7e01eea2ddb3b",
    "650da35a77ba8c0e3f2789b7", "650da35f32b7e01eea2ddb3d", "650da3631e469e60f0150995", "650da367e8d06e7b1865953d",
    "650da36c1e469e60f0150997", "650da37077ba8c0e3f2789b9", "650da3764927ad32004d4e59", "650da37b4927ad32004d4e5b" ]
}


let versionsApiV1ToApiV2Map = {
  privacypolicy = { v1 = 1749482558, v2 = [ UNKNOWN_REQ_VER, "650da55c675d431225347c89", "650da56294f02343e1382479",
    "650da567dbe9521a831b164b", "650da56c27c8f17707396787", "650da5701e3ea03aff4fb6c7", "650da57694f02343e138247b",
    "650da57a5e023a69f72a4e53", "650da5813fe942444c2375d7", "650da5866637f65e1b2cda89", "650da58b94f02343e138247d",
    "650da5903fe942444c2375d9", "650da5947093fc6a4728db57", "650da599675d431225347c8b", "650da59e1e3ea03aff4fb6c9" ] }
  termsofservice = { v1 = 1749200825, v2 = [ UNKNOWN_REQ_VER, "650da33d77ba8c0e3f2789b5", "650da342c3daf428a11170c9",
    "650da347d298aa75d6583989", "650da34bd298aa75d658398b", "650da35029697d4b9018a94b", "650da35532b7e01eea2ddb3b",
    "650da35a77ba8c0e3f2789b7", "650da35f32b7e01eea2ddb3d", "650da3631e469e60f0150995", "650da367e8d06e7b1865953d",
    "650da36c1e469e60f0150997", "650da37077ba8c0e3f2789b9", "650da3764927ad32004d4e59", "650da37b4927ad32004d4e5b" ] }
}

function isAcceptedVerActual(id, acceptedVers, requiredVer, knownVers) {
  
  if (acceptedVers.len() == 1 && type(acceptedVers[0]) == "integer")
    return versionsApiV1ToApiV2Map?[id].v1 == acceptedVers[0] && versionsApiV1ToApiV2Map?[id].v2.contains(requiredVer)
  
  return acceptedVers.contains(requiredVer)
    || (requiredVer == UNKNOWN_REQ_VER && knownVers.findindex(@(v) acceptedVers.contains(v)) != null)
}

let requiredVersionsByLangOnline = hardPersistWatched("requiredVersionsByLangOnline", {})
let requiredVersions = Computed(@() requiredVersionsByLangOnline.get()?[legalLang] != null
  ? legalToApprove.map(@(_, id) requiredVersionsByLangOnline.get()?[legalLang][id] ?? UNKNOWN_REQ_VER)
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
  : legalToApprove.map(@(_, id) (id not in acceptedVersionLists.get())
      || !isAcceptedVerActual(id, acceptedVersionLists.get()[id], requiredVersions.get()[id], knownVersionLists?[id] ?? [])))
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
  if (isDataBlock(versionsBlk)) {
    eachParam(versionsBlk, @(v, k) res[k] <- [ v ]) 
    eachBlock(versionsBlk, @(v, k) res[k] <- v % "o")
  }
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
  if ((requiredVersionsByLangOnline.get()?[legalLang].len() ?? 0) != 0)
    return
  httpRequest({
    method = "GET"
    url = GET_REQ_VERSIONS_URL.subst({ lang = legalLang })
    respEventId = RESP_GET_REQUIRED_VERSIONS
    context = legalLang
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
      let vers = v[id]
        .filter(@(ver) type(ver) == "string") 
      if (!vers.contains(version))
        vers.append(version)
      v[id] <- vers
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

eventbus_subscribe("acceptAllLegals", function(_) {
  if (!isAuthorized.get() || !isOnlineSettingsAvailable.get() || acceptedVersionLists.get() == null)
    return
  if (isAcceptLegalsInProgress.get())
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
})

needApprove.subscribe(@(v) (v.findvalue(@(n) n) != null) ? null : isAcceptLegalsInProgress.set(false))



let debugRequestCb = mkJsonHttpRequestCb(
  @(data) console_print($"Response ({data.context})", data.answer), 
  @(errInfo) console_print($"ERROR: ({errInfo.context}) - {errInfo.errId}")) 

register_command(
  function() {
    foreach (id, _ in legalToApprove)
      httpRequest({
        method = "GET"
        url = GET_DOC_LANGS_URL.subst({ id })
        callback = mkJsonHttpRequestCb(
          function(data) {
            let newVersions = data.answer?.result.filter(@(_, k) k.len() == 2).values().sort() ?? []
            let prevVersions = knownVersionLists?[id] ?? []
            if (newVersions.len() != 0 && isEqual(newVersions, prevVersions))
              console_print($"Known versions are valid, no changes required: {id}") 
            else
              console_print($"Known versions need to be updated: {id}", newVersions) 
          },
          @(errInfo) console_print($"ERROR getting {id}: {errInfo.errId}")) 
      })
  }
  "debug.legalApiV2.checkKnownVersionListsUpdate")

register_command(
  function() {
    httpRequest({
      method = "GET"
      url = GET_REQ_VERSIONS_URL.subst({ lang = legalLang })
      callback = debugRequestCb
      context = legalLang
    })
  }
  "debug.legalApiV2.printReqVersionsForCurLang")

register_command(
  function() {
    let legacyGetVersionsUrl = getCurCircuitOverride("legalApiURL",
      "https://legal.gaijin.net/api/v1/getversions?filter=default,gamerules,gamerules-wtm,wtm-compliance-policy")
    httpRequest({
      method = "GET"
      url = legacyGetVersionsUrl
      callback = debugRequestCb
      context = "API v1"
    })
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

register_command(
  function() {
    if (!isOnlineSettingsAvailable.get())
      return console_print("Not available local custom settings") 
    let blk = get_local_custom_settings_blk()
    let versionsBlk = DataBlock()
    let val = {
      privacypolicy = 1749482558
      termsofservice = 1749200825
    }
    foreach (k, v in val)
      versionsBlk[k] <- v
    blk[VERSIONS_SAVE_ID] = versionsBlk
    saveProfile()
    console_print("Success. Do restart now.") 
  }
  "debug.legalBackupRestoreV1")

return {
  isLoginAllowed
}
