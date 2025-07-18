from "%scripts/dagui_natives.nut" import is_online_available
from "%scripts/dagui_library.nut" import *
let logGM = log_with_prefix("[GAME_MODES] ")
let { rnd_int } = require("dagor.random")
let { OPERATION_COMPLETE } = require("matching.errors")
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { isMatchingConnected } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { gameModesRaw } = require("%appGlobals/gameModes/gameModes.nut")
let { startLogout } = require("%scripts/login/loginStart.nut")
let showMatchingError = require("showMatchingError.nut")
let matching = require("%appGlobals/matching_api.nut")


const MAX_FETCH_RETRIES = 5
const MAX_FETCH_DELAY_SEC = 60

local isFetchingDigest = false
local failedFetchesDigest = 0
local isFetchingInfo = false
local failedFetchesInfo = 0
local fetchingGmIds = []

let changedModes = persist("changedModes", @() [])




function fetchGameModesInfo() {
  if (isFetchingInfo || fetchingGmIds.len() == 0)
    return

  isFetchingInfo = true
  logGM($"fetchGameModesInfo (try {failedFetchesInfo})")
  let again = callee()
  matching.rpc_call("match.fetch_game_modes_info",
    { byId = fetchingGmIds, timeout = 60 },
    function(result) {
      isFetchingInfo = false

      if (result.error == OPERATION_COMPLETE) {
        failedFetchesInfo = 0
        fetchingGmIds = []
        let { modes = [] } = result
        if (modes.len() == 0) {
          logGM("fetched 0 modes info")
          return
        }
        modes.each(@(m) logGM($"fetched mode {m.name} = {m.gameModeId}"))
        gameModesRaw.mutate(@(list) modes.each(@(m) list[m.gameModeId] <- m))
        return
      }

      if (++failedFetchesInfo <= MAX_FETCH_RETRIES)
        resetTimeout(0.1, again)
      else {
        showMatchingError(result)
        deferOnce(startLogout)
      }
    })
}

function loadGameModesFromList(gm_list) {
  fetchingGmIds = gm_list
  fetchGameModesInfo()
}

function fetchGameModesDigest() {
  if (isFetchingDigest)
    return

  isFetchingDigest = true
  logGM($"fetchGameModesDigest (try {failedFetchesDigest})")
  let again = callee()
  matching.rpc_call("wtmm_static.fetch_game_modes_digest",
    { timeout = 60 },
    function (result) {
      isFetchingDigest = false

      if (result.error == OPERATION_COMPLETE) {
        failedFetchesDigest = 0
        loadGameModesFromList(result?.modes ?? [])
        return
      }

      if (++failedFetchesDigest <= MAX_FETCH_RETRIES)
        resetTimeout(0.1, again)
      else {
        showMatchingError(result)
        deferOnce(startLogout)
      }
    })
}

function updateChangedModesImpl(added_list, removed_list, changed_list) {
  let needToFetchGmList = []

  foreach (m in added_list) {
    let { name = "", gameModeId = -1 } = m
    logGM($"matching game mode added '{name}' [{gameModeId}]")
    needToFetchGmList.append(gameModeId)
  }

  if (removed_list.len() + changed_list.len() > 0)
    gameModesRaw.mutate(function(modes) {
      foreach (m in removed_list) {
        let { name = "", gameModeId = -1 } = m
        logGM($"matching game mode removed '{name}' [{gameModeId}]")
        modes?.$rawdelete(gameModeId)
      }

      foreach (m in changed_list) {
        let { name = "", gameModeId = null, disabled = false, visible = true, active = true } = m
        if (gameModeId == null)
          continue

        logGM($"matching game mode {disabled ? "disabled" : "enabled"} '{name}' [{gameModeId}]")

        if (disabled && !visible && !active) {
          modes?.$rawdelete(gameModeId)
          continue
        }

        needToFetchGmList.append(gameModeId) 

        
        if ((disabled || !visible) && (gameModeId in modes))
          modes[gameModeId] = modes[gameModeId].__merge({ disabled, visible })
      }
    })

  if (needToFetchGmList.len() > 0)
    loadGameModesFromList(needToFetchGmList)
}

function updateChangedModes() {
  if (changedModes.len() == 0)
    return
  if (!is_online_available()) {
    changedModes.clear()
    return
  }

  if (isInBattle.value) { 
    logGM("wait battle finish to update game modes")
    return
  }

  log("apply modes changes")
  let list = clone changedModes
  changedModes.clear()
  list.each(@(c) updateChangedModesImpl(c?.added ?? [], c?.removed ?? [], c?.changed ?? []))
}
updateChangedModes()

isMatchingConnected.subscribe(function(v) {
  isFetchingDigest = false
  failedFetchesDigest = 0
  isFetchingInfo = false
  failedFetchesInfo = 0
  fetchingGmIds = []
  if (v)
    fetchGameModesDigest()
  else
    gameModesRaw({})
})

isInBattle.subscribe(@(v) v ? null : updateChangedModes())

matching.subscribe("match.notify_game_modes_changed", function(modes) {
  changedModes.append(modes)
  if (changedModes.len() > 1) {
    logGM("Receive changed event while previous not applied")
    return
  }
  let delay = rnd_int(0, MAX_FETCH_DELAY_SEC)
  logGM($"resetTimeout to fetch modes in {delay}")
  resetTimeout(delay, updateChangedModes)
})
