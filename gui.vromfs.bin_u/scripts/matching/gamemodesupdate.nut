
from "%scripts/dagui_library.nut" import *
let logGM = log_with_prefix("[GAME_MODES] ")
let { rnd_int } = require("dagor.random")
let { isMatchingConnected } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { gameModesRaw } = require("%appGlobals/gameModes/gameModes.nut")
let { startLogout } = require("%scripts/login/logout.nut")
let showMatchingError = require("showMatchingError.nut")
let { setTimeout } = require("dagor.workcycle")

const MAX_FETCH_RETRIES = 5
const MAX_FETCH_DELAY_SEC = 60

let changedModes = persist("changedModes", @() [])
local isFetching = false
local failedFetches = 0

//this logic will not suvive scripts reload while request in progress,
//just used from WT with rewrite to simple module
let function loadGameModesFromList(gm_list) {
  ::matching.rpc_call("match.fetch_game_modes_info",
    { byId = gm_list, timeout = 60 },
    function(result) {
      let { modes = [] } = result
      if (showMatchingError(result) || modes.len() == 0)
        return
      modes.each(@(m) logGM($"fetched mode {m.name} = {m.gameModeId}"))
      gameModesRaw.mutate(@(list) modes.each(@(m) list[m.gameModeId] <- m))
    })
}

let function fetchGameModes() {
  if (isFetching)
    return

  isFetching = true
  logGM($"fetchGameModes (try {failedFetches})")
  let again = callee()
  ::matching.rpc_call("wtmm_static.fetch_game_modes_digest",
    { timeout = 60 },
    function (result) {
      isFetching = false

      if (result.error == OPERATION_COMPLETE) {
        failedFetches = 0
        loadGameModesFromList(result?.modes ?? [])
        return
      }

      if (++failedFetches <= MAX_FETCH_RETRIES)
        setTimeout(0.1, again)
      else {
        showMatchingError(result)
        startLogout()
      }
    })
}

let function updateChangedModesImpl(added_list, removed_list, changed_list) {
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
        if (gameModeId in modes)
          delete modes[gameModeId]
      }

      foreach (m in changed_list) {
        let { name = "", gameModeId = null, disabled = false, visible = true, active = true } = m
        if (gameModeId == null)
          continue

        logGM($"matching game mode {disabled ? "disabled" : "enabled"} '{name}' [{gameModeId}]")

        if (disabled && !visible && !active) {
          if (gameModeId in modes)
            delete modes[gameModeId]
          continue
        }

        needToFetchGmList.append(gameModeId) //need refresh full mode-info because may updated mode params

        //instant hide when need
        if ((disabled || !visible) && (gameModeId in modes))
          modes[gameModeId] = modes[gameModeId].__merge({ disabled, visible })
      }
    })

  if (needToFetchGmList.len() > 0)
    loadGameModesFromList(needToFetchGmList)
}

let function updateChangedModes() {
  if (changedModes.len() == 0)
    return
  if (!::is_online_available()) {
    changedModes.clear()
    return
  }

  if (isInBattle.value) { // do not handle while session is active
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
  isFetching = false
  failedFetches = 0
  if (v)
    fetchGameModes()
  else
    gameModesRaw({})
})

isInBattle.subscribe(@(v) v ? null : updateChangedModes())

::matching.subscribe("match.notify_game_modes_changed", function(modes) {
  changedModes.append(modes)
  if (changedModes.len() > 1) {
    logGM("Receive changed event while previous not applied")
    return
  }
  let delay = rnd_int(0, MAX_FETCH_DELAY_SEC)
  logGM($"setTimeout to fetch modes in {delay}")
  setTimeout(delay, updateChangedModes)
})
