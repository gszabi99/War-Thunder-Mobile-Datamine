from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
import "%rGui/seasonScene/seasonSceneContentCfg.nut" as sceneContentCfg
from "%rGui/unlocks/userstat.nut" import addUnlocksUpdater, removeUnlocksUpdater


function mkSeasonSceneUnseenMark(eventId, ovr = {}) {
  let eventIdW = Watched(eventId)
  let watch = sceneContentCfg
    .map(@(t) t?.mkHasUnseen(eventIdW))
    .values()
    .filter(@(w) w != null)
  let key = $"eventStatus_{eventId}"
  return @() {
    watch
    key
    onAttach = @() addUnlocksUpdater(key) 
    onDetach = @() removeUnlocksUpdater(key)
    children = watch.findvalue(@(w) w.get()) ? priorityUnseenMark : null
  }.__update(ovr)
}

return mkSeasonSceneUnseenMark