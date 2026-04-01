from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import clearTimer, setInterval, deferOnce
from "mission" import get_local_mplayer


let localMPlayer = Watched(null)
local isRefreshOn = false
let updaters = {}

let updateLocalMPlayer = @() localMPlayer.set(get_local_mplayer())

function updateRefreshTimer() {
  let needRefresh = null != updaters.findindex(@(w) w == null || w.get())
  if (needRefresh == isRefreshOn)
    return
  isRefreshOn = needRefresh
  if (!isRefreshOn) {
    clearTimer(updateLocalMPlayer)
    return
  }
  setInterval(1, updateLocalMPlayer)
  updateLocalMPlayer()
}

let deferedRefreshTimer = @(_) deferOnce(updateRefreshTimer)

function addMPlayerUpdater(key, watch = null) {
  if (key in updaters) {
    if (watch != updaters[key])
      logerr($"Duplicate register MPlayer updater: {key}")
    return
  }
  updaters[key] <- watch
  watch?.subscribe(deferedRefreshTimer)
  updateRefreshTimer()
}

function removeMPlayerUpdater(key) {
  if (key not in updaters)
    return
  let watch = updaters.$rawdelete(key)
  watch?.unsubscribe(deferedRefreshTimer)
  updateRefreshTimer()
}

return {
  localMPlayer
  addMPlayerUpdater
  removeMPlayerUpdater
  mySpawnScore = Computed(@() localMPlayer.get()?.spawnScore ?? 0)
}