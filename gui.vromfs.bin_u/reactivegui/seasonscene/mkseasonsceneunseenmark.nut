from "%globalsDarg/darg_library.nut" import *
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let sceneContentCfg = require("%rGui/seasonScene/seasonSceneContentCfg.nut")
let { addUnlocksUpdater, removeUnlocksUpdater } = require("%rGui/unlocks/userstat.nut")


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