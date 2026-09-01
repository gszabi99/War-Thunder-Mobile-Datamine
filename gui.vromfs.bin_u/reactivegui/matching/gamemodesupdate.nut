from "%globalsDarg/darg_library.nut" import *
from "dagor.random" import rnd_int
from "dagor.workcycle" import resetTimeout, deferOnce
from "%sqstd/globalState.nut" import hardPersistWatched
from "eventbus" import eventbus_send
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/gameModes/gameModes.nut" import gameModesRaw
from "%appGlobals/loginState.nut" import isMatchingConnected, isLoggedIn
from "%rGui/matching/matchingApi.nut" import matching_subscribe, matchingRpcRegisterHandler
from "online" import is_online_available
import "%rGui/matching/matchingRequestWithRetries.nut" as matchingRequestWithRetries
import "showMatchingError.nut" as showMatchingError


let logGM = log_with_prefix("[GAME_MODES] ")
let requestLogout = @() eventbus_send("logOut", {})

const MAX_FETCH_DELAY_SEC = 60

let changedModes = hardPersistWatched("changedModes", [])

let fetchGameModesInfo = @(gm_list) gm_list.len() == 0 ? null
  : matchingRequestWithRetries({
      cmd = "match.fetch_game_modes_info"
      params = { byId = gm_list, timeout = MAX_FETCH_DELAY_SEC }
      onFinish = "onGameModesFetched"
    })

matchingRpcRegisterHandler("onGameModesFetched", function(result) {
  if ("error" in result) {
    showMatchingError(result)
    deferOnce(requestLogout)
    return
  }
  let { modes = [] } = result
  if (modes.len() == 0) {
    logGM("fetched 0 modes info")
    return
  }
  modes.each(@(m) logGM($"fetched mode {m.name} = {m.gameModeId}"))
  gameModesRaw.mutate(@(list) modes.each(@(m) list[m.gameModeId] <- m))
})

let fetchGameModesDigest = @() matchingRequestWithRetries({
  cmd = "wtmm_static.fetch_game_modes_digest"
  params = { timeout = MAX_FETCH_DELAY_SEC }
  onFinish = "onGameModesDigest"
})

matchingRpcRegisterHandler("onGameModesDigest", function(result) {
  if ("error" in result) {
    showMatchingError(result)
    deferOnce(requestLogout)
    return
  }
  fetchGameModesInfo(result?.modes ?? [])
})

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
    fetchGameModesInfo(needToFetchGmList)
}

function updateChangedModes() {
  if (changedModes.get().len() == 0)
    return
  if (!is_online_available()) {
    changedModes.mutate(@(v) v.clear())
    return
  }

  if (isInBattle.get()) { 
    logGM("wait battle finish to update game modes")
    return
  }

  log("apply modes changes")
  let list = clone changedModes.get()
  changedModes.mutate(@(v) v.clear())
  list.each(@(c) updateChangedModesImpl(c?.added ?? [], c?.removed ?? [], c?.changed ?? []))
}
updateChangedModes()

isMatchingConnected.subscribe(@(v) v ? fetchGameModesDigest() : null)
isLoggedIn.subscribe(@(v) v ? null : gameModesRaw.set({}))
isInBattle.subscribe(@(v) v ? null : updateChangedModes())

matching_subscribe("match.notify_game_modes_changed", function(modes) {
  changedModes.mutate(@(v) v.append(modes))
  if (changedModes.get().len() > 1) {
    logGM("Receive changed event while previous not applied")
    return
  }
  let delay = rnd_int(0, MAX_FETCH_DELAY_SEC)
  logGM($"resetTimeout to fetch modes in {delay}")
  resetTimeout(delay, updateChangedModes)
})
